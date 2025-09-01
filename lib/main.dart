import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'features/auth/presentation/login_page.dart';
import 'features/auth/presentation/register_page.dart';
import 'features/dashboard/presentation/dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BizCat',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white, // whole app background
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white, // white app bar
          elevation: 0,
          foregroundColor: Colors.black, // black text/icons
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Colors.black, // primary accent color
          secondary: Colors.grey[800], // secondary accent
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => AuthGate(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/dashboard': (context) => DashboardPage(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return user != null ? DashboardPage() : const LoginPage();
  }
}
