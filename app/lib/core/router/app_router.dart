import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/calendar/calendar_page.dart';
import '../../features/lock/lock_settings_page.dart';
import '../../features/profiles/member_detail_page.dart';
import '../../features/profiles/profiles_page.dart';
import '../../features/settings/data_settings_page.dart';
import '../../features/settings/notification_settings_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/shell/adaptive_shell.dart';
import '../../features/sync/sync_settings_page.dart';

/// 应用路由。三个分支共用一套壳，宽屏时由 [AdaptiveShell] 换成左侧边栏。
final routerProvider = Provider<GoRouter>((Ref ref) {
  return GoRouter(
    initialLocation: '/calendar',
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder: (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell navigationShell,
        ) => AdaptiveShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/calendar',
                builder: (BuildContext context, GoRouterState state) =>
                    const CalendarPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/profiles',
                builder: (BuildContext context, GoRouterState state) =>
                    const ProfilesPage(),
                routes: <RouteBase>[
                  GoRoute(
                    path: ':id',
                    builder: (BuildContext context, GoRouterState state) =>
                        MemberDetailPage(memberId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/settings',
                builder: (BuildContext context, GoRouterState state) =>
                    const SettingsPage(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'notifications',
                    builder: (BuildContext context, GoRouterState state) =>
                        const NotificationSettingsPage(),
                  ),
                  GoRoute(
                    path: 'lock',
                    builder: (BuildContext context, GoRouterState state) =>
                        const LockSettingsPage(),
                  ),
                  GoRoute(
                    path: 'data',
                    builder: (BuildContext context, GoRouterState state) =>
                        const DataSettingsPage(),
                  ),
                  GoRoute(
                    path: 'sync',
                    builder: (BuildContext context, GoRouterState state) =>
                        const SyncSettingsPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
