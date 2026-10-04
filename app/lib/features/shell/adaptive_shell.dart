import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../core/motion.dart';
import '../../core/theme/tokens.dart';
import '../../widgets/glass_bar.dart';

/// 三个分支的共用外壳：窄屏用底部导航，宽屏（≥ [AppSpacing.breakpoint]）换成左侧边栏。
class AdaptiveShell extends StatelessWidget {
  const AdaptiveShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth >= AppSpacing.breakpoint) {
          return Scaffold(
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _SideBar(navigationShell: navigationShell),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppSpacing.contentMaxWidth,
                      ),
                      child: navigationShell,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return Scaffold(
          extendBody: true,
          body: navigationShell,
          bottomNavigationBar: _BottomBar(navigationShell: navigationShell),
        );
      },
    );
  }
}

/// 分支索引 → 图标（未选中 / 选中）。
const List<(IconData, IconData)> _branchIcons = <(IconData, IconData)>[
  (Icons.calendar_month_outlined, Icons.calendar_month),
  (Icons.people_outline, Icons.people),
  (Icons.settings_outlined, Icons.settings),
];

List<String> _branchLabels(AppLocalizations l10n) => <String>[
  l10n.tabCalendar,
  l10n.tabProfiles,
  l10n.tabSettings,
];

void _goTo(StatefulNavigationShell shell, int index) {
  Motion.tap();
  shell.goBranch(index, initialLocation: index == shell.currentIndex);
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<String> labels = _branchLabels(l10n);
    return GlassBar(
      border: Border(
        top: BorderSide(color: context.colors.separator, width: 0.5),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: <Widget>[
              for (int i = 0; i < _branchIcons.length; i++)
                Expanded(
                  child: _NavButton(
                    icon: _branchIcons[i].$1,
                    selectedIcon: _branchIcons[i].$2,
                    label: labels[i],
                    selected: navigationShell.currentIndex == i,
                    onTap: () => _goTo(navigationShell, i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideBar extends StatelessWidget {
  const _SideBar({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppColors colors = context.colors;
    final List<String> labels = _branchLabels(l10n);
    return SizedBox(
      width: 248,
      child: GlassBar(
        border: Border(right: BorderSide(color: colors.separator, width: 0.5)),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x3,
                  AppSpacing.x3,
                  AppSpacing.x3,
                  AppSpacing.x2,
                ),
                child: Text(
                  l10n.appTitle,
                  style: AppType.title.copyWith(color: colors.text),
                ),
              ),
              for (int i = 0; i < _branchIcons.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.x1,
                    vertical: 2,
                  ),
                  child: _NavButton(
                    icon: _branchIcons[i].$1,
                    selectedIcon: _branchIcons[i].$2,
                    label: labels[i],
                    selected: navigationShell.currentIndex == i,
                    horizontal: true,
                    onTap: () => _goTo(navigationShell, i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.horizontal = false,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final Color tint = selected ? colors.accent : colors.textSecondary;
    final Widget iconWidget = Icon(
      selected ? selectedIcon : icon,
      size: 24,
      color: tint,
    );
    final Widget labelWidget = Text(
      label,
      style: AppType.caption.copyWith(color: tint),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.control),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontal ? AppSpacing.x2 : 0,
            vertical: horizontal ? 10 : 6,
          ),
          child: horizontal
              ? Row(
                  children: <Widget>[
                    iconWidget,
                    const SizedBox(width: AppSpacing.x2),
                    Expanded(child: labelWidget),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    iconWidget,
                    const SizedBox(height: 2),
                    labelWidget,
                  ],
                ),
        ),
      ),
    );
  }
}
