import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:spoonshare/constants/app_colors.dart';
import 'package:spoonshare/screens/fooddetails/food_details.dart';

class NearbyDailyFoodCard extends StatelessWidget {
  const NearbyDailyFoodCard({Key? key, this.dailyActive = false})
      : super(key: key);
  final bool dailyActive;

  Future<double> _calculateDistance(
      GeoPoint foodLocation, Position userLocation) async {
    double distanceInMeters = Geolocator.distanceBetween(
      userLocation.latitude,
      userLocation.longitude,
      foodLocation.latitude,
      foodLocation.longitude,
    );
    return distanceInMeters;
  }

  String calculateTimeDifference(Timestamp timestamp) {
    final currentTime = DateTime.now();
    final uploadTime = timestamp.toDate();
    final difference = currentTime.difference(uploadTime);

    if (difference.inHours < 1) {
      return '${difference.inMinutes} mins ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  void _navigateToFoodDetails(BuildContext context, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoodDetailsScreen(data: data),
      ),
    );
  }

  Widget buildCard(Map<String, dynamic> data, String uploadTime,
      bool isNGOVerified, Position userLocation) {
    GeoPoint foodLocation = data['location'];
    return FutureBuilder<double>(
      future: _calculateDistance(foodLocation, userLocation),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        return Padding(
          padding: EdgeInsets.only(bottom: 24.h),
          child: GestureDetector(
            onTap: () => _navigateToFoodDetails(context, data),
            child: Container(
              width: 312.w,
              height: 220.h,
              decoration: BoxDecoration(
                color: AppColors.basePrimaryColor,
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 5,
                    color: AppColors.kBlackColor.withOpacity(0.4),
                  ),
                ],
                image: DecorationImage(
                  image: NetworkImage(data['imageUrl'] ?? ''),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10.0,
                      horizontal: 10.0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 219.0,
                          decoration: BoxDecoration(
                            color: AppColors.kWhiteColor.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(32.0),
                            border: Border.all(color: AppColors.kWhiteColor),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 7.0,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on_outlined),
                              const SizedBox(width: 4.0),
                              Expanded(
                                child: Text(
                                  _truncateText(data['venue'], 20),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Column(
                          children: [
                            _circularButton(
                              icon: Icons.favorite_border_outlined,
                              onTap: () {},
                            ),
                            const SizedBox(height: 12.0),
                            _circularButton(
                              icon: Icons.share_rounded,
                              onTap: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 8.0,
                    ),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16.0, 18.0, 16.0, 11.0),
                      decoration: BoxDecoration(
                        color: AppColors.kWhiteColor,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _customText(
                            headerText: 'UPLOADED BY:',
                            text: '${data['fullName']}',
                          ),
                          _customVerticalDivider(),
                          _customText(
                            headerText: 'FOOD TYPE:',
                            text: '${data['foodType']}',
                          ),
                          _customVerticalDivider(),
                          _customText(
                            headerText: 'UPLOAD TIME:',
                            text: '$uploadTime',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('food')
          .doc('sharedfood')
          .collection('foodData')
          .where('dailyActive', isEqualTo: dailyActive)
          .where('verified',
              isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        List<QueryDocumentSnapshot<Map<String, dynamic>>> foodDocs =
            snapshot.data?.docs ?? [];

        return FutureBuilder<Position>(
          future: Geolocator.getCurrentPosition(),
          builder: (context, positionSnapshot) {
            if (positionSnapshot.connectionState == ConnectionState.waiting) {
              return Container(
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              );
            } else if (positionSnapshot.hasError) {
              return Text('Error: ${positionSnapshot.error}');
            }

            Position userLocation = positionSnapshot.data!;

            // Filter and sort food docs by location and verification status
            foodDocs = foodDocs.where((doc) {
              GeoPoint foodLocation = doc.data()['location'];
              double distance = Geolocator.distanceBetween(
                userLocation.latitude,
                userLocation.longitude,
                foodLocation.latitude,
                foodLocation.longitude,
              );
              return distance <= 30000 &&
                  distance >= 0; // Adjust distance condition here
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                ...(foodDocs.isEmpty
                    ? [const Text('No data available.')]
                    : [
                        ...foodDocs.map((doc) {
                          Map<String, dynamic> data = doc.data();
                          Timestamp timestamp = data['timestamp'];
                          String uploadTime =
                              calculateTimeDifference(timestamp);
                          bool isNGOVerified = data['verified'] ?? false;

                          return GestureDetector(
                            onTap: () => _navigateToFoodDetails(context, data),
                            child: buildCard(
                                data, uploadTime, isNGOVerified, userLocation),
                          );
                        }),
                      ]),
                const SizedBox(height: 5),
              ],
            );
          },
        );
      },
    );
  }
}


// Helper function to truncate text
  String _truncateText(String text, int maxLength) {
    return (text.length > maxLength) ? '${text.substring(0, maxLength)}...' : text;
  }

  // Helper function to build circular buttons
  Widget _circularButton({required IconData icon, required Function() onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.kWhiteColor.withOpacity(0.6),
        child: Icon(
          icon,
          color: AppColors.kBlackColor,
        ),
      ),
    );
  }

  // Helper function to build custom text widgets
  Widget _customText({required String headerText, required String text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          headerText,
          style: TextStyle(
            fontSize: 10.sp,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          text,
          style: TextStyle(
            fontSize: 12.sp,
            color: AppColors.kBlackColor,
          ),
        ),
      ],
    );
  }

  // Helper function to build custom vertical divider
  Widget _customVerticalDivider() {
    return Container(
      height: 20.0,
      width: 1.0,
      color: Colors.grey,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
    );
  }
