import 'package:flutter/material.dart';

class AdminPanelScreen extends StatelessWidget {
  final VoidCallback onSwitchToUser;
  const AdminPanelScreen({super.key, required this.onSwitchToUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Console', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: onSwitchToUser,
          ),
        ],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.admin_panel_settings_rounded, size: 72, color: Color(0xFFFF6B00)),
              SizedBox(height: 16),
              Text('Admin Dashboard Live', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Manage tasks, verify users, and approve withdrawal payouts.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
