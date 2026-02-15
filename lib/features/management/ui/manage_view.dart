import 'package:flutter/material.dart';

class ManageChildrenScreen extends StatelessWidget {
  const ManageChildrenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Children Page')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('This is the chlidren management page 🚀', style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
