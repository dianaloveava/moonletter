import '../../domain/prediction/cycle_predictor.dart';
import '../../domain/prediction/member_status.dart';
import 'gen/app_localizations.dart';

/// 状态行文案：经期第 N 天 / 距下次 N 天 / 已推迟 N 天 / 还没有记录。
String memberStatusLabel(AppLocalizations l10n, MemberStatus status) =>
    switch (status.kind) {
      MemberStatusKind.noRecords => l10n.memberStatusNoRecords,
      MemberStatusKind.period => l10n.memberStatusPeriod(status.days),
      MemberStatusKind.upcoming => l10n.memberStatusUpcoming(status.days),
      MemberStatusKind.late => l10n.memberStatusLate(status.days),
    };

/// 单日状态文案（个人日历与无障碍标签用）。
String dayKindLabel(AppLocalizations l10n, DayKind kind) => switch (kind) {
  DayKind.period => l10n.dayKindPeriod,
  DayKind.predictedPeriod => l10n.dayKindPredicted,
  DayKind.ovulation => l10n.dayKindOvulation,
  DayKind.fertile => l10n.dayKindFertile,
  DayKind.safe => l10n.dayKindSafe,
  DayKind.unknown => l10n.dayKindUnknown,
};
