import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/presentation/login_page.dart';

class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({super.key});

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    // Clear navigation stack and go back to login
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          const SizedBox(height: 20),

          // Admin Profile Section
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: const Text("Admin User"),
            subtitle: const Text("admin@bizcat.app"),
          ),

          const Divider(),

      
          // Sign Out
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Sign Out"),
            onTap: () => _signOut(context),
          ),
        ],
      ),
    );
  }
}
