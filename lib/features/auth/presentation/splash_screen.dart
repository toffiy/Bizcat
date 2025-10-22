import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Screens
import 'login_page.dart';
import 'package:bizcat/features/dashboard/presentation/dashboard_page.dart';
import 'package:bizcat/features/admin/admin_home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Adjust duration to match your GIF length
    Timer(const Duration(seconds: 3), () {
      _checkUserRole();
    });
  }

  Future<void> _checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Not logged in → go to login
      Navigator.of(context).pushReplacement(
        _createFadeRoute(const LoginPage()),
      );
      return;
    }

    final uid = user.uid;

    try {
      // 🔹 Check if UID is in admin collection
      final adminDoc = await FirebaseFirestore.instance
          .collection('admin')
          .doc(uid)
          .get();

      if (adminDoc.exists) {
        Navigator.of(context).pushReplacement(
          _createFadeRoute(const AdminHomePage()),
        );
        return;
      }

      // 🔹 Otherwise check sellers
      final sellerDoc = await FirebaseFirestore.instance
          .collection('sellers')
          .doc(uid)
          .get();

      if (sellerDoc.exists) {
        Navigator.of(context).pushReplacement(
          _createFadeRoute(const DashboardPage()),
        );
      } else {
        // fallback if user exists but no role
        Navigator.of(context).pushReplacement(
          _createFadeRoute(const LoginPage()),
        );
      }
    } catch (e) {
      // In case of error, go back to login
      Navigator.of(context).pushReplacement(
        _createFadeRoute(const LoginPage()),
      );
    }
  }

  /// Custom fade transition
  Route _createFadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 800),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover, // ensures no gaps on any device
          child: Image.asset(
            "assets/splash.gif", // replace with your BizCat splash asset
          ),
        ),
      ),
    );
  }
}
