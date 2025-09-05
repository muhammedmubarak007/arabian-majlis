import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'role_selection.dart';
import 'change_password_page.dart';

class DeliveryItem {
  String bill;
  String location;
  DateTime? startTime;
  int elapsedSeconds;
  bool running;

  DeliveryItem({
    required this.bill,
    required this.location,
    this.startTime,
    this.elapsedSeconds = 0,
    this.running = false,
  });
}

class DeliveryDashboard extends StatefulWidget {
  final User user;
  const DeliveryDashboard({super.key, required this.user});

  @override
  State<DeliveryDashboard> createState() => _DeliveryDashboardState();
}

class _DeliveryDashboardState extends State<DeliveryDashboard> {
  final TextEditingController billCtl = TextEditingController();
  final TextEditingController locCtl = TextEditingController();

  final List<DeliveryItem> deliveries = [];
  Timer? timer;
  bool deliveriesStarted = false;

  bool get canAdd =>
      (billCtl.text.trim().isNotEmpty) && (locCtl.text.trim().isNotEmpty);

  void _addDelivery() {
    if (!canAdd) return;
    setState(() {
      deliveries.add(
        DeliveryItem(
          bill: billCtl.text.trim(),
          location: locCtl.text.trim(),
        ),
      );
      billCtl.clear();
      locCtl.clear();
    });
    FocusScope.of(context).unfocus();
  }

  void _startAll() {
    if (deliveries.isEmpty) return;

    setState(() {
      for (var d in deliveries) {
        d.startTime = DateTime.now();
        d.running = true;
        d.elapsedSeconds = 0;
      }
      deliveriesStarted = true;
    });

    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        for (var d in deliveries.where((d) => d.running)) {
          d.elapsedSeconds += 1;
        }
      });
    });
  }

  Future<void> _reachDelivery(DeliveryItem delivery) async {
    if (delivery.startTime == null) return;

    final stopTime = DateTime.now();
    final durationMinutes = stopTime.difference(delivery.startTime!).inMinutes;

    try {
      await FirebaseFirestore.instance.collection("deliveries").add({
        "billNo": delivery.bill,
        "location": delivery.location,
        "startAt": Timestamp.fromDate(delivery.startTime!),
        "stopAt": Timestamp.fromDate(stopTime),
        "durationMinutes": durationMinutes,
        "createdBy": widget.user.email ?? "Unknown",
        "userId": widget.user.uid,
        "createdAt": FieldValue.serverTimestamp(),
      });

      setState(() {
        deliveries.remove(delivery);
        if (deliveries.isEmpty) {
          deliveriesStarted = false;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Delivery completed successfully!",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error saving delivery: $e",
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _cancelDelivery(DeliveryItem delivery) {
    setState(() {
      deliveries.remove(delivery);
    });
  }

  String formatTime(int seconds) {
    final hrs = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hrs > 0) {
      return "${hrs.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
    }
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'change_password':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
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
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Logout",
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        content: const Text(
          "Are you sure you want to logout?",
          style: TextStyle(color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel", style: TextStyle(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                    (_) => false,
              );
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Delivery Dashboard",
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuSelection,
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'change_password',
                child: ListTile(
                  leading: Icon(Icons.lock_reset, color: Colors.black87),
                  title: Text('Change Password', style: TextStyle(color: Colors.black87)),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.black87),
                  title: Text('Logout', style: TextStyle(color: Colors.black87)),
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // User info card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: Colors.black87, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.user.email ?? "User",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Delivery Personnel",
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Input form & start button area, scrollable if needed
            if (!deliveriesStarted)
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[200]!, width: 1),
                        ),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.local_shipping, color: Colors.black87, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    "New Delivery",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.black87),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: billCtl,
                                decoration: InputDecoration(
                                  labelText: "Bill Number",
                                  labelStyle: const TextStyle(color: Colors.black54),
                                  prefixIcon: const Icon(Icons.receipt_long,
                                      color: Colors.black87, size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.grey),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black87),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: locCtl,
                                decoration: InputDecoration(
                                  labelText: "Delivery Location",
                                  labelStyle: const TextStyle(color: Colors.black54),
                                  prefixIcon: const Icon(Icons.location_on,
                                      color: Colors.black87, size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.grey),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black87),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.add_box, size: 20),
                                  label: const Text("ADD DELIVERY"),
                                  onPressed: canAdd ? _addDelivery : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: canAdd ? Colors.black87 : Colors.grey[300],
                                    foregroundColor: canAdd ? Colors.white : Colors.grey[500],
                                    padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.play_arrow, size: 22),
                          label: const Text("START ALL DELIVERIES",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          onPressed: deliveries.isNotEmpty ? _startAll : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            deliveries.isNotEmpty ? Colors.black87 : Colors.grey[300],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 10),

            // Active deliveries label and count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Active Deliveries",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.inventory_2,
                        size: 16,
                        color: Colors.black87,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "${deliveries.length}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Expanded scrollable deliveries list
            Expanded(
              child: deliveries.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_shipping, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    const Text(
                      "No deliveries added",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Add a delivery to get started",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: deliveries.length,
                itemBuilder: (context, index) {
                  final d = deliveries[index];
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[200]!, width: 1),
                    ),
                    color: Colors.white,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: d.running
                              ? Colors.grey[100]
                              : Colors.grey[50],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          d.running ? Icons.delivery_dining : Icons.access_time,
                          color: Colors.black87,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        "Bill #${d.bill}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.place,
                                color: Colors.black87,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  d.location,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.timer,
                                color: Colors.black87,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  d.running
                                      ? "Elapsed: ${formatTime(d.elapsedSeconds)}"
                                      : "Ready to start",
                                  style: TextStyle(
                                    color: d.running ? Colors.black87 : Colors.grey,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: d.running
                          ? ElevatedButton.icon(
                        icon: const Icon(Icons.flag, size: 16),
                        label: const Text("REACH", style: TextStyle(fontSize: 12)),
                        onPressed: () => _reachDelivery(d),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      )
                          : ElevatedButton.icon(
                        icon: const Icon(Icons.cancel, size: 16),
                        label: const Text("CANCEL", style: TextStyle(fontSize: 12)),
                        onPressed: () => _cancelDelivery(d),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
