import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

// Screens
import 'features/auth/presentation/login_page.dart';
import 'features/dashboard/presentation/dashboard_page.dart';
import 'features/auth/presentation/create_password.dart';
import 'features/auth/presentation/splash_screen.dart';
import 'features/auth/presentation/forgot_password.dart';
import 'features/admin/admin_home_page.dart';

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
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Colors.black,
          secondary: Colors.grey[800],
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/dashboard': (context) => const DashboardPage(), // seller dashboard
        '/create-password': (context) => const CreatePasswordPage(),
        '/admin-dashboard': (context) => const AdminHomePage(), // ✅ new admin dashboard
      },
    );
  }
}
