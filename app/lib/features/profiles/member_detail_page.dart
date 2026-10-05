import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../core/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/dates.dart';
import '../../data/data_providers.dart';
import '../../data/db/database.dart';
import '../../domain/prediction/cycle_predictor.dart';
import '../../domain/prediction/member_status.dart';
import '../../domain/prediction/prediction_config.dart';
import '../../domain/prediction/prediction_providers.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/day_cell.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/grouped_list.dart';
import '../../widgets/member_avatar.dart';
import '../../widgets/month_calendar.dart';
import '../../widgets/squircle.dart';
import 'member_edit_sheet.dart';
import 'period_edit_sheet.dart';
import '../../core/l10n/labels.dart';

/// 成员详情：信息卡 + 周期预测 + 经期记录 + 个人日历。
class MemberDetailPage extends ConsumerWidget {
  const MemberDetailPage({super.key, required this.memberId});

  final String memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppColors colors = context.colors;

    final List<Member> members = switch (ref.watch(membersProvider)) {
      AsyncData<List<Member>>(value: final List<Member> v) => v,
      _ => const <Member>[],
    };
    Member? member;
    for (final Member candidate in members) {
      if (candidate.id == memberId) {
        member = candidate;
        break;
      }
    }

    if (member == null) {
      return SafeArea(
        child: Column(
          children: <Widget>[
            _Header(title: '', onBack: () => context.go('/profiles')),
            Expanded(child: EmptyState(message: l10n.profilesEmpty)),
          ],
        ),
      );
    }

