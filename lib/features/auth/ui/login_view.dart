import 'package:flutter/material.dart';

// TODO: replace the placeholder class later
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('This is the login page 🚀', style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
