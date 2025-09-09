import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'screens/role_selection.dart';
import 'screens/admin_dashboard.dart';
import 'screens/delivery_dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final isAdmin = prefs.getBool('isAdmin') ?? false;

  Widget defaultHome = const RoleSelectionScreen();

  if (isLoggedIn && FirebaseAuth.instance.currentUser != null) {
    if (isAdmin) {
      defaultHome = AdminDashboard(
        adminEmail: '',      // Optionally store in prefs
        adminPassword: '',   // Optionally store in prefs
      );
    } else {
      defaultHome = DeliveryDashboard(
        user: FirebaseAuth.instance.currentUser!,
      );
    }
  }

  runApp(DeliveryApp(home: defaultHome));
}

class DeliveryApp extends StatelessWidget {
  final Widget home;

  const DeliveryApp({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Delivery Tracker",
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.white,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
        ),
      ),
      home: home,
    );
  }
}
