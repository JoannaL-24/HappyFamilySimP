import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:happy_family_sim/features/auth/ui/signup_view.dart';
import 'package:happy_family_sim/features/auth/ui/welcome_view.dart';
import 'package:happy_family_sim/features/game/game_view.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const WelcomeScreen(),
      routes: [
        // children routes, have a back button
        GoRoute(
          path: 'signup',
          builder: (context, state) => const SignUpScreen(),
        ),
        GoRoute(
          path: 'login',
          builder: (context, state) => const Placeholder(),
        ),
        GoRoute(path: 'game', builder: (context, state) => const GameScreen()),
      ],
    ),
    // other routes
  ],
);
