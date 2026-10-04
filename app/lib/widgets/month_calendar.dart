import 'package:flutter/material.dart';

import '../core/l10n/gen/app_localizations.dart';
import '../core/motion.dart';
import '../core/theme/tokens.dart';
import '../core/utils/dates.dart';

/// 格子构造器：`date` 是 `YYYY-MM-DD`，`inMonth` 表示是否属于当前显示的月份。
typedef DayCellBuilder = Widget Function(
  BuildContext context,
  String date,
  bool inMonth,
);

/// 月历：横向翻月（[PageView]）+ 6×7 网格，每格由 [cellBuilder] 决定外观。
/// 日历页与档案详情页的个人日历共用同一个实现。
class MonthCalendar extends StatefulWidget {
  const MonthCalendar({
    super.key,
    required this.initialMonth,
    required this.cellBuilder,
    this.onMonthChanged,
    this.showWeekdays = true,
  });

  /// 起始月份，`YYYY-MM`
  final String initialMonth;
  final DayCellBuilder cellBuilder;

  /// 翻月后回调（用于外部显示月份标题）
  final ValueChanged<String>? onMonthChanged;
  final bool showWeekdays;

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<MonthCalendar> {
  /// 前后各 100 年，够用且不用做边界处理。
  static const int _basePage = 1200;
  static const int _pageCount = 2401;

  late final PageController _controller;
  late final String _base;
  late String _month;
  int _page = _basePage;

  @override
  void initState() {
    super.initState();
    // 基准月份在 initState 里固定下来：外部把当前月份回传进来时不会把坐标系带偏。
    _base = widget.initialMonth;
    _month = widget.initialMonth;
    _controller = PageController(initialPage: _basePage);
  }

  @override
  void didUpdateWidget(MonthCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialMonth != oldWidget.initialMonth &&
        widget.initialMonth != _month) {
      _jumpTo(widget.initialMonth);
    }
  }

  /// 外部要求切换到某个月份（点击左右箭头之外的入口）。
  void _jumpTo(String monthKey) {
    final int target = _basePage + _monthsBetween(_base, monthKey);
    _page = target;
    if (_controller.hasClients) {
      _controller.jumpToPage(target);
    }
    setState(() => _month = monthKey);
  }

  static int _monthsBetween(String from, String to) {
    int index(String key) =>
        int.parse(key.substring(0, 4)) * 12 + int.parse(key.substring(5, 7));
    return index(to) - index(from);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _monthAt(int page) => LocalDate.addMonths(_base, page - _basePage);

  void _onPageChanged(int page) {
    final String month = _monthAt(page);
    setState(() {
      _page = page;
      _month = month;
    });
    widget.onMonthChanged?.call(month);
  }

  void _step(int delta) {
    Motion.tap();
    // 用自己的页码而不是 _controller.page：连点时动画还没结束，page 是小数，
    // 取整会前后漂移，翻月会跳。
    final int target = _page + delta;
    _controller.animateToPage(
      target,
      duration: Motion.medium,
      curve: Motion.spring,
    );
    _page = target;
    final String month = _monthAt(target);
    setState(() => _month = month);
    widget.onMonthChanged?.call(month);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppColors colors = context.colors;
    final int year = int.parse(_month.substring(0, 4));
    final int month = int.parse(_month.substring(5, 7));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton(
              onPressed: () => _step(-1),
              icon: const Icon(Icons.chevron_left),
              color: colors.textSecondary,
              tooltip: l10n.calendarPrevMonth,
            ),
            Expanded(
              child: Center(
                child: Text(
                  l10n.calendarMonthLabel(year, month),
                  style: AppType.title.copyWith(color: colors.text),
                ),
              ),
            ),
            IconButton(
              onPressed: () => _step(1),
              icon: const Icon(Icons.chevron_right),
              color: colors.textSecondary,
              tooltip: l10n.calendarNextMonth,
            ),
          ],
        ),
        if (widget.showWeekdays) ...<Widget>[
          const SizedBox(height: AppSpacing.x1),
          Row(
            children: <Widget>[
              for (final String label in <String>[
                l10n.weekdayMon,
                l10n.weekdayTue,
                l10n.weekdayWed,
                l10n.weekdayThu,
                l10n.weekdayFri,
                l10n.weekdaySat,
                l10n.weekdaySun,
              ])
                Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: AppType.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.x1),
        Expanded(
          child: PageView.builder(
            controller: _controller,
            itemCount: _pageCount,
            onPageChanged: _onPageChanged,
            itemBuilder: (BuildContext context, int page) => _MonthGrid(
              month: _monthAt(page),
              cellBuilder: widget.cellBuilder,
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.month, required this.cellBuilder});

  final String month;
  final DayCellBuilder cellBuilder;

  @override
  Widget build(BuildContext context) {
    final List<String> days = LocalDate.monthGrid(month);
    return Column(
      children: <Widget>[
        for (int row = 0; row < 6; row++)
          Expanded(
            child: Row(
              children: <Widget>[
                for (int column = 0; column < 7; column++)
                  Expanded(
                    child: RepaintBoundary(
                      child: cellBuilder(
                        context,
                        days[row * 7 + column],
                        days[row * 7 + column].startsWith(month),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
