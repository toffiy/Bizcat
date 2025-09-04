import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../Services/auth_service.dart';
import '../Services/google_auth_service.dart';

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

  // Email/Password login
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

  // Reset password
  void _resetPassword() async {
    final error = await _authService.resetPassword(
      _emailController.text.trim(),
    );

    if (error != null) {
      setState(() => _message = error);
    } else {
      setState(() =>
          _message = "Password reset email sent ✅ Check your inbox.");
    }
  }

// Google Sign-In
void _handleGoogleSignIn() async {
  setState(() {
    _message = "";
    _isLoading = true;
  });

  final result = await _googleAuthService.signInWithGoogle();

  setState(() => _isLoading = false);

  if (result == "NEW_ACCOUNT") {
    // New Google account → go to create password screen
    Navigator.pushNamed(context, '/create-password');
  } else if (result == "SET_PASSWORD") {
    // Existing account but no password set → go to create password screen
    Navigator.pushNamed(context, '/create-password');
  } else if (result == "LOGIN_SUCCESS") {
    // Existing account with password → go straight to dashboard
    Navigator.pushReplacementNamed(context, '/dashboard');
  } else {
    // Any error or cancellation
    setState(() => _message = result ?? "Google sign-in failed.");
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.blueLight, AppColors.blueDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Welcome Back",
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.blueDark,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                TextField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: "Email",
                                    labelStyle:
                                        TextStyle(color: AppColors.blueDark),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                TextField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    labelText: "Password",
                                    labelStyle:
                                        TextStyle(color: AppColors.blueDark),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.blue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const CircularProgressIndicator(
                                            color: Colors.white,
                                          )
                                        : const Text(
                                            "Login",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _resetPassword,
                                  child: Text(
                                    "Forgot Password?",
                                    style: TextStyle(color: AppColors.blueDark),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/register');
                                  },
                                  child: Text(
                                    "Create Account",
                                    style: TextStyle(color: AppColors.blueDark),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Google Sign-In Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        _isLoading ? null : _handleGoogleSignIn,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: const BorderSide(
                                            color: Colors.grey),
                                      ),
                                    ),
                                
                                    label: const Text(
                                      "Sign in with Google",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 10),
                                Text(
                                  _message,
                                  style: TextStyle(
                                    color: _message.contains("✅")
                                        ? Colors.green
                                        : Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
