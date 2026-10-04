import 'package:flutter_test/flutter_test.dart';
import 'package:moonletter/core/utils/dates.dart';

void main() {
  group('LocalDate 基础运算', () {
    test('解析、格式化与校验', () {
      expect(LocalDate.of(DateTime(2026, 10, 4)), '2026-10-04');
      expect(LocalDate.isValid('2026-10-04'), isTrue);
      expect(LocalDate.isValid('2026-02-30'), isFalse);
      expect(LocalDate.isValid('2026-13-01'), isFalse);
      expect(LocalDate.isValid('2026-11'), isFalse);
      expect(LocalDate.utcOf('2026-02-28').day, 28);
    });

    test('加减天数按日历计算，跨月跨年正确', () {
      expect(LocalDate.addDays('2026-01-31', 1), '2026-02-01');
      expect(LocalDate.addDays('2026-03-01', -1), '2026-02-28');
      expect(LocalDate.addDays('2026-12-31', 1), '2027-01-01');
      expect(LocalDate.addDays('2026-10-01', 28), '2026-10-29');
    });

    test('间隔天数', () {
      expect(LocalDate.diffDays('2026-10-01', '2026-10-04'), 3);
      expect(LocalDate.diffDays('2026-09-03', '2026-10-01'), 28);
      expect(LocalDate.diffDays('2026-10-04', '2026-10-01'), -3);
    });

    test('星期：1 = 周一', () {
      expect(LocalDate.weekday('2026-10-05'), 1);
      expect(LocalDate.weekday('2026-10-04'), 7);
    });
  });

  group('月份工具', () {
    test('monthKey / firstOfMonth / lastOfMonth', () {
      expect(LocalDate.monthKey('2026-10-04'), '2026-10');
      expect(LocalDate.firstOfMonth('2026-10'), '2026-10-01');
      expect(LocalDate.lastOfMonth('2026-10'), '2026-10-31');
      expect(LocalDate.lastOfMonth('2026-02'), '2026-02-28');
      expect(LocalDate.lastOfMonth('2028-02'), '2028-02-29');
    });

    test('addMonths 跨年与负值', () {
      expect(LocalDate.addMonths('2026-10', 1), '2026-11');
      expect(LocalDate.addMonths('2026-12', 1), '2027-01');
      expect(LocalDate.addMonths('2026-01', -1), '2025-12');
      expect(LocalDate.addMonths('2026-10', 3), '2027-01');
    });

    test('monthGrid 是 42 天、周一开始、覆盖整月', () {
      final List<String> grid = LocalDate.monthGrid('2026-10');
      expect(grid, hasLength(42));
      expect(LocalDate.weekday(grid.first), 1, reason: '第一格必须是周一');
      expect(grid, contains('2026-10-01'));
      expect(grid, contains('2026-10-31'));
      final List<String> feb = LocalDate.monthGrid('2026-02');
      expect(feb, contains('2026-02-01'));
      expect(feb, contains('2026-02-28'));
      expect(LocalDate.weekday(feb.first), 1);
    });
  });

  group('Timestamps', () {
    test('往返转换', () {
      final int now = Timestamps.now();
      expect(Timestamps.toDateTime(now).millisecondsSinceEpoch, now);
    });
  });
}
