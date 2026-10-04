import 'package:flutter_test/flutter_test.dart';
import 'package:moonletter/data/db/database.dart';
import 'package:moonletter/domain/prediction/cycle_predictor.dart';
import 'package:moonletter/domain/prediction/prediction_config.dart';

Member _member({
  String id = 'm1',
  String name = '小月',
  int? defaultCycleDays,
  int? defaultPeriodDays,
}) => Member(
  id: id,
  name: name,
  colorIndex: 0,
  defaultCycleDays: defaultCycleDays,
  defaultPeriodDays: defaultPeriodDays,
  sortOrder: 0,
  createdAt: 1,
  updatedAt: 1,
  updatedBy: 'test',
);

Period _period(
  String start, {
  String? end,
  String id = 'p',
  int? deletedAt,
  String memberId = 'm1',
}) => Period(
  id: id,
  memberId: memberId,
  startDate: start,
  endDate: end,
  createdAt: 1,
  updatedAt: 1,
  updatedBy: 'test',
  deletedAt: deletedAt,
);

/// 从 [starts] 造一批记录，id 按序号生成。
List<Period> _periods(List<String> starts) => <Period>[
  for (int i = 0; i < starts.length; i++) _period(starts[i], id: 'p$i'),
];

const PredictionConfig _cfg = PredictionConfig();

