import 'package:flutter/material.dart';
import '../Services/auth_service.dart';
import '../Services/google_auth_service.dart';
import '../widgets/login_design.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  String _message = "";
  bool _isLoading = false;

  void _login() async {
    setState(() => _isLoading = true);
    final error = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    if (error != null) {
      setState(() {
        _message = error;
        _isLoading = false;
      });
    } else {
      setState(() {
        _message = "Login successful ✅";
        _isLoading = false;
      });
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  void _handleGoogleSignIn() async {
    setState(() {
      _message = "";
      _isLoading = true;
    });
    final result = await _googleAuthService.signInWithGoogle();
    setState(() => _isLoading = false);

    if (result == "NEW_ACCOUNT" || result == "SET_PASSWORD") {
      Navigator.pushNamed(context, '/create-password');
    } else if (result == "LOGIN_SUCCESS") {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      setState(() => _message = result ?? "Google sign-in failed.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromRGBO(110, 198, 255, 1),
              Color.fromRGBO(13, 71, 161, 1)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LoginDesign(
            emailController: _emailController,
            passwordController: _passwordController,
            onLogin: _login,
            onForgotPassword: () {
              Navigator.pushNamed(context, '/forgot-password');
            },
            onGoogleSignIn: _handleGoogleSignIn,
            message: _message,
            isLoading: _isLoading,
          ),
        ),
      ),
    );
  }
}
