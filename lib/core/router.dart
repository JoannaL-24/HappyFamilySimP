import 'package:go_router/go_router.dart';
import 'package:happy_family_sim/core/widgets/main_wrapper.dart';
import 'package:happy_family_sim/features/auth/data/auth_repository.dart';
import 'package:happy_family_sim/features/auth/ui/login_view.dart';
import 'package:happy_family_sim/features/auth/ui/signup_view.dart';
import 'package:happy_family_sim/features/auth/ui/welcome_view.dart';
import 'package:happy_family_sim/features/game/game_view.dart';
import 'package:happy_family_sim/features/management/ui/manage_view.dart';
import 'package:happy_family_sim/features/profile/ui/profile_view.dart';
import 'package:happy_family_sim/features/tasks/ui/parent/tasks_view.dart';

GoRouter createRouter(AuthRepository authRepository) {
  final parentBranches = [
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/parent/tasks',
          builder: (context, state) => const ParentTasksScreen(),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/parent/management',
          builder: (context, state) => const ManageChildrenScreen(),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/parent/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ];

  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const WelcomeScreen(),
        routes: [
          // children routes, have a back button
          GoRoute(
            path: 'signup',
            builder: (context, state) =>
                SignUpScreen(authRepository: authRepository),
          ),
          GoRoute(
            path: 'login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: 'game',
            builder: (context, state) => const GameScreen(),
          ),
        ],
      ),
      // other routes
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainWrapper(navigationShell: navigationShell);
        },
        branches: parentBranches,
      ),
    ],
  );
}