void main() {
  group('computeStats', () {
    test('没有任何记录时全部走回退值', () {
      final CycleStats stats = computeStats(<Period>[], _member(), _cfg);
      expect(stats.cycleDays, 28);
      expect(stats.periodDays, 5);
      expect(stats.cycleFromRecords, isFalse);
      expect(stats.periodFromRecords, isFalse);
      expect(stats.recentCycles, isEmpty);
    });

    test('不足一个间隔时用档案值', () {
      final CycleStats stats = computeStats(
        _periods(<String>['2026-03-01']),
        _member(defaultCycleDays: 30, defaultPeriodDays: 6),
        _cfg,
      );
      expect(stats.cycleDays, 30);
      expect(stats.periodDays, 6);
      expect(stats.cycleFromRecords, isFalse);
      expect(stats.periodFromRecords, isFalse);
    });

    test('超过 window 条记录时只取最近 6 个间隔', () {
      // 间隔（升序）：28,29,30,31,27,26,25 → 最近 6 个 = 29..25，
      // 平均 = (29+30+31+27+26+25)/6 = 168/6 = 28
      final CycleStats stats = computeStats(
        _periods(<String>[
          '2026-01-01',
          '2026-01-29',
          '2026-02-27',
          '2026-03-29',
          '2026-04-29',
          '2026-05-26',
          '2026-06-21',
          '2026-07-16',
        ]),
        _member(),
        _cfg,
      );
      expect(stats.recentCycles, <int>[29, 30, 31, 27, 26, 25]);
      expect(stats.cycleDays, 28);
      expect(stats.cycleFromRecords, isTrue);
    });

    test('经期天数取已结束记录的平均值四舍五入', () {
      final CycleStats stats = computeStats(
        <Period>[
          _period('2026-01-01', end: '2026-01-05', id: 'p1'), // 5 天
          _period('2026-01-29', end: '2026-02-03', id: 'p2'), // 6 天
          _period('2026-02-26', id: 'p3'), // 进行中，不参与
        ],
        _member(),
        _cfg,
      );
      expect(stats.periodDays, 6); // (5+6)/2 = 5.5 → 6
      expect(stats.periodFromRecords, isTrue);
    });

    test('墓碑记录不参与统计', () {
      final List<Period> periods = _periods(<String>[
        '2026-01-01',
        '2026-01-29',
        '2026-03-01',
      ]);
      periods[1] = _period('2026-01-29', id: 'p1', deletedAt: 99);
      final CycleStats stats = computeStats(periods, _member(), _cfg);
      expect(stats.recentCycles, <int>[59]); // 01-01 → 03-01
    });

    test('window 由配置决定', () {
      final CycleStats stats = computeStats(
        _periods(<String>['2026-01-01', '2026-01-29', '2026-02-27']),
        _member(),
        const PredictionConfig(window: 1),
      );
      expect(stats.recentCycles, <int>[29]);
      expect(stats.cycleDays, 29);
    });
  });

  group('predict', () {
    test('没有记录时返回 null', () {
      expect(predict(_member(), <Period>[], _cfg), isNull);
    });

    test('一条记录 → 下一次开始日 = 最近开始 + 周期', () {
      final Prediction? p = predict(
        _member(defaultCycleDays: 30),
        _periods(<String>['2026-03-01']),
        _cfg,
        today: '2026-03-10',
      );
      expect(p!.nextStart, '2026-03-31');
      expect(p.stats.cycleFromRecords, isFalse);
      expect(p.ovulation, '2026-03-17'); // 03-31 - 14
      expect(p.fertileFrom, '2026-03-12'); // -5
      expect(p.fertileTo, '2026-03-21'); // +4
    });

    test('周期跨月按日历天数计算', () {
      final Prediction? p = predict(
        _member(defaultCycleDays: 30),
        _periods(<String>['2026-01-30']),
        _cfg,
        today: '2026-02-01',
      );
      expect(p!.nextStart, '2026-03-01'); // 2026-02 只有 28 天
    });

    test('预计开始日已过时按周期前推', () {
      final Prediction? p = predict(
        _member(defaultCycleDays: 28),
        _periods(<String>['2026-01-01']),
        _cfg,
        today: '2026-03-15',
      );
      // 01-29 → 02-26 → 03-26（> 03-15）
      expect(p!.nextStart, '2026-03-26');
    });

    test('今天正好是预计开始日时前推一个周期', () {
      final Prediction? p = predict(
        _member(defaultCycleDays: 28),
        _periods(<String>['2026-01-01']),
        _cfg,
        today: '2026-02-26',
      );
      expect(p!.nextStart, '2026-03-26');
    });

    test('有记录时用历史平均值而不是档案值', () {
      final Prediction? p = predict(
        _member(defaultCycleDays: 40),
        _periods(<String>['2026-01-01', '2026-01-31', '2026-03-02']),
        _cfg,
        today: '2026-03-05',
      );
      expect(p!.stats.cycleDays, 30); // (30+30)/2
      expect(p.stats.cycleFromRecords, isTrue);
      expect(p.nextStart, '2026-04-01');
    });
  });

  group('dayKind', () {
    // 最近一次开始 2026-03-01，周期回退 28 天 → nextStart 2026-03-29；
    // 排卵 03-15，危险期 03-10 ~ 03-19。
    late List<Period> periods;
    late Prediction prediction;

    setUp(() {
      periods = <Period>[
        _period('2026-02-01', end: '2026-02-05', id: 'p1'),
        _period('2026-03-01', end: '2026-03-05', id: 'p2'),
      ];
      prediction = predict(_member(), periods, _cfg, today: '2026-03-06')!;
    });

    test('实际经期命中（含结束日）', () {
      expect(dayKind('2026-03-01', periods, prediction), DayKind.period);
      expect(dayKind('2026-03-05', periods, prediction), DayKind.period);
      expect(dayKind('2026-03-06', periods, prediction), isNot(DayKind.period));
    });

    test('进行中的记录延伸到今天', () {
      final List<Period> ongoing = <Period>[_period('2026-03-04', id: 'p9')];
      final Prediction? p = predict(
        _member(),
        ongoing,
        _cfg,
        today: '2026-03-06',
      );
      expect(dayKind('2026-03-06', ongoing, p), DayKind.period);
      expect(
        dayKind('2026-03-06', ongoing, p, today: '2026-03-06'),
        DayKind.period,
      );
      expect(
        dayKind('2026-03-07', ongoing, p, today: '2026-03-06'),
        isNot(DayKind.period),
      );
    });

    test('预测经期窗口（下一次与再下一次）', () {
      expect(prediction.nextStart, '2026-03-29');
      expect(
        dayKind('2026-03-29', periods, prediction),
        DayKind.predictedPeriod,
      );
      expect(
        dayKind('2026-04-02', periods, prediction),
        DayKind.predictedPeriod,
      ); // nextStart + periodDays - 1
      expect(
        dayKind('2026-04-26', periods, prediction),
        DayKind.predictedPeriod,
      ); // 下一个周期 +28 天
    });

    test('排卵日与危险期边界（前 5 后 4）', () {
      expect(prediction.ovulation, '2026-03-15');
      expect(dayKind('2026-03-15', periods, prediction), DayKind.ovulation);
      expect(dayKind('2026-03-10', periods, prediction), DayKind.fertile);
      expect(dayKind('2026-03-19', periods, prediction), DayKind.fertile);
      expect(dayKind('2026-03-09', periods, prediction), DayKind.safe);
      expect(dayKind('2026-03-20', periods, prediction), DayKind.safe);
    });

    test('更远周期的危险期同样按周期前推', () {
      // 下下个周期的排卵日 = 2026-04-26 - 14 = 2026-04-12
      expect(dayKind('2026-04-12', periods, prediction), DayKind.ovulation);
      expect(dayKind('2026-04-07', periods, prediction), DayKind.fertile);
    });

    test('最早记录之前是 unknown，其余是 safe', () {
      expect(dayKind('2026-01-20', periods, prediction), DayKind.unknown);
      expect(dayKind('2026-02-20', periods, prediction), DayKind.safe);
    });

    test('没有记录时全部 unknown', () {
      expect(dayKind('2026-03-15', <Period>[], null), DayKind.unknown);
    });
  });

  group('periodDayIndex', () {
    late List<Period> periods;
    late Prediction prediction;

    setUp(() {
      periods = <Period>[
        _period('2026-09-03', end: '2026-09-07', id: 'p0'),
        _period('2026-10-01', end: '2026-10-04'),
      ];
      prediction = predict(_member(), periods, _cfg, today: '2026-10-04')!;
    });

    test('实际经期内的第几天', () {
      expect(periodDayIndex('2026-10-01', periods, prediction), 1);
      expect(periodDayIndex('2026-10-04', periods, prediction), 4);
      expect(periodDayIndex('2026-09-03', periods, prediction), 1);
      expect(periodDayIndex('2026-09-07', periods, prediction), 5);
    });

    test('预测经期窗口内的第几天', () {
      expect(prediction.nextStart, '2026-10-29');
      expect(periodDayIndex('2026-10-29', periods, prediction), 1);
      expect(periodDayIndex('2026-10-30', periods, prediction), 2);
      expect(periodDayIndex('2026-11-26', periods, prediction), 1);
    });

    test('不在经期窗口内返回 null', () {
      // 10-05 仍落在上个周期的预测窗口内（经期天数平均为 5，见 computeStats）
      expect(periodDayIndex('2026-10-05', periods, prediction), 5);
      expect(periodDayIndex('2026-10-06', periods, prediction), isNull);
      expect(periodDayIndex('2026-10-20', periods, prediction), isNull);
      expect(periodDayIndex('2026-09-01', periods, prediction), isNull);
    });

    test('进行中的记录延伸到今天', () {
      final List<Period> ongoing = <Period>[_period('2026-10-02', id: 'p9')];
      final Prediction? p = predict(
        _member(),
        ongoing,
        _cfg,
        today: '2026-10-04',
      );
      expect(periodDayIndex('2026-10-02', ongoing, p, today: '2026-10-04'), 1);
      expect(periodDayIndex('2026-10-04', ongoing, p, today: '2026-10-04'), 3);
      expect(
        periodDayIndex('2026-10-07', ongoing, p, today: '2026-10-04'),
        isNull,
      );
    });
  });
}
