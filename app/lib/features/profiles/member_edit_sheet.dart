import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/dates.dart';
import '../../data/data_providers.dart';
import '../../data/db/database.dart';
import '../../data/repo/member_repository.dart';
import '../../widgets/bottom_sheet_scaffold.dart';
import '../../widgets/squircle.dart';

/// 打开「添加成员 / 编辑成员」底部弹层。
Future<void> showMemberEditor({required BuildContext context, Member? member}) {
  return showAppSheet(
    context: context,
    title: member == null
        ? AppLocalizations.of(context).memberAddTitle
        : AppLocalizations.of(context).memberEditTitle,
    child: MemberEditSheet(member: member),
  );
}

class MemberEditSheet extends ConsumerStatefulWidget {
  const MemberEditSheet({super.key, this.member});

  final Member? member;

  @override
  ConsumerState<MemberEditSheet> createState() => _MemberEditSheetState();
}

class _MemberEditSheetState extends ConsumerState<MemberEditSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  late final TextEditingController _note;
  late final TextEditingController _cycleDays;
  late final TextEditingController _periodDays;

  String? _avatarHash;
  String? _lastStart;
  int? _reminderLead;
  bool _saving = false;

  bool get _isEditing => widget.member != null;

  @override
  void initState() {
    super.initState();
    final Member? m = widget.member;
    _name = TextEditingController(text: m?.name ?? '');
    _age = TextEditingController(text: m?.age?.toString() ?? '');
    _height = TextEditingController(text: _decimalText(m?.heightCm));
    _weight = TextEditingController(text: _decimalText(m?.weightKg));
    _note = TextEditingController(text: m?.note ?? '');
    _cycleDays = TextEditingController(
      text: m?.defaultCycleDays?.toString() ?? '',
    );
    _periodDays = TextEditingController(
      text: m?.defaultPeriodDays?.toString() ?? '',
    );
    _avatarHash = m?.avatarHash;
    _reminderLead = m?.reminderLeadDays;
    if (m != null) {
      _loadLastStart(m.id);
    }
  }

  static String _decimalText(double? value) {
    if (value == null) {
      return '';
    }
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }

  Future<void> _loadLastStart(String memberId) async {
    final Period? latest = await ref
        .read(periodRepositoryProvider)
        .latestOf(memberId);
    if (!mounted || latest == null) {
      return;
    }
    setState(() => _lastStart = latest.startDate);
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    _note.dispose();
    _cycleDays.dispose();
    _periodDays.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final Uint8List? bytes = result?.files.single.bytes;
    if (bytes == null) {
      return;
    }
    try {
      final String hash = await ref
          .read(avatarStoreProvider)
          .saveFromImage(bytes);
      if (mounted) {
        setState(() => _avatarHash = hash);
      }
    } on FormatException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _pickDate({
    required String? current,
    required ValueChanged<String> onPicked,
    bool allowFuture = false,
  }) async {
    final DateTime now = DateTime.now();
    final DateTime initial = current != null
        ? LocalDate.utcOf(current).toLocal()
        : now;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 100),
      lastDate: allowFuture ? DateTime(now.year + 1) : now,
    );
    if (picked != null) {
      onPicked(LocalDate.of(picked));
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _saving = true);

    final int? age = _parseInt(_age.text);
    final double? height = _parseDouble(_height.text);
    final double? weight = _parseDouble(_weight.text);
    final int? cycleDays = _parseInt(_cycleDays.text);
    final int? periodDays = _parseInt(_periodDays.text);
    final String name = _name.text.trim();
    final String? note = _note.text.trim().isEmpty ? null : _note.text.trim();

    final MemberRepository repository = ref.read(memberRepositoryProvider);
    try {
      final String memberId;
      if (_isEditing) {
        memberId = widget.member!.id;
        await repository.update(
          memberId,
          MemberInput(
            name: name,
            age: age,
            heightCm: height,
            weightKg: weight,
            note: note,
            avatarHash: _avatarHash,
            colorIndex: widget.member!.colorIndex,
            defaultCycleDays: cycleDays,
            defaultPeriodDays: periodDays,
            reminderLeadDays: _reminderLead,
          ),
        );
      } else {
        final int colorIndex = ref.read(membersProvider).value?.length ?? 0;
        memberId = await repository.create(
          MemberInput(
            name: name,
            age: age,
            heightCm: height,
            weightKg: weight,
            note: note,
            avatarHash: _avatarHash,
            colorIndex: colorIndex % kDefaultAvatarColors.length,
            defaultCycleDays: cycleDays,
            defaultPeriodDays: periodDays,
            reminderLeadDays: _reminderLead,
          ),
        );
      }
      final String? lastStart = _lastStart;
      if (lastStart != null) {
        await ref
            .read(periodRepositoryProvider)
            .setLastStartDate(memberId, lastStart);
      }
      if (mounted) {
        Navigator.of(context).maybePop();
      }
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  static int? _parseInt(String value) =>
      value.trim().isEmpty ? null : int.tryParse(value.trim());

  static double? _parseDouble(String value) =>
      value.trim().isEmpty ? null : double.tryParse(value.trim());

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppColors colors = context.colors;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _AvatarPicker(
            hash: _avatarHash,
            name: _name.text,
            colorIndex: widget.member?.colorIndex ?? 0,
            onPick: _pickAvatar,
            onClear: () => setState(() => _avatarHash = null),
          ),
          const SizedBox(height: AppSpacing.x3),
          _SheetField(
            label: l10n.memberName,
            child: TextFormField(
              controller: _name,
              textInputAction: TextInputAction.next,
              decoration: _inputDecoration(colors),
              validator: (String? value) =>
                  (value ?? '').trim().isEmpty ? l10n.memberNameRequired : null,
              onChanged: (_) => setState(() {}),
            ),
          ),
          _SheetField(
            label: l10n.memberAge,
            child: TextFormField(
              controller: _age,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: _inputDecoration(colors),
              validator: (String? value) {
                final int? age = _parseInt(value ?? '');
                if (age != null && (age < 0 || age > 120)) {
                  return l10n.memberAgeRange;
                }
                return null;
              },
            ),
          ),
          _SheetField(
            label: '${l10n.memberHeight}（${l10n.unitCm}）',
            child: TextFormField(
              controller: _height,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: _inputDecoration(colors),
            ),
          ),
          _SheetField(
            label: '${l10n.memberWeight}（${l10n.unitKg}）',
            child: TextFormField(
              controller: _weight,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: _inputDecoration(colors),
            ),
          ),
          _SheetField(
            label: l10n.memberNote,
            child: TextFormField(
              controller: _note,
              maxLines: 3,
              decoration: _inputDecoration(colors),
            ),
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(
            l10n.memberDetailCycle,
            style: AppType.bodySmall.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.x1),
          _SheetField(
            label: l10n.memberCycleDays,
            child: TextFormField(
              controller: _cycleDays,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: _inputDecoration(colors),
              validator: (String? value) {
                final int? days = _parseInt(value ?? '');
                if (days != null && (days < 15 || days > 60)) {
                  return l10n.memberCycleRange;
                }
                return null;
              },
            ),
          ),
          _SheetField(
            label: l10n.memberPeriodDays,
            child: TextFormField(
              controller: _periodDays,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: _inputDecoration(colors),
              validator: (String? value) {
                final int? days = _parseInt(value ?? '');
                if (days != null && (days < 1 || days > 15)) {
                  return l10n.memberPeriodRange;
                }
                return null;
              },
            ),
          ),
          _SheetField(
            label: l10n.memberLastStart,
            child: _DateField(
              value: _lastStart,
              placeholder: l10n.memberLastStart,
              onTap: () => _pickDate(
                current: _lastStart,
                onPicked: (String value) => setState(() => _lastStart = value),
              ),
            ),
          ),
          _SheetField(
            label: l10n.memberReminderLead,
            child: DropdownButtonFormField<int?>(
              initialValue: _reminderLead,
              decoration: _inputDecoration(colors),
              dropdownColor: colors.surface,
              items: <DropdownMenuItem<int?>>[
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(l10n.memberReminderFollowGlobal),
                ),
                for (int days = 1; days <= 30; days++)
                  DropdownMenuItem<int?>(value: days, child: Text('$days')),
              ],
              onChanged: (int? value) => setState(() => _reminderLead = value),
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
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
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(AppColors colors) => InputDecoration(
    isDense: true,
    filled: true,
    fillColor: colors.surfaceAlt,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.x2,
      vertical: 12,
    ),
    border: const SquircleInputBorder(),
    enabledBorder: const SquircleInputBorder(),
    focusedBorder: SquircleInputBorder(
      borderSide: BorderSide(color: colors.accent, width: 1.5),
    ),
  );
}

class _SheetField extends StatelessWidget {
  const _SheetField({required this.label, required this.child});

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

class _DateField extends StatelessWidget {
  const _DateField({
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

class _AvatarPicker extends ConsumerWidget {
  const _AvatarPicker({
    required this.hash,
    required this.name,
    required this.colorIndex,
    required this.onPick,
    required this.onClear,
  });

  final String? hash;
  final String name;
  final int colorIndex;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppColors colors = context.colors;
    final String? avatarHash = hash;
    return Row(
      children: <Widget>[
        SizedBox(
          width: 64,
          height: 64,
          child: ClipPath(
            clipper: const SquircleClipper(radius: 32),
            child: avatarHash == null
                ? ColoredBox(
                    color:
                        kDefaultAvatarColors[colorIndex %
                            kDefaultAvatarColors.length],
                    child: Center(
                      child: Text(
                        name.trim().isEmpty
                            ? '?'
                            : String.fromCharCode(name.trim().runes.first),
                        style: AppType.title.copyWith(color: Colors.white),
                      ),
                    ),
                  )
                : FutureBuilder<Uint8List?>(
                    future: ref.read(avatarStoreProvider).read(avatarHash),
                    builder:
                        (
                          BuildContext context,
                          AsyncSnapshot<Uint8List?> snapshot,
                        ) => snapshot.hasData && snapshot.data != null
                        ? Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          )
                        : ColoredBox(color: colors.surfaceAlt),
                  ),
          ),
        ),
        const SizedBox(width: AppSpacing.x2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              OutlinedButton(
                onPressed: onPick,
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.accent,
                  side: BorderSide(color: colors.accent, width: 1),
                  shape: const SquircleBorder(radius: AppRadii.control),
                ),
                child: Text(l10n.memberAvatarPick),
              ),
              if (hash != null)
                TextButton(
                  onPressed: onClear,
                  child: Text(
                    l10n.memberAvatarClear,
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
