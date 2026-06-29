import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/api/api_client.dart';
import '../features/dependents/screens/dependents_screen.dart';
import '../presentation/access_log_screen/access_log_screen.dart';
import '../presentation/digital_membership_card_screen/digital_membership_card_screen.dart';
import '../presentation/home_screen/home_screen.dart';
import '../presentation/profile_screen/profile_screen.dart';
import '../presentation/sign_up_login_screen/sign_up_login_screen.dart';
import '../features/admin/screens/admin_users_screen.dart';
import '../features/admin/screens/admin_user_detail_screen.dart';
import '../widgets/app_scaffold.dart';

class AppRoutes {
  static const String initial = '/';
  static const String signUpLoginScreen = '/sign-up-login-screen';
  static const String homeScreen = '/home-screen';
  static const String digitalMembershipCardScreen =
      '/digital-membership-card-screen';
  static const String profileScreen = '/profile-screen';
  static const String accessLogScreen = '/access-log-screen';
  static const String dependentsScreen = '/dependents';
  static const String adminUsersScreen = '/admin-users';
  static String adminUserDetailPath(int userId) => '/admin-users/$userId';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.initial,
  redirect: (context, state) async {
    final token = await ApiClient.instance.getToken();

    final hasToken = token != null && token.isNotEmpty;

    final currentPath = state.uri.path;

    final isInitialRoute = currentPath == AppRoutes.initial;
    final isLoginRoute = currentPath == AppRoutes.signUpLoginScreen;

    final isPublicRoute = isInitialRoute || isLoginRoute;

    if (!hasToken && !isPublicRoute) {
      return AppRoutes.signUpLoginScreen;
    }

    if (hasToken && isPublicRoute) {
      return AppRoutes.homeScreen;
    }

    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.initial,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SignUpLoginScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.signUpLoginScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SignUpLoginScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
      ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppScaffold(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.homeScreen,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: HomeScreen()),
            ),
          ],
        ),

        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.digitalMembershipCardScreen,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: DigitalMembershipCardScreen()),
            ),
          ],
        ),

        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.accessLogScreen,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: AccessLogScreen()),
            ),
          ],
        ),

        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.adminUsersScreen,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: AdminUsersScreen()),
              routes: [
                GoRoute(
                  path: ':id',
                  pageBuilder: (context, state) {
                    final userId = int.tryParse(
                      state.pathParameters['id'] ?? '',
                    );

                    if (userId == null || userId <= 0) {
                      return const NoTransitionPage(
                        child: AdminUsersScreen(),
                      );
                    }

                    return NoTransitionPage(
                      child: AdminUserDetailScreen(
                        userId: userId,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),

        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profileScreen,
              pageBuilder: (context, state) {
                final extra = state.extra;

                final openPhotoPicker = extra is Map<String, dynamic> &&
                    extra['openPhotoPicker'] == true;

                return NoTransitionPage(
                  child: ProfileScreen(
                    openPhotoPicker: openPhotoPicker,
                  ),
                );
              },
            ),
            GoRoute(
              path: AppRoutes.dependentsScreen,
              builder: (context, state) => const DependentsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

void configureSessionExpiredHandler() {
  ApiClient.instance.onSessionExpired = () {
    appRouter.go(AppRoutes.signUpLoginScreen);
  };
}