import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/dates.dart';
import '../../data/data_providers.dart';
import '../../data/db/database.dart';

/// 某个月份（`yyyy-MM`）内有交集的未删除经期记录。
/// 日历页只订阅可见月份，避免整表刷新。
final periodsInMonthProvider = StreamProvider.family<List<Period>, String>((
  Ref ref,
  String monthKey,
) {
  final String from = LocalDate.firstOfMonth(monthKey);
  final String to = LocalDate.lastOfMonth(monthKey);
  return ref.watch(periodRepositoryProvider).watchOverlapping(from, to);
});
