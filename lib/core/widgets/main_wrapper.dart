import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:happy_family_sim/core/constants.dart';

class MainWrapper extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final String userRole;

  const MainWrapper({
    super.key,
    required this.navigationShell,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(index),
        type: BottomNavigationBarType.fixed,
        items: userRole == Constants.parentRole ? _parentTabs : _childTabs,
      ),
    );
  }

  static const List<BottomNavigationBarItem> _parentTabs = [
    BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Tasks'),
    // BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Manage'),
    BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Manage'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
  ];

  static const List<BottomNavigationBarItem> _childTabs = [
    BottomNavigationBarItem(icon: Icon(Icons.task_alt), label: 'Tasks'),
    BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Game'),
    // BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Shop'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Me'),
  ];
}
