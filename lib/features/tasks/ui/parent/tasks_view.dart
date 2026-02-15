import 'package:flutter/material.dart';

// TODO: replace the placeholder class later
class ParentTasksScreen extends StatelessWidget {
  const ParentTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parent Tasks Page')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('This is the parent tasks page 🚀', style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
