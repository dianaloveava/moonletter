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

/// 推入的二级页面自带不透明底色：过渡期间上一个页面还在下面画着，底色透明
/// 就会透出旧页面（两个界面叠在一起）。底色用主题的页面背景色。
Widget _opaquePage(BuildContext context, Widget child) {
  return ColoredBox(
    color: Theme.of(context).scaffoldBackgroundColor,
    child: child,
  );
}

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
                          child: _opaquePage(
                            context,
                            MemberDetailPage(
                              memberId: state.pathParameters['id']!,
                            ),
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
                          child: _opaquePage(context, const NotificationSettingsPage()),
                        ),
                  ),
                  GoRoute(
                    path: 'lock',
                    pageBuilder: (BuildContext context, GoRouterState state) =>
                        MaterialPage<void>(
                          key: state.pageKey,
                          child: _opaquePage(context, const LockSettingsPage()),
                        ),
                  ),
                  GoRoute(
                    path: 'data',
                    pageBuilder: (BuildContext context, GoRouterState state) =>
                        MaterialPage<void>(
                          key: state.pageKey,
                          child: _opaquePage(context, const DataSettingsPage()),
                        ),
                  ),
                  GoRoute(
                    path: 'sync',
                    pageBuilder: (BuildContext context, GoRouterState state) =>
                        MaterialPage<void>(
                          key: state.pageKey,
                          child: _opaquePage(context, const SyncSettingsPage()),
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
