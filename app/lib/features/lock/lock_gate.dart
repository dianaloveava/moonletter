import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../core/theme/tokens.dart';
import '../../domain/lock/lock_providers.dart';
import 'pin_pad.dart';

/// 应用锁门 + 隐私遮罩（§7）：
/// - 切到后台（inactive/paused/hidden）立刻盖一层不透明遮罩，挡住最近任务预览；
/// - 开启应用锁时回到前台要先解锁（`pin_bio` 会先尝试生物识别，失败回退 PIN）。
class LockGate extends ConsumerStatefulWidget {
  const LockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate> {
  late final AppLifecycleListener _lifecycle;
  bool _covered = false;
  String _pin = '';
  String? _error;
  bool _biometricPrompted = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onInactive: () => _setCovered(true),
      onHide: () => _setCovered(true),
      onPause: () => _setCovered(true),
      onRestart: () => _setCovered(false),
      onResume: _onResumed,
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _setCovered(bool value) {
    if (!mounted || _covered == value) {
      return;
    }
    setState(() => _covered = value);
  }

  void _onResumed() {
    _setCovered(false);
    final bool locked = ref.read(appLockProvider);
    if (locked) {
      // 回来时保持锁定，并重试一次生物识别
      _biometricPrompted = false;
      _maybeBiometric();
    } else {
      _maybeLockOnResume();
    }
  }

  /// 切后台时上锁：只有开了应用锁才会有实际效果。
  void _maybeLockOnResume() {
    ref.read(appLockProvider.notifier).lock();
    if (ref.read(appLockProvider)) {
      _maybeBiometric();
    }
  }

  Future<void> _maybeBiometric() async {
    if (_biometricPrompted || !mounted) {
      return;
    }
    final bool enabled = await ref
        .read(lockServiceProvider)
        .isBiometricEnabled();
    if (!enabled || !mounted) {
      return;
    }
    _biometricPrompted = true;
    await _authenticate();
  }

  Future<void> _authenticate() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    try {
      final bool ok = await LocalAuthentication().authenticate(
        localizedReason: l10n.lockUnlockTitle,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
      if (ok && mounted) {
        setState(() {
          _pin = '';
          _error = null;
        });
        ref.read(appLockProvider.notifier).unlock();
      }
    } catch (_) {
      // 生物识别不可用时静默回退到 PIN
    }
  }

  Future<void> _submitPin(String pin) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final service = ref.read(lockServiceProvider);
    final bool ok = await service.verifyPin(pin);
    if (!mounted) {
      return;
    }
    if (ok) {
      setState(() {
        _pin = '';
        _error = null;
      });
      ref.read(appLockProvider.notifier).unlock();
      return;
    }
    final Duration left = service.cooldownRemaining;
    setState(() {
      _pin = '';
      _error = left > Duration.zero
          ? l10n.lockCooldown(left.inSeconds)
          : l10n.lockWrongPin;
    });
  }

  void _onDigit(String digit) {
    if (_pin.length >= 6) {
      return;
    }
    setState(() {
      _pin += digit;
      _error = null;
    });
    if (_pin.length == 6) {
      final String submitted = _pin;
      // 等一帧，让第 6 个点先画出来
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _submitPin(submitted),
      );
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) {
      return;
    }
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final bool locked = ref.watch(appLockProvider);
    final bool biometricEnabled =
        ref.watch(biometricAvailableProvider).value ?? false;

    if (_covered) {
      return const _PrivacyCover();
    }
    if (!locked) {
      return widget.child;
    }

    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppColors colors = context.colors;
    // MaterialApp 的 builder 在 Navigator 之上，没有 Material 祖先，
    // 而数字键盘用的是 InkWell，所以这里补一层 Material。
    return Material(
      color: colors.bg,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.x3),
            child: PinEntry(
              value: _pin,
              title: l10n.lockEnterPin,
              error: _error,
              onDigit: _onDigit,
              onBackspace: _onBackspace,
              onBiometrics: biometricEnabled ? _authenticate : null,
              biometricSemanticLabel: l10n.lockUseBiometrics,
            ),
          ),
        ),
      ),
    );
  }
}

/// 切后台时的不透明遮罩：不显示任何记录内容。
class _PrivacyCover extends StatelessWidget {
  const _PrivacyCover();

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return Material(
      color: colors.bg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Image.asset('assets/icon/logo_512.png', width: 72, height: 72),
            const SizedBox(height: AppSpacing.x2),
            Text(
              AppLocalizations.of(context).lockLocked,
              style: AppType.body.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
