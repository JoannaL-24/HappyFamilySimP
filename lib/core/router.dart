import 'package:go_router/go_router.dart';
import 'package:happy_family_sim/core/constants.dart';
import 'package:happy_family_sim/core/widgets/main_wrapper.dart';
import 'package:happy_family_sim/features/analytics/data/analytics_repository.dart';
import 'package:happy_family_sim/features/auth/data/auth_repository.dart';
import 'package:happy_family_sim/features/auth/ui/login_view.dart';
import 'package:happy_family_sim/features/auth/ui/forgot_password_view.dart';
import 'package:happy_family_sim/features/auth/ui/signup_view.dart';
import 'package:happy_family_sim/features/auth/ui/welcome_view.dart';
import 'package:happy_family_sim/features/game/data/cosmetic_repository.dart';
import 'package:happy_family_sim/features/game/data/game_repository.dart';
import 'package:happy_family_sim/features/game/game_view.dart';
import 'package:happy_family_sim/features/management/data/manage_repository.dart';
import 'package:happy_family_sim/features/management/ui/manage_view.dart';
import 'package:happy_family_sim/features/analytics/ui/analytics_entry_view.dart';
import 'package:happy_family_sim/features/analytics/ui/task_report_view.dart';
import 'package:happy_family_sim/features/analytics/ui/task_statistics_view.dart';
import 'package:happy_family_sim/features/analytics/ui/task_history_view.dart'
    as parent_history;
import 'package:happy_family_sim/features/profile/data/profile_repository.dart';
import 'package:happy_family_sim/features/profile/ui/parent/profile_view.dart';
import 'package:happy_family_sim/features/profile/ui/child/profile_view.dart';
import 'package:happy_family_sim/features/approval/ui/approval_view.dart';
import 'package:happy_family_sim/features/tasks/data/task_repository.dart';
import 'package:happy_family_sim/features/tasks/ui/child/tasks_view.dart';
import 'package:happy_family_sim/features/tasks/ui/child/task_history_view.dart'
    as child_history;
import 'package:happy_family_sim/features/tasks/ui/parent/tasks_view.dart';

GoRouter createRouter(
  AuthRepository authRepository,
  ProfileRepository profileRepository,
  ManageRepository manageRepository,
  GameRepository gameRepository,
  CosmeticRepository cosmeticRepository,
  TaskRepository taskRepository,
  AnalyticsRepository analyticsRepository,
  String userRole,
  Function(String) onLoginSucess,
) {
  final parentBranches = [
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/parent/tasks',
          builder: (context, state) =>
              ParentTasksScreen(authRepository: authRepository),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/parent/approval',
          builder: (context, state) =>
              ParentApprovalScreen(authRepository: authRepository),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/parent/analytics',
          builder: (context, state) => const AnalyticsEntryScreen(),
          routes: [
            GoRoute(
              path: 'report',
              builder: (context, state) => TaskReportScreen(
                authRepository: authRepository,
                manageRepository: manageRepository,
                analyticsRepository: analyticsRepository,
              ),
            ),
            GoRoute(
              path: 'statistics',
              builder: (context, state) => TaskStatisticsScreen(
                authRepository: authRepository,
                manageRepository: manageRepository,
                analyticsRepository: analyticsRepository,
              ),
            ),
            GoRoute(
              path: 'history',
              builder: (context, state) => parent_history.ParentTaskHistoryScreen(
                authRepository: authRepository,
              ),
            )
          ],
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/parent/management',
          builder: (context, state) => ManageChildrenScreen(
            authRepository: authRepository,
            manageRepository: manageRepository,
          ),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/parent/profile',
          builder: (context, state) => ParentProfileScreen(
            authRepository: authRepository,
            profileRepository: profileRepository,
          ),
        ),
      ],
    ),
  ];

  final childBranches = [
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/child/tasks',
          builder: (context, state) =>
              ChildTasksScreen(authRepository: authRepository),
          routes: [
            GoRoute(
              path: 'history',
              builder: (context, state) =>
                  child_history.TaskHistoryScreen(authRepository: authRepository),
            ),
          ],
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/chlid/game',
          builder: (context, state) => GameScreen(
            gameRepository: gameRepository,
            cosmeticRepository: cosmeticRepository,
          ),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/child/profile',
          builder: (context, state) => ChildProfileScreen(
            authRepository: authRepository,
            profileRepository: profileRepository,
          ),
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
            builder: (context, state) => SignUpScreen(
              authRepository: authRepository,
              onLoginSuccess: onLoginSucess,
            ),
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
            builder: (context, state) => GameScreen(
              gameRepository: gameRepository,
              cosmeticRepository: cosmeticRepository,
            ),
          ),
          GoRoute(
            path: 'forgot-password',
            builder: (context, state) =>
                ForgotPasswordScreen(authRepository: authRepository),
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
