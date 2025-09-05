import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});
  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final emailCtl = TextEditingController();

  Future<void> _reset() async {
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: emailCtl.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Reset link sent to ${emailCtl.text}")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          TextField(controller: emailCtl, decoration: const InputDecoration(labelText: "Enter your email")),
          const SizedBox(height: 20),
          ElevatedButton(
              onPressed: _reset,
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50)),
              child: const Text("Send Reset Link"))
        ]),
      ),
    );
  }
}
