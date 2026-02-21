import 'package:flutter/material.dart';

// TODO: replace the placeholder class later
class ChildTasksScreen extends StatelessWidget {
  const ChildTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Child Tasks Page')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This is the child tasks page 🚀',
              style: TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
