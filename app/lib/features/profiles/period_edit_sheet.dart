import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/dates.dart';
import '../../data/data_providers.dart';
import '../../data/db/database.dart';
import '../../widgets/bottom_sheet_scaffold.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/squircle.dart';

/// 打开「添加经期 / 编辑经期」底部弹层。
Future<void> showPeriodEditor({
  required BuildContext context,
  required String memberId,
  Period? period,
}) {
  return showAppSheet(
    context: context,
    title: period == null
        ? AppLocalizations.of(context).periodAddTitle
        : AppLocalizations.of(context).periodEditTitle,
    child: PeriodEditSheet(memberId: memberId, period: period),
  );
}

class PeriodEditSheet extends ConsumerStatefulWidget {
  const PeriodEditSheet({super.key, required this.memberId, this.period});

  final String memberId;
  final Period? period;

  @override
  ConsumerState<PeriodEditSheet> createState() => _PeriodEditSheetState();
}

class _PeriodEditSheetState extends ConsumerState<PeriodEditSheet> {
  String? _start;
  String? _end;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _start = widget.period?.startDate;
    _end = widget.period?.endDate;
  }

  Future<void> _pickDate({
    required String? current,
    required ValueChanged<String> onPicked,
  }) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: current != null ? LocalDate.utcOf(current).toLocal() : now,
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (picked != null) {
      onPicked(LocalDate.of(picked));
    }
  }

  Future<void> _save() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String? start = _start;
    if (start == null) {
      setState(() => _error = l10n.periodStartRequired);
      return;
    }
    final String? end = _end;
    if (end != null && LocalDate.isBefore(end, start)) {
      setState(() => _error = l10n.periodEndBeforeStart);
      return;
    }

    setState(() {
      _error = null;
      _saving = true;
    });

    try {
      final periodRepo = ref.read(periodRepositoryProvider);
      final Period? existing = widget.period;
      if (existing == null) {
        await periodRepo.add(widget.memberId, start, endDate: end);
      } else {
        if (existing.startDate != start) {
          await periodRepo.setStart(existing.id, start);
        }
        if (existing.endDate != end) {
          await periodRepo.setEnd(existing.id, end);
        }
      }
      if (mounted) {
        Navigator.of(context).maybePop();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '$error';
        });
      }
    }
  }

  Future<void> _delete() async {
    final Period? existing = widget.period;
    if (existing == null) {
      return;
    }
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool confirmed = await showConfirmDialog(
      context: context,
      title: l10n.commonDelete,
      message: l10n.memberDeleteMessage,
    );
    if (!confirmed) {
      return;
    }
    await ref.read(periodRepositoryProvider).delete(existing.id);
    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppColors colors = context.colors;
    final String? error = _error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _Field(
          label: l10n.periodStartLabel,
          child: _DateBox(
            value: _start,
            placeholder: l10n.periodStartLabel,
            onTap: () => _pickDate(
              current: _start,
              onPicked: (String value) => setState(() => _start = value),
            ),
          ),
        ),
        _Field(
          label: l10n.periodEndLabel,
          child: Row(
            children: <Widget>[
              Expanded(
                child: _DateBox(
                  value: _end,
                  placeholder: l10n.periodEndLabel,
                  onTap: () => _pickDate(
                    current: _end,
                    onPicked: (String value) => setState(() => _end = value),
                  ),
                ),
              ),
              if (_end != null)
                IconButton(
                  onPressed: () => setState(() => _end = null),
                  icon: Icon(
                    Icons.close,
                    size: 18,
                    color: colors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        if (error != null) ...<Widget>[
          Text(
            error,
            style: AppType.bodySmall.copyWith(color: colors.periodRed),
          ),
          const SizedBox(height: AppSpacing.x2),
        ],
        FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: colors.accent,
            foregroundColor: colors.onAccent,
            minimumSize: const Size.fromHeight(48),
            shape: const SquircleBorder(radius: AppRadii.control),
          ),
          child: Text(l10n.commonSave),
        ),
        if (widget.period != null) ...<Widget>[
          const SizedBox(height: AppSpacing.x2),
          TextButton(
            onPressed: _saving ? null : _delete,
            child: Text(
              l10n.commonDelete,
              style: TextStyle(color: colors.periodRed),
            ),
          ),
        ],
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.x1,
              bottom: AppSpacing.x1 / 2,
            ),
            child: Text(
              label,
              style: AppType.bodySmall.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  const _DateBox({
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return Semantics(
      container: true,
      button: true,
      excludeSemantics: true,
      onTap: onTap,
      label: '$placeholder ${value ?? ''}'.trim(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.control),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x2,
            vertical: 14,
          ),
          decoration: ShapeDecoration(
            color: colors.surfaceAlt,
            shape: const SquircleBorder(radius: AppRadii.control),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  value ?? placeholder,
                  style: AppType.body.copyWith(
                    color: value == null ? colors.textSecondary : colors.text,
                  ),
                ),
              ),
              Icon(Icons.event, size: 18, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
