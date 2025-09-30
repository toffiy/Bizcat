import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'package:bizcat/features/dashboard/presentation/dashboard_page.dart';

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
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Already logged in → go to dashboard
        Navigator.of(context).pushReplacement(
          _createFadeRoute(const DashboardPage()),
        );
      } else {
        // Not logged in → go to login
        Navigator.of(context).pushReplacement(
          _createFadeRoute(const LoginPage()),
        );
      }
    });
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
