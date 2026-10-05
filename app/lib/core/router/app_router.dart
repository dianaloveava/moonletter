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
                    // 用 MaterialPage 而不是 builder：builder 生成的路由由
                    // go_router 自己接管过渡（零时长），吃不到主题里的
                    // pageTransitionsTheme，页面就会硬切。
                    pageBuilder: (BuildContext context, GoRouterState state) =>
                        MaterialPage<void>(
                          key: state.pageKey,
                          child: MemberDetailPage(
                            memberId: state.pathParameters['id']!,
                          ),
                        ),
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
                  // 同上：子页面走 MaterialPage，才会用主题里的页面过渡动画。
                  GoRoute(
                    path: 'notifications',
                    pageBuilder: (BuildContext context, GoRouterState state) =>
                        MaterialPage<void>(
                          key: state.pageKey,
                          child: const NotificationSettingsPage(),
                        ),
                  ),
                  GoRoute(
                    path: 'lock',
                    pageBuilder: (BuildContext context, GoRouterState state) =>
                        MaterialPage<void>(
                          key: state.pageKey,
                          child: const LockSettingsPage(),
                        ),
                  ),
                  GoRoute(
                    path: 'data',
                    pageBuilder: (BuildContext context, GoRouterState state) =>
                        MaterialPage<void>(
                          key: state.pageKey,
                          child: const DataSettingsPage(),
                        ),
                  ),
                  GoRoute(
                    path: 'sync',
                    pageBuilder: (BuildContext context, GoRouterState state) =>
                        MaterialPage<void>(
                          key: state.pageKey,
                          child: const SyncSettingsPage(),
                        ),
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
