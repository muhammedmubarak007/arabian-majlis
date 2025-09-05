import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/role_selection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const DeliveryApp());
}

class DeliveryApp extends StatelessWidget {
  const DeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Delivery Tracker",
      theme: ThemeData(
        brightness: Brightness.light, // Light theme
        primaryColor: Colors.white,   // App primary color
        scaffoldBackgroundColor: Colors.white, // App background
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,      // AppBar color
        ),
      ),
      home: const RoleSelectionScreen(),
    );
  }
}
