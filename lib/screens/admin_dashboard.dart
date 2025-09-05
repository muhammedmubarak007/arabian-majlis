import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'role_selection.dart';
import 'change_password_page.dart';
import 'users_tab.dart';
import 'deliveries_tab.dart';

class AdminDashboard extends StatefulWidget {
  final String adminEmail;
  final String adminPassword;

  const AdminDashboard({
    super.key,
    required this.adminEmail,
    required this.adminPassword,
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
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
                  MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          title: const Text(
            "Admin Dashboard",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
          bottom: TabBar(
            indicatorColor: Colors.black,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black54,
            tabs: const [
              Tab(text: "Users"),
              Tab(text: "Deliveries"),
            ],
          ),
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
        body: const TabBarView(
          children: [
            UsersTab(),
            DeliveriesTab(),
          ],
        ),
      ),
    );
  }
}