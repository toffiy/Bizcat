import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/colors.dart';

class CreatePasswordPage extends StatefulWidget {
  const CreatePasswordPage({super.key});

  @override
  State<CreatePasswordPage> createState() => _CreatePasswordPageState();
}

class _CreatePasswordPageState extends State<CreatePasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String _message = "";

  /// Returns a list of missing password requirements
  List<String> _passwordValidationErrors(String password) {
    final errors = <String>[];

    if (password.length < 8) {
      errors.add("at least 8 characters");
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      errors.add("an uppercase letter");
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      errors.add("a lowercase letter");
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      errors.add("a number");
    }
    if (!RegExp(r'[@$%*?&-_]').hasMatch(password)) {
      errors.add("a special character");
    }

    return errors;
  }

  Future<void> _savePassword() async {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password.isEmpty || confirmPassword.isEmpty) {
      setState(() => _message = "Please fill in all fields.");
      return;
    }
    if (password != confirmPassword) {
      setState(() => _message = "Passwords do not match.");
      return;
    }

    final missing = _passwordValidationErrors(password);
    if (missing.isNotEmpty) {
      setState(() => _message = "Password must include ${missing.join(', ')}.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _message = "No signed-in user found.";
          _isLoading = false;
        });
        return;
      }

      // Set password for Google account
      await user.updatePassword(password);

      // Mark hasPassword = true in Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': user.email,
        'firstName': user.displayName?.split(' ').first ?? '',
        'lastName': user.displayName?.split(' ').skip(1).join(' ') ?? '',
        'role': 'seller',
        'createdAt': FieldValue.serverTimestamp(),
        'googleSignIn': true,
        'hasPassword': true,
      }, SetOptions(merge: true));

      setState(() {
        _message = "Password set successfully ✅";
        _isLoading = false;
      });

      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      setState(() {
        _message = "Error: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Set Your Password"),
        backgroundColor: AppColors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "New Password"),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Confirm Password"),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _savePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save Password"),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _message,
              style: TextStyle(
                color: _message.contains("✅") ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
