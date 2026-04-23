import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';
import 'firebase_options.dart';

// This is the starting point of the whole Flutter app.
Future<void> main() async {
  // This makes sure Flutter is fully ready before Firebase starts.
  WidgetsFlutterBinding.ensureInitialized();

  // This initializes Firebase using the configuration generated
  // by FlutterFire for the current platform.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // This runs the main app widget after Firebase is ready.
  runApp(const MyApp());
}

// This is the root widget of the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // This removes the debug banner at the top right in development mode.
      debugShowCheckedModeBanner: false,

      // This is the name of the app.
      title: 'Python Mai Farawa',

      // This defines the general theme colors used in the app.
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),

      // This sets the first screen the user will see when the app opens.
      home: const SplashScreen(),
    );
  }
}
