import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  User? get currentUser => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _endLiveAndHideAll();
    }
  }

  Future<void> _endLiveAndHideAll() async {
    final user = currentUser;
    if (user == null) {
      debugPrint("❌ No authenticated user, skipping end live.");
      return;
    }

    final userId = user.uid;

    try {
      // 1️⃣ Get all products for this seller
      final productsSnapshot = await FirebaseFirestore.instance
          .collection('sellers')
          .doc(userId)
          .collection('products')
          .get();

      // 2️⃣ Batch update all products to hide them
      final batch = FirebaseFirestore.instance.batch();
      for (var productDoc in productsSnapshot.docs) {
        batch.update(productDoc.reference, {'isVisible': false});
      }

      // 3️⃣ Update seller live status safely (create if missing)
      final sellerRef = FirebaseFirestore.instance.collection('sellers').doc(userId);
      batch.set(sellerRef, {
        'isLive': false,
        'fbLiveLink': FieldValue.delete(),
      }, SetOptions(merge: true));

      // 4️⃣ Commit all changes atomically
      await batch.commit();

      debugPrint("✅ Live ended for $userId, all products hidden.");
    } catch (e) {
      debugPrint("❌ Error ending live: $e");
    }
  }

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
        '/dashboard': (context) => const DashboardPage(),
        '/create-password': (context) => const CreatePasswordPage(),
        '/admin-dashboard': (context) => const AdminHomePage(),
      },
    );
  }
}
