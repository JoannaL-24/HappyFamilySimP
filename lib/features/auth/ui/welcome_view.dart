import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.family_restroom_rounded,
                size: 80,
                color: Color(0xFF4A90E2),
              ),
              const SizedBox(height: 16),
              const Text(
                'Happy Family Sim',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                child: Text(
                  'Manage chores and care for your virtual creature together!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 48),

              // game button
              ElevatedButton.icon(
                onPressed: () => context.go('/game'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(250, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text(
                  'Play Game',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),

              // parent app button
              ElevatedButton.icon(
                onPressed: () => context.go('/parent/tasks'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(250, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                ),
                label: const Text(
                  'Parent App Temp',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),

              // child app button
              ElevatedButton.icon(
                onPressed: () => context.go('/child/tasks'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(250, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                ),
                label: const Text(
                  'Child App Temp',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),

              // login button
              OutlinedButton(
                onPressed: () => context.go('/login'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(250, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                child: const Text('Login', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 25),

              Column(
                children: [
                  const Text(
                    "Don't have an account?",
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),

                  // signup button
                  TextButton(
                    onPressed: () => context.go('/signup'),
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
