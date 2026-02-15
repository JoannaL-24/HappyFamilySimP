import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainWrapper extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  // final String userRole; // Passed in from the Router

  const MainWrapper({
    super.key, 
    required this.navigationShell, 
    // required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(index),
        type: BottomNavigationBarType.fixed,
        // Logic to switch the items based on the passed string
        // items: userRole == 'parent' ? _parentTabs : _childTabs,
        items: _parentTabs,
      ),
    );
  }

  static const List<BottomNavigationBarItem> _parentTabs = [
    BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Tasks'),
    // BottomNavigationBarItem(icon: Icon(Icons.add_task), label: 'Assign'),
    // BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Manage'),
    BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Manage'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
  ];

  // static const List<BottomNavigationBarItem> _childTabs = [
  //   BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Game'),
  //   BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Tasks'),
  //   BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Shop'),
  //   BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Me'),
  // ];
}
