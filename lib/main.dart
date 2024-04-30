import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:spoonshare/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spoonshare/services/notifications_services.dart';
import 'package:spoonshare/splash_screen.dart';
import 'package:device_preview/device_preview.dart';
import 'common_blocs/common_blocs.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  NotificationServices().firebaseInit();
  await SharedPreferences.getInstance();
  runApp(
    DevicePreview(
       enabled: !kReleaseMode,
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

NavigatorState? get _navigator => navigatorKey.currentState;

 onNavigateSplash() {
  _navigator!.pushAndRemoveUntil(MaterialPageRoute(builder: (context) {
    return const SplashScreen();
  }), (route) => false);
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: CommonBloc.blocProviders,
      child: ScreenUtilInit(
        designSize: const Size(360, 800),
        minTextAdapt: true,
        splitScreenMode: true,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Spoon Share',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xffFF9F1C)),
            useMaterial3: true,
          ),
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
