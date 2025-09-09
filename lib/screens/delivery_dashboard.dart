import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'role_selection.dart';
import 'change_password_page.dart';

/// Model for a delivery item
class DeliveryItem {
  final String bill;
  final String location;
  final DateTime? startTime;
  final bool running;
  final int elapsedSeconds;

  DeliveryItem({
    required this.bill,
    required this.location,
    this.startTime,
    this.running = false,
    this.elapsedSeconds = 0,
  });

  DeliveryItem copyWith({
    String? bill,
    String? location,
    DateTime? startTime,
    bool? running,
    int? elapsedSeconds,
  }) {
    return DeliveryItem(
      bill: bill ?? this.bill,
      location: location ?? this.location,
      startTime: startTime ?? this.startTime,
      running: running ?? this.running,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    );
  }
}

/// Main delivery dashboard page
class DeliveryDashboard extends StatefulWidget {
  final User user;
  const DeliveryDashboard({super.key, required this.user});

  @override
  State<DeliveryDashboard> createState() => _DeliveryDashboardState();
}

class _DeliveryDashboardState extends State<DeliveryDashboard> {
  final TextEditingController billCtl = TextEditingController();
  final TextEditingController locCtl = TextEditingController();
  List<DeliveryItem> deliveries = [];

  bool get canAdd => billCtl.text.trim().isNotEmpty && locCtl.text.trim().isNotEmpty;

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
    super.dispose();
  }

  void _addDelivery() {
    if (!canAdd) return;
    setState(() {
      deliveries.add(DeliveryItem(
        bill: billCtl.text.trim(),
        location: locCtl.text.trim(),
      ));
      billCtl.clear();
      locCtl.clear();
    });
    FocusScope.of(context).unfocus();
  }

  void _cancelDelivery(DeliveryItem delivery) {
    setState(() {
      deliveries.remove(delivery);
    });
  }

  Future<void> _startAll() async {
    if (deliveries.isEmpty) return;
    final started = deliveries
        .map((d) => d.copyWith(startTime: DateTime.now(), running: true))
        .toList();

    final remaining = await Navigator.push<List<DeliveryItem>>(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveDeliveriesPage(
          user: widget.user,
          initialDeliveries: started,
        ),
      ),
    );

    if (!mounted) return;
    setState(() {
      deliveries = remaining ?? [];
    });
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
        title: const Text("Logout", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
          TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                    context, MaterialPageRoute(builder: (_) => const RoleSelectionScreen()), (_) => false);
              },
              child: const Text("Logout", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Delivery Dashboard", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
        actions: [
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // User Info Card
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.black12,
                      radius: 28,
                      child: Icon(Icons.person, color: Colors.black, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded( // <- prevents overflow
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.user.email ?? "User",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis, // <- ensures long emails don't overflow
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Delivery Personnel",
                            style: TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Add Delivery Card
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.delivery_dining, color: Colors.black),
                        SizedBox(width: 8),
                        Text("New Delivery",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: billCtl,
                      decoration: const InputDecoration(
                        labelText: "Bill Number",
                        prefixIcon: Icon(Icons.receipt, color: Colors.black),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locCtl,
                      decoration: const InputDecoration(
                        labelText: "Delivery Location",
                        prefixIcon: Icon(Icons.location_on, color: Colors.black),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: canAdd ? _addDelivery : null,
                            icon: const Icon(Icons.add, color: Colors.black),
                            label: const Text("Add", style: TextStyle(color: Colors.black)),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: Colors.black12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: deliveries.isNotEmpty ? _startAll : null,
                            icon: const Icon(Icons.play_arrow, color: Colors.black),
                            label: const Text("Start All", style: TextStyle(color: Colors.black)),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: Colors.black12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Pending Deliveries
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Pending Deliveries", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory, size: 16),
                      const SizedBox(width: 6),
                      Text("${deliveries.length}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            deliveries.isEmpty
                ? Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: const Text("Add a new delivery to get started",
                    style: TextStyle(color: Colors.black54, fontSize: 16)))
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: deliveries.length,
              itemBuilder: (context, index) {
                final d = deliveries[index];
                return Card(
                  color: Colors.white,
                  elevation: 1,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const CircleAvatar(
                        backgroundColor: Colors.black12, child: Icon(Icons.delivery_dining, color: Colors.black)),
                    title: Text("Bill #${d.bill}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Row(
                      children: [
                        const Icon(Icons.place, size: 14, color: Colors.black54),
                        const SizedBox(width: 4),
                        Expanded(child: Text(d.location, style: const TextStyle(color: Colors.black87))),
                      ],
                    ),
                    trailing: ElevatedButton.icon(
                      icon: const Icon(Icons.cancel, color: Colors.white),
                      label: const Text("Cancel", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      onPressed: () => _cancelDelivery(d),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Active deliveries page
class ActiveDeliveriesPage extends StatefulWidget {
  final User user;
  final List<DeliveryItem> initialDeliveries;

  const ActiveDeliveriesPage({super.key, required this.user, required this.initialDeliveries});

  @override
  State<ActiveDeliveriesPage> createState() => _ActiveDeliveriesPageState();
}

class _ActiveDeliveriesPageState extends State<ActiveDeliveriesPage> {
  late List<DeliveryItem> deliveries;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    deliveries = widget.initialDeliveries;
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        deliveries = deliveries
            .map((d) => d.running ? d.copyWith(elapsedSeconds: d.elapsedSeconds + 1) : d)
            .toList();
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
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

  Future<void> _reachDelivery(DeliveryItem delivery) async {
    if (delivery.startTime == null) return;

    final stopTime = DateTime.now();
    final durationMinutes = stopTime.difference(delivery.startTime!).inMinutes;

    setState(() {
      deliveries.remove(delivery);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Delivery completed!"), duration: Duration(seconds: 2)),
    );

    FirebaseFirestore.instance.collection("deliveries").add({
      "billNo": delivery.bill,
      "location": delivery.location,
      "startAt": Timestamp.fromDate(delivery.startTime!),
      "stopAt": Timestamp.fromDate(stopTime),
      "durationMinutes": durationMinutes,
      "createdBy": widget.user.email ?? "Unknown",
      "userId": widget.user.uid,
      "createdAt": FieldValue.serverTimestamp(),
    });

    if (deliveries.isEmpty) {
      timer?.cancel();
      if (mounted) {
        Navigator.pop(context, deliveries);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Active Deliveries", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: deliveries.isEmpty
          ? const Center(child: Text("No active deliveries", style: TextStyle(color: Colors.black54)))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: deliveries.length,
        itemBuilder: (context, index) {
          final d = deliveries[index];
          return Card(
            color: Colors.white,
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const CircleAvatar(
                  backgroundColor: Colors.black12, child: Icon(Icons.delivery_dining, color: Colors.black)),
              title: Text("Bill #${d.bill}", style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.place, size: 14, color: Colors.black54),
                      const SizedBox(width: 4),
                      Expanded(child: Text(d.location, style: const TextStyle(color: Colors.black87))),
                    ],
                  ),

                  const SizedBox(height: 4),

                      Text("Time: ${formatTime(d.elapsedSeconds)}",
                          style: const TextStyle(fontSize: 12, color: Colors.black54)),

                ],
              ),
              trailing: ElevatedButton.icon(
                onPressed: () => _reachDelivery(d),
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text("Reached", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              ),
            ),
          );
        },
      ),
    );
  }
}