    final Member current = member;
    final List<Period> periods = switch (ref.watch(periodsByMemberProvider)) {
      AsyncData<Map<String, List<Period>>>(
        value: final Map<String, List<Period>> v,
      ) =>
        v[memberId] ?? const <Period>[],
      _ => const <Period>[],
    };
    final PredictionConfig config = ref.watch(predictionConfigProvider);
    final Prediction? prediction = ref.watch(predictionsProvider)[memberId];
    final MemberStatus status = memberStatus(current, periods, config);

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Header(
            title: current.name,
            onBack: () => context.go('/profiles'),
            actions: <Widget>[
              IconButton(
                onPressed: () =>
                    showMemberEditor(context: context, member: current),
                icon: const Icon(Icons.edit_outlined),
                color: colors.accent,
                tooltip: l10n.memberEditTitle,
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.pageMobile,
                0,
                AppSpacing.pageMobile,
                AppSpacing.x4 + MediaQuery.paddingOf(context).bottom,
              ),
              children: <Widget>[
                _IdentityCard(member: current, status: status),
                const SizedBox(height: AppSpacing.groupGap),
                GroupedList(
                  sections: <Widget>[
                    _basicSection(l10n, colors, current),
                    _cycleSection(l10n, colors, current, prediction),
                    _reminderSection(l10n, colors, current),
                    _recordsSection(context, l10n, colors, current, periods),
                  ],
                ),
                const SizedBox(height: AppSpacing.groupGap),
                Text(
                  l10n.memberDetailCalendar,
                  style: AppType.caption.copyWith(color: colors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.x1),
                Container(
                  height: 360,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.x1,
                    vertical: AppSpacing.x1,
                  ),
                  decoration: ShapeDecoration(
                    color: colors.surface,
                    shape: SquircleBorder(
                      radius: AppRadii.card,
                      side: BorderSide(color: colors.separator, width: 0.5),
                    ),
                  ),
                  child: MonthCalendar(
                    initialMonth: LocalDate.monthKey(LocalDate.today()),
                    cellBuilder:
                        (BuildContext context, String date, bool inMonth) {
                          final DayKind kind = dayKind(
                            date,
                            periods,
                            prediction,
                          );
                          return PersonalDayCell(
                            dayNumber: int.parse(date.substring(8, 10)),
                            kind: kind,
                            inMonth: inMonth,
                            isToday: date == LocalDate.today(),
                            isSelected: false,
                            label:
                                '${date.substring(5).replaceAll('-', '/')} '
                                '${dayKindLabel(l10n, kind)}',
                          );
                        },
                  ),
                ),
                const SizedBox(height: AppSpacing.groupGap),
                TextButton(
                  onPressed: () async {
                    final bool confirmed = await showConfirmDialog(
                      context: context,
                      title: l10n.memberDeleteTitle,
                      message: l10n.memberDeleteMessage,
                    );
                    if (!confirmed) {
                      return;
                    }
                    Motion.impact();
                    await ref.read(memberRepositoryProvider).delete(current.id);
                    if (context.mounted) {
                      context.go('/profiles');
                    }
                  },
                  child: Text(
                    l10n.memberDeleteTitle,
                    style: TextStyle(color: colors.periodRed),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _basicSection(
    AppLocalizations l10n,
    AppColors colors,
    Member member,
  ) => GroupSection(
    title: l10n.memberDetailInfo,
    rows: <Widget>[
      GroupRow(
        label: l10n.memberAge,
        value: member.age == null ? '—' : '${member.age}',
      ),
      GroupRow(
        label: '${l10n.memberHeight}（${l10n.unitCm}）',
        value: member.heightCm == null
            ? '—'
            : member.heightCm!.toStringAsFixed(1),
      ),
      GroupRow(
        label: '${l10n.memberWeight}（${l10n.unitKg}）',
        value: member.weightKg == null
            ? '—'
            : member.weightKg!.toStringAsFixed(1),
      ),
      GroupRow(label: l10n.memberNote, value: member.note ?? '—'),
    ],
  );

  Widget _cycleSection(
    AppLocalizations l10n,
    AppColors colors,
    Member member,
    Prediction? prediction,
  ) {
    final CycleStats? stats = prediction?.stats;
    final String cycleValue = stats == null
        ? (member.defaultCycleDays?.toString() ?? '—')
        : l10n.unitDay(stats.cycleDays);
    final String periodValue = stats == null
        ? (member.defaultPeriodDays?.toString() ?? '—')
        : l10n.unitDay(stats.periodDays);
    final String lastStart = prediction == null
        ? '—'
        : LocalDate.addDays(prediction.nextStart, -stats!.cycleDays);

    return GroupSection(
      title: l10n.memberDetailCycle,
      rows: <Widget>[
        GroupRow(label: l10n.memberCycleDays, value: cycleValue),
        GroupRow(label: l10n.memberPeriodDays, value: periodValue),
        GroupRow(label: l10n.memberLastStart, value: lastStart),
        GroupRow(
          label: l10n.memberDetailPredictNext,
          value: prediction?.nextStart ?? '—',
        ),
        GroupRow(
          label: l10n.memberDetailPredictOvulation,
          value: prediction?.ovulation ?? '—',
        ),
        GroupRow(
          label: l10n.memberDetailPredictFertile,
          value: prediction == null
              ? '—'
              : '${prediction.fertileFrom} ~ ${prediction.fertileTo}',
        ),
      ],
    );
  }

  Widget _reminderSection(
    AppLocalizations l10n,
    AppColors colors,
    Member member,
  ) => GroupSection(
    title: l10n.memberDetailReminder,
    rows: <Widget>[
      GroupRow(
        label: l10n.memberReminderLead,
        value:
            member.reminderLeadDays?.toString() ??
            l10n.memberReminderFollowGlobal,
      ),
    ],
  );

  Widget _recordsSection(
    BuildContext context,
    AppLocalizations l10n,
    AppColors colors,
    Member member,
    List<Period> periods,
  ) {
    final List<Period> sorted = <Period>[...periods]
      ..sort((Period a, Period b) => b.startDate.compareTo(a.startDate));
    return GroupSection(
      title: l10n.memberDetailRecords,
      rows: <Widget>[
        if (sorted.isEmpty)
          GroupRow(label: l10n.memberRecordsEmpty)
        else
          for (final Period period in sorted)
            GroupRow(
              label: period.startDate,
              value: period.endDate ?? l10n.periodOngoingLabel,
              onTap: () => showPeriodEditor(
                context: context,
                memberId: member.id,
                period: period,
              ),
            ),
        GroupRow(
          label: l10n.memberRecordsAdd,
          onTap: () => showPeriodEditor(context: context, memberId: member.id),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.onBack,
    this.actions = const <Widget>[],
  });

  final String title;
  final VoidCallback onBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x1,
        AppSpacing.x1,
        AppSpacing.x2,
        0,
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            color: colors.textSecondary,
          ),
          Expanded(
            child: Text(
              title,
              style: AppType.title.copyWith(color: colors.text),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.member, required this.status});

  final Member member;
  final MemberStatus status;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppColors colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x2),
      decoration: ShapeDecoration(
        color: colors.surface,
        shape: SquircleBorder(
          radius: AppRadii.card,
          side: BorderSide(color: colors.separator, width: 0.5),
        ),
      ),
      child: Row(
        children: <Widget>[
          MemberAvatar(member: member, size: 64),
          const SizedBox(width: AppSpacing.x2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  member.name,
                  style: AppType.title.copyWith(color: colors.text),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  memberStatusLabel(l10n, status),
                  style: AppType.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
