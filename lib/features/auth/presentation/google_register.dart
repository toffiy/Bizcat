import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoogleRegisterPage extends StatefulWidget {
  final User user;
  const GoogleRegisterPage({super.key, required this.user});

  @override
  State<GoogleRegisterPage> createState() => _GoogleRegisterPageState();
}

class _GoogleRegisterPageState extends State<GoogleRegisterPage> {
  final _passwordController = TextEditingController();
  String _message = "";
  bool _loading = false;

  Future<void> _setPassword() async {
    final password = _passwordController.text.trim();
    if (password.length < 6) {
      setState(() => _message = "Password must be at least 6 characters.");
      return;
    }

    setState(() {
      _loading = true;
      _message = "";
    });

    try {
      final email = widget.user.email!;
      final credential = EmailAuthProvider.credential(email: email, password: password);

      await widget.user.linkWithCredential(credential);

      setState(() => _message = "Password set successfully ✅");
      // Navigate to dashboard or login
    } on FirebaseAuthException catch (e) {
      setState(() => _message = "Error: ${e.message}");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Set Your Password")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Welcome, ${widget.user.displayName ?? widget.user.email}"),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Create Password",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _setPassword,
                    child: const Text("Save Password"),
                  ),
            const SizedBox(height: 10),
            Text(
              _message,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
