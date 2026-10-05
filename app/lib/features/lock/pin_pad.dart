import 'package:flutter/material.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../core/motion.dart';
import '../../core/theme/tokens.dart';
import '../../widgets/glass_bar.dart';
import '../../widgets/squircle.dart';

/// 已输入位数的圆点指示。
class PinDots extends StatelessWidget {
  const PinDots({super.key, required this.length, required this.filled});

  final int length;
  final int filled;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int i = 0; i < length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x1 / 2),
            child: AnimatedContainer(
              duration: Motion.fast,
              curve: Motion.spring,
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < filled ? colors.accent : Colors.transparent,
                border: Border.all(color: colors.separator, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}

/// 自绘数字键盘：0-9、退格，左下角可换成生物识别。
class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.onBiometrics,
    this.biometricSemanticLabel,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onBiometrics;
  final String? biometricSemanticLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final List<String> row in const <List<String>>[
          <String>['1', '2', '3'],
          <String>['4', '5', '6'],
          <String>['7', '8', '9'],
          <String>['bio', '0', 'del'],
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.x1 / 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (final String key in row)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.x1 / 2,
                    ),
                    child: _PadKey(
                      value: key,
                      onDigit: onDigit,
                      onBackspace: onBackspace,
                      onBiometrics: onBiometrics,
                      biometricSemanticLabel: biometricSemanticLabel,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PadKey extends StatelessWidget {
  const _PadKey({
    required this.value,
    required this.onDigit,
    required this.onBackspace,
    required this.onBiometrics,
    required this.biometricSemanticLabel,
  });

  final String value;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onBiometrics;
  final String? biometricSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    if (value == 'bio') {
      if (onBiometrics == null) {
        return const SizedBox(width: 72, height: 64);
      }
      return Semantics(
        container: true,
        button: true,
        excludeSemantics: true,
        label: biometricSemanticLabel,
        onTap: onBiometrics,
        child: InkWell(
          onTap: onBiometrics,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 72,
            height: 64,
            child: Icon(Icons.fingerprint, size: 26, color: colors.accent),
          ),
        ),
      );
    }

    final bool isDelete = value == 'del';
    return Semantics(
      container: true,
      button: true,
      excludeSemantics: true,
      label: isDelete
          ? AppLocalizations.of(context).commonDelete
          : value,
      onTap: isDelete ? onBackspace : () => onDigit(value),
      child: InkWell(
        onTap: isDelete ? onBackspace : () => onDigit(value),
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 72,
          height: 64,
          child: Center(
            child: isDelete
                ? Icon(
                    Icons.backspace_outlined,
                    size: 22,
                    color: colors.textSecondary,
                  )
                : Text(
                    value,
                    style: AppType.title.copyWith(color: colors.text),
                  ),
          ),
        ),
      ),
    );
  }
}

/// PIN 输入区域的容器（弹层与解锁页共用）。
class PinEntry extends StatelessWidget {
  const PinEntry({
    super.key,
    required this.value,
    required this.title,
    this.error,
    required this.onDigit,
    required this.onBackspace,
    this.onBiometrics,
    this.biometricSemanticLabel,
    this.footer,
  });

  final String value;
  final String title;
  final String? error;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onBiometrics;
  final String? biometricSemanticLabel;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(title, style: AppType.body.copyWith(color: colors.textSecondary)),
        const SizedBox(height: AppSpacing.x3),
        PinDots(length: 6, filled: value.length),
        SizedBox(
          height: 44,
          child: Center(
            child: error == null
                ? null
                : Text(
                    error!,
                    style: AppType.bodySmall.copyWith(color: colors.periodRed),
                  ),
          ),
        ),
        PinPad(
          onDigit: onDigit,
          onBackspace: onBackspace,
          onBiometrics: onBiometrics,
          biometricSemanticLabel: biometricSemanticLabel,
        ),
        if (footer != null) ...<Widget>[
          const SizedBox(height: AppSpacing.x2),
          footer!,
        ],
      ],
    );
  }
}

/// 弹层里的 PIN 设置流程（输两次）。
Future<String?> showPinSetupSheet({
  required BuildContext context,
  required String title,
  required String confirmTitle,
  required String mismatchMessage,
  required String cancelLabel,
}) async {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) => _PinSetupSheet(
      title: title,
      confirmTitle: confirmTitle,
      mismatchMessage: mismatchMessage,
      cancelLabel: cancelLabel,
    ),
  );
}

class _PinSetupSheet extends StatefulWidget {
  const _PinSetupSheet({
    required this.title,
    required this.confirmTitle,
    required this.mismatchMessage,
    required this.cancelLabel,
  });

  final String title;
  final String confirmTitle;
  final String mismatchMessage;
  final String cancelLabel;

  @override
  State<_PinSetupSheet> createState() => _PinSetupSheetState();
}

class _PinSetupSheetState extends State<_PinSetupSheet> {
  String _first = '';
  String _current = '';
  bool _confirming = false;
  String? _error;

  void _onDigit(String digit) {
    if (_current.length >= 6) {
      return;
    }
    setState(() {
      _current += digit;
      _error = null;
    });
    if (_current.length == 6) {
      _complete();
    }
  }

  void _onBackspace() {
    if (_current.isEmpty) {
      return;
    }
    setState(() => _current = _current.substring(0, _current.length - 1));
  }

  void _complete() {
    if (!_confirming) {
      setState(() {
        _first = _current;
        _current = '';
        _confirming = true;
      });
      return;
    }
    if (_current != _first) {
      setState(() {
        _current = '';
        _first = '';
        _confirming = false;
        _error = widget.mismatchMessage;
      });
      return;
    }
    Navigator.of(context).pop(_current);
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return GlassBar(
      shape: const TopSquircleBorder(),
      opacity: 0.94,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              PinEntry(
                value: _current,
                title: _confirming ? widget.confirmTitle : widget.title,
                error: _error,
                onDigit: _onDigit,
                onBackspace: _onBackspace,
                footer: TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text(
                    widget.cancelLabel,
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
