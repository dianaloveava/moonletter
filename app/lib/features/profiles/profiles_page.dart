import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../core/motion.dart';
import '../../core/theme/tokens.dart';
import '../../data/data_providers.dart';
import '../../data/db/database.dart';
import '../../domain/prediction/member_status.dart';
import '../../domain/prediction/prediction_providers.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/member_avatar.dart';
import '../../widgets/page_frame.dart';
import '../../widgets/squircle.dart';
import 'member_edit_sheet.dart';
import '../../core/l10n/labels.dart';

/// 档案页：成员卡片列表 + 新增/编辑/左滑删除。
class ProfilesPage extends ConsumerWidget {
  const ProfilesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppColors colors = context.colors;
    final AsyncValue<List<Member>> membersAsync = ref.watch(membersProvider);
    final List<Member> members = switch (membersAsync) {
      AsyncData<List<Member>>(value: final List<Member> v) => v,
      _ => const <Member>[],
    };

    return PageFrame(
      title: l10n.tabProfiles,
      actions: <Widget>[
        if (members.isNotEmpty)
          IconButton(
            onPressed: () {
              Motion.tap();
              showMemberEditor(context: context);
            },
            icon: const Icon(Icons.add),
            color: colors.accent,
            tooltip: l10n.profilesAdd,
          ),
      ],
      child: switch (membersAsync) {
        AsyncData<List<Member>>(value: final List<Member> v) when v.isEmpty =>
          EmptyState(
            message: l10n.profilesEmpty,
            action: FilledButton(
              onPressed: () => showMemberEditor(context: context),
              style: FilledButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: colors.onAccent,
                shape: const SquircleBorder(radius: AppRadii.control),
              ),
              child: Text(l10n.profilesAdd),
            ),
          ),
        AsyncData<List<Member>>(value: final List<Member> v) =>
          ListView.separated(
            padding: const EdgeInsets.only(bottom: AppSpacing.x4),
            itemCount: v.length,
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(height: AppSpacing.x2),
            itemBuilder: (BuildContext context, int index) =>
                _MemberCard(member: v[index]),
          ),
        AsyncError<List<Member>>() => EmptyState(message: l10n.commonRetry),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _MemberCard extends ConsumerWidget {
  const _MemberCard({required this.member});

  final Member member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppColors colors = context.colors;
    final Map<String, List<Period>> grouped = switch (ref.watch(
      periodsByMemberProvider,
    )) {
      AsyncData<Map<String, List<Period>>>(
        value: final Map<String, List<Period>> v,
      ) =>
        v,
      _ => const <String, List<Period>>{},
    };
    final List<Period> periods = grouped[member.id] ?? const <Period>[];
    final MemberStatus status = memberStatus(
      member,
      periods,
      ref.watch(predictionConfigProvider),
    );

    return Dismissible(
      key: ValueKey<String>(member.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.x3),
        decoration: ShapeDecoration(
          color: colors.periodRed,
          shape: const SquircleBorder(radius: AppRadii.card),
        ),
        child: Text(
          l10n.commonDelete,
          style: AppType.body.copyWith(color: colors.onAccent),
        ),
      ),
      confirmDismiss: (DismissDirection direction) => showConfirmDialog(
        context: context,
        title: l10n.memberDeleteTitle,
        message: l10n.memberDeleteMessage,
      ),
      onDismissed: (DismissDirection direction) {
        Motion.impact();
        ref.read(memberRepositoryProvider).delete(member.id);
      },
      child: Semantics(
        container: true,
        button: true,
        excludeSemantics: true,
        onTap: () {
          Motion.tap();
          context.go('/profiles/${member.id}');
        },
        label: '${member.name}，${memberStatusLabel(l10n, status)}',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Motion.tap();
              context.go('/profiles/${member.id}');
            },
            borderRadius: BorderRadius.circular(AppRadii.card),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x2,
                vertical: AppSpacing.x2,
              ),
              decoration: ShapeDecoration(
                color: colors.surface,
                shape: SquircleBorder(
                  radius: AppRadii.card,
                  side: BorderSide(color: colors.separator, width: 0.5),
                ),
              ),
              child: Row(
                children: <Widget>[
                  MemberAvatar(member: member, size: 44),
                  const SizedBox(width: AppSpacing.x2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          member.name,
                          style: AppType.headline.copyWith(color: colors.text),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          memberStatusLabel(l10n, status),
                          style: AppType.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
