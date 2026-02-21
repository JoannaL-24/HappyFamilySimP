import 'package:go_router/go_router.dart';
import 'package:happy_family_sim/core/constants.dart';
import 'package:happy_family_sim/core/widgets/main_wrapper.dart';
import 'package:happy_family_sim/features/auth/data/auth_repository.dart';
import 'package:happy_family_sim/features/auth/ui/login_view.dart';
import 'package:happy_family_sim/features/auth/ui/signup_view.dart';
import 'package:happy_family_sim/features/auth/ui/welcome_view.dart';
import 'package:happy_family_sim/features/game/game_view.dart';
import 'package:happy_family_sim/features/management/ui/manage_view.dart';
import 'package:happy_family_sim/features/profile/ui/profile_view.dart';
import 'package:happy_family_sim/features/tasks/ui/child/tasks_view.dart';
import 'package:happy_family_sim/features/tasks/ui/parent/tasks_view.dart';

GoRouter createRouter(
  AuthRepository authRepository,
  String userRole,
  Function(String) onLoginSucess,
) {
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

  final childBranches = [
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/child/tasks',
          builder: (context, state) => const ChildTasksScreen(),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/chlid/game',
          builder: (context, state) => const GameScreen(),
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
    initialLocation: () {
      switch (userRole) {
        case Constants.parentRole:
          return '/parent/tasks';
        case Constants.childRole:
          return '/child/tasks';
        default:
          return '/';
      }
    }(),
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
            builder: (context, state) => LoginScreen(
              authRepository: authRepository,
              onLoginSuccess: onLoginSucess,
            ),
          ),
          GoRoute(
            path: 'game',
            builder: (context, state) => const GameScreen(),
          ),
        ],
      ),
      if (userRole != Constants.guestRole)
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainWrapper(
              navigationShell: navigationShell,
              userRole: userRole,
            );
          },
          branches: userRole == Constants.parentRole
              ? parentBranches
              : childBranches,
        ),
    ],
  );
}
