import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final emailCtl = TextEditingController();
  bool _loading = false;

  Future<void> _reset() async {
    if (emailCtl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter your email")));
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: emailCtl.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Reset link sent to ${emailCtl.text.trim()}. Check your inbox.")),
      );
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'user-not-found':
          msg = 'No user found for this email.';
          break;
        case 'invalid-email':
          msg = 'Invalid email address.';
          break;
        default:
          msg = e.message ?? 'Something went wrong';
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Firebase initialization failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background
      appBar: AppBar(
        title: const Text(
          "Reset Password",
          style: TextStyle(color: Colors.black), // Black text
        ),
        backgroundColor: Colors.white, // White app bar
        elevation: 0, // Remove shadow
        iconTheme: const IconThemeData(color: Colors.black), // Black back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailCtl,
              decoration: const InputDecoration(
                labelText: "Enter your email",
                labelStyle: TextStyle(color: Colors.black54), // Gray label
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black), // Black border
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black), // Black border
                ),
              ),
              style: const TextStyle(color: Colors.black), // Black text
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _reset,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.black, // Black button
                foregroundColor: Colors.white, // White text
                disabledBackgroundColor: Colors.grey, // Gray when disabled
              ),
              child: _loading
                  ? const CircularProgressIndicator(
                color: Colors.white,
              )
                  : const Text("Send Reset Link"),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Back to Login",
                style: TextStyle(color: Colors.black), // Black text
              ),
            ),
          ],
        ),
      ),
    );
  }
}