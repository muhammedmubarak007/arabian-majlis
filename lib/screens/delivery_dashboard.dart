import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'role_selection.dart';
import 'change_password_page.dart';

class DeliveryDashboard extends StatefulWidget {
  final User user;
  const DeliveryDashboard({super.key, required this.user});

  @override
  State<DeliveryDashboard> createState() => _DeliveryDashboardState();
}

class _DeliveryDashboardState extends State<DeliveryDashboard> {
  final billCtl = TextEditingController();
  final locCtl = TextEditingController();

  DateTime? startTime;
  bool running = false;
  Timer? timer;
  int elapsedSeconds = 0;

  bool get canStart =>
      billCtl.text.trim().isNotEmpty && locCtl.text.trim().isNotEmpty;

  void _start() {
    if (!canStart) return;

    setState(() {
      startTime = DateTime.now();
      running = true;
      elapsedSeconds = 0;
    });

    // Start live timer
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        elapsedSeconds += 1;
      });
    });
  }

  Future<void> _stop() async {
    if (startTime == null) return;

    final stopTime = DateTime.now();
    timer?.cancel();

    final durationMinutes = stopTime.difference(startTime!).inMinutes;

    try {
      await FirebaseFirestore.instance.collection("deliveries").add({
        "billNo": billCtl.text.trim(),
        "location": locCtl.text.trim(),
        "startAt": Timestamp.fromDate(startTime!),
        "stopAt": Timestamp.fromDate(stopTime),
        "durationMinutes": durationMinutes,
        "createdBy": widget.user.email ?? "Unknown",
        "userId": widget.user.uid,
        "createdAt": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Delivery saved successfully!",
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.grey[300],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Reset form
      setState(() {
        running = false;
        startTime = null;
        elapsedSeconds = 0;
        billCtl.clear();
        locCtl.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error saving delivery: $e",
            style: const TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.grey[300],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    billCtl.addListener(() => setState(() {}));
    locCtl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    billCtl.dispose();
    locCtl.dispose();
    timer?.cancel();
    super.dispose();
  }

  String formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'change_password':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ChangePasswordPage(),
          ),
        );
        break;
      case 'logout':
        _showLogoutConfirmation();
        break;
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text("Logout", style: TextStyle(color: Colors.black)),
          content: const Text("Are you sure you want to logout?", style: TextStyle(color: Colors.black)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel", style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RoleSelectionScreen(),
                  ),
                      (_) => false,
                );
              },
              child: const Text("Logout", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Delivery Dashboard", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          // Popup menu button
          PopupMenuButton<String>(
            onSelected: _handleMenuSelection,
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'change_password',
                child: ListTile(
                  leading: Icon(Icons.lock_reset, color: Colors.black),
                  title: Text('Change Password', style: TextStyle(color: Colors.black)),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.black),
                  title: Text('Logout', style: TextStyle(color: Colors.black)),
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert, color: Colors.black),
            color: Colors.white,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome, ${widget.user.email?.split('@').first ?? 'Delivery Partner'}!",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Track your delivery time efficiently",
                    style: TextStyle(
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Bill Number Input
            TextField(
              controller: billCtl,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                labelText: "Bill Number",
                labelStyle: const TextStyle(color: Colors.black54),
                prefixIcon: const Icon(Icons.receipt, color: Colors.black54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black54),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black54),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Location Input
            TextField(
              controller: locCtl,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                labelText: "Delivery Location",
                labelStyle: const TextStyle(color: Colors.black54),
                prefixIcon: const Icon(Icons.location_on, color: Colors.black54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black54),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black54),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Timer Display with Clock Icon
            if (running)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    // Clock icon and title row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time, color: Colors.black, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          "Elapsed Time",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Timer display
                    Text(
                      formatTime(elapsedSeconds),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Start/Stop Button
            ElevatedButton(
              onPressed: canStart ? (running ? _stop : _start) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: running ? Colors.red : Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Text(
                running ? "STOP DELIVERY" : "START DELIVERY",
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Hint text when fields are empty
            if (!canStart)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "Please enter both bill number and location to start tracking",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.black54,
                      fontStyle: FontStyle.italic
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}