/// 本地民用日工具。应用内所有日期一律是 `YYYY-MM-DD` 字符串（本地日期，不做时区换算），
/// 时间戳一律是毫秒 epoch（UTC）。加减天数走 UTC 日历运算，不受夏令时影响。
abstract final class LocalDate {
  static final RegExp _pattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  /// 把 [dt] 的本地年月日格式化为 `YYYY-MM-DD`。
  static String of(DateTime dt) {
    final String y = dt.year.toString().padLeft(4, '0');
    final String m = dt.month.toString().padLeft(2, '0');
    final String d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String today() => of(DateTime.now());

  /// `YYYY-MM-DD` → 该日的 UTC 零点（仅用于日历运算与比较）。
  static DateTime utcOf(String date) {
    final Match? m = _pattern.firstMatch(date);
    if (m == null) {
      throw FormatException('无效日期：$date');
    }
    return DateTime.utc(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
    );
  }

  static bool isValid(String date) {
    final Match? m = _pattern.firstMatch(date);
    if (m == null) {
      return false;
    }
    final int year = int.parse(m.group(1)!);
    final int month = int.parse(m.group(2)!);
    final int day = int.parse(m.group(3)!);
    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return false;
    }
    final DateTime normalized = DateTime.utc(year, month, day);
    return normalized.year == year &&
        normalized.month == month &&
        normalized.day == day;
  }

  static String addDays(String date, int days) =>
      of(utcOf(date).add(Duration(days: days)));

  /// [to] - [from]，单位天。
  static int diffDays(String from, String to) =>
      utcOf(to).difference(utcOf(from)).inDays;

  /// 星期：1 = 周一 … 7 = 周日。
  static int weekday(String date) => utcOf(date).weekday;

  /// 年月：`2026-10`。
  static String monthKey(String date) => date.substring(0, 7);

  /// 该月第一天。
  static String firstOfMonth(String monthKey) => '$monthKey-01';

  /// 月份加减（[months] 可为负）。
  static String addMonths(String monthKey, int months) {
    final int year = int.parse(monthKey.substring(0, 4));
    final int month = int.parse(monthKey.substring(5, 7));
    final int total = year * 12 + (month - 1) + months;
    final int newYear = total ~/ 12;
    final int newMonth = total % 12 + 1;
    return '${newYear.toString().padLeft(4, '0')}-'
        '${newMonth.toString().padLeft(2, '0')}';
  }

  /// 该月最后一天。
  static String lastOfMonth(String monthKey) =>
      addDays(firstOfMonth(addMonths(monthKey, 1)), -1);

  /// 该月 6×7 网格的全部日期（周一开头，含相邻月的补位日）。
  static List<String> monthGrid(String monthKey) {
    final String first = firstOfMonth(monthKey);
    final String gridStart = addDays(first, -(weekday(first) - 1));
    return List<String>.generate(42, (int i) => addDays(gridStart, i));
  }

  static bool isAfter(String a, String b) => a.compareTo(b) > 0;
  static bool isBefore(String a, String b) => a.compareTo(b) < 0;

  static String min(String a, String b) => a.compareTo(b) <= 0 ? a : b;
  static String max(String a, String b) => a.compareTo(b) >= 0 ? a : b;
}

/// 时间戳工具。
abstract final class Timestamps {
  static int now() => DateTime.now().millisecondsSinceEpoch;

  static DateTime toDateTime(int millis) =>
      DateTime.fromMillisecondsSinceEpoch(millis);
}
