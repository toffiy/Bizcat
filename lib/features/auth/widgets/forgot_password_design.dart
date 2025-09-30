import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

class ForgotPasswordDesign extends StatelessWidget {
  final TextEditingController emailController;
  final VoidCallback onResetPassword;
  final VoidCallback onBackToLogin;
  final String message;
  final bool isLoading;

  const ForgotPasswordDesign({
    super.key,
    required this.emailController,
    required this.onResetPassword,
    required this.onBackToLogin,
    required this.message,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo pinned at the top
        Padding(
          padding: const EdgeInsets.only(top: 40, bottom: 20),
          child: Image.asset(
            "assets/login_logo.png",
            height: 100,
          ),
        ),

        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
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
                        "Reset Password",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blueDark,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Enter your email and we’ll send you a reset link.",
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.blueDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: "Email",
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
                          onPressed: isLoading ? null : onResetPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "Send Reset Link",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: onBackToLogin,
                        child: Text(
                          "Back to Login",
                          style: TextStyle(color: AppColors.blueDark),
                        ),
                      ),
                      if (message.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          message,
                          style: TextStyle(
                            color: message.contains("✅")
                                ? Colors.green
                                : Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
