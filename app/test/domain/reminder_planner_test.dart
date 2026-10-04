import 'package:flutter_test/flutter_test.dart';
import 'package:moonletter/data/db/database.dart';
import 'package:moonletter/domain/prediction/prediction_config.dart';
import 'package:moonletter/domain/reminder/reminder_planner.dart';

Member _member({
  String id = 'm1',
  String name = '小月',
  int? reminderLeadDays,
  int? defaultCycleDays,
}) => Member(
  id: id,
  name: name,
  colorIndex: 0,
  defaultCycleDays: defaultCycleDays,
  reminderLeadDays: reminderLeadDays,
  sortOrder: 0,
  createdAt: 1,
  updatedAt: 1,
  updatedBy: 'test',
);

Period _period(String start, {String? end, String memberId = 'm1'}) => Period(
  id: 'p-$start-$memberId',
  memberId: memberId,
  startDate: start,
  endDate: end,
  createdAt: 1,
  updatedAt: 1,
  updatedBy: 'test',
);

const PredictionConfig _cfg = PredictionConfig();

void main() {
  test('触发时刻 = 下次开始日往前 lead 天的本地 09:00', () {
    final List<ReminderPlan> plans = planReminders(
      members: <Member>[_member(defaultCycleDays: 28)],
      periodsByMember: <String, List<Period>>{
        'm1': <Period>[_period('2026-10-01')],
      },
      config: _cfg,
      globalLeadDays: 3,
      now: DateTime(2026, 10, 4, 8),
      today: '2026-10-04',
    );

    expect(plans, hasLength(1));
    // nextStart = 2026-10-29，提前 3 天 = 10-26 09:00
    expect(plans.single.periodStart, '2026-10-29');
    expect(plans.single.fireAt, DateTime(2026, 10, 26, kReminderHour));
  });

  test('个人提前天数优先于全局', () {
    final DateTime now = DateTime(2026, 10, 4, 8);
    final Map<String, List<Period>> periods = <String, List<Period>>{
      'm1': <Period>[_period('2026-10-01')],
      'm2': <Period>[_period('2026-10-01', memberId: 'm2')],
    };

    final List<ReminderPlan> global = planReminders(
      members: <Member>[
        _member(defaultCycleDays: 28),
        _member(id: 'm2'),
      ],
      periodsByMember: periods,
      config: _cfg,
      globalLeadDays: 3,
      now: now,
      today: '2026-10-04',
    );
    expect(
      global.every((ReminderPlan p) {
        return p.fireAt == DateTime(2026, 10, 26, kReminderHour);
      }),
      isTrue,
    );

    final List<ReminderPlan> personal = planReminders(
      members: <Member>[_member(defaultCycleDays: 28, reminderLeadDays: 1)],
      periodsByMember: periods,
      config: _cfg,
      globalLeadDays: 3,
      now: now,
      today: '2026-10-04',
    );
    expect(personal.single.fireAt, DateTime(2026, 10, 28, kReminderHour));
  });

  test('已经过去的触发时刻不排期', () {
    final List<ReminderPlan> plans = planReminders(
      members: <Member>[_member(defaultCycleDays: 28)],
      periodsByMember: <String, List<Period>>{
        'm1': <Period>[_period('2026-10-01')],
      },
      config: _cfg,
      globalLeadDays: 3,
      // 触发时刻是 10-26 09:00，已经过去了
      now: DateTime(2026, 10, 26, 10),
      today: '2026-10-26',
    );
    expect(plans, isEmpty);
  });

  test('没有记录的成员不排期', () {
    final List<ReminderPlan> plans = planReminders(
      members: <Member>[_member()],
      periodsByMember: const <String, List<Period>>{},
      config: _cfg,
      globalLeadDays: 3,
      now: DateTime(2026, 10, 4, 8),
      today: '2026-10-04',
    );
    expect(plans, isEmpty);
  });

  test('notificationId 稳定且按成员区分', () {
    expect(fnv1a32('m1'), fnv1a32('m1'));
    expect(fnv1a32('m1'), isNot(fnv1a32('m2')));
    expect(fnv1a32('') & 0x7FFFFFFF, inInclusiveRange(0, 0x7FFFFFFF));

    final List<ReminderPlan> one = planReminders(
      members: <Member>[_member(defaultCycleDays: 28)],
      periodsByMember: <String, List<Period>>{
        'm1': <Period>[_period('2026-10-01')],
      },
      config: _cfg,
      globalLeadDays: 3,
      now: DateTime(2026, 10, 4, 8),
      today: '2026-10-04',
    );
    final List<ReminderPlan> two = planReminders(
      members: <Member>[_member(defaultCycleDays: 28)],
      periodsByMember: <String, List<Period>>{
        'm1': <Period>[_period('2026-10-01')],
      },
      config: _cfg,
      globalLeadDays: 5,
      now: DateTime(2026, 10, 4, 8),
      today: '2026-10-04',
    );
    expect(one.single.notificationId, two.single.notificationId);
  });

  test('多个成员按触发时间排序', () {
    final List<ReminderPlan> plans = planReminders(
      members: <Member>[
        _member(id: 'a', defaultCycleDays: 28, reminderLeadDays: 1),
        _member(id: 'b', defaultCycleDays: 28),
      ],
      periodsByMember: <String, List<Period>>{
        'a': <Period>[_period('2026-10-01', memberId: 'a')],
        'b': <Period>[_period('2026-10-01', memberId: 'b')],
      },
      config: _cfg,
      globalLeadDays: 3,
      now: DateTime(2026, 10, 4, 8),
      today: '2026-10-04',
    );
    expect(plans.map((ReminderPlan p) => p.memberId), <String>['b', 'a']);
  });

  group('missedReminders（Windows 启动补发）', () {
    List<ReminderPlan> missed(DateTime now) => missedReminders(
      members: <Member>[_member(defaultCycleDays: 28)],
      periodsByMember: <String, List<Period>>{
        'm1': <Period>[_period('2026-10-01')],
      },
      config: _cfg,
      globalLeadDays: 3,
      now: now,
      today: '2026-10-26',
    );

    test('6 小时窗口内补发一次', () {
      expect(missed(DateTime(2026, 10, 26, 9, 30)), hasLength(1));
      expect(missed(DateTime(2026, 10, 26, 14, 59)), hasLength(1));
    });

    test('超过 6 小时或还没到点都不补发', () {
      expect(missed(DateTime(2026, 10, 26, 15, 1)), isEmpty);
      expect(missed(DateTime(2026, 10, 26, 8, 0)), isEmpty);
    });
  });
}
