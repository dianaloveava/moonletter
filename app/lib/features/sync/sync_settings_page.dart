import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../core/theme/tokens.dart';
import '../../data/data_providers.dart';
import '../../data/db/tables.dart';
import '../../data/secure/secure_store.dart';
import '../../domain/sync/sync_providers.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/grouped_list.dart';
import '../../widgets/page_frame.dart';
import '../../widgets/squircle.dart';

/// 云同步设置（§8）：后端、口令、手动同步与重置。
class SyncSettingsPage extends ConsumerStatefulWidget {
  const SyncSettingsPage({super.key});

  @override
  ConsumerState<SyncSettingsPage> createState() => _SyncSettingsPageState();
}

class _SyncSettingsPageState extends ConsumerState<SyncSettingsPage> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppColors colors = context.colors;
    final Map<String, String> settings = switch (ref.watch(settingsProvider)) {
      AsyncData<Map<String, String>>(value: final Map<String, String> v) => v,
      _ => const <String, String>{},
    };
    final SyncState sync = ref.watch(syncControllerProvider);
    final bool enabled =
        (settings[SettingKeys.syncEnabled] ?? 'false') == 'true';
    final bool relay =
        (settings[SettingKeys.syncBackend] ?? 'webdav') == 'relay';
    final String lastAt = settings[SettingKeys.syncLastAt] ?? '';

    return Scaffold(
      backgroundColor: colors.bg,
      body: PageFrame(
        title: l10n.syncTitle,
        actions: <Widget>[
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close),
            color: colors.textSecondary,
          ),
        ],
        child: ListView(
          padding: EdgeInsets.only(
            bottom: AppSpacing.x4 + MediaQuery.paddingOf(context).bottom,
          ),
          children: <Widget>[
            GroupedList(
              sections: <Widget>[
                GroupSection(
                  footer: l10n.syncPassphraseWarn,
                  rows: <Widget>[
                    GroupRow(
                      label: l10n.syncEnabled,
                      trailing: Switch(
                        value: enabled,
                        activeThumbColor: colors.accent,
                        onChanged: _busy ? null : _toggleEnabled,
                      ),
                    ),
                    if (enabled)
                      GroupRow(
                        label: l10n.syncBackend,
                        value: relay
                            ? l10n.syncBackendRelay
                            : l10n.syncBackendWebdav,
                        onTap: () => _pickBackend(relay),
                      ),
                    if (enabled && !relay) ...<Widget>[
                      GroupRow(
                        label: l10n.syncWebdavUrl,
                        value: _short(settings[SettingKeys.syncWebdavUrl]),
                        onTap: () => _editText(
                          key: SettingKeys.syncWebdavUrl,
                          title: l10n.syncWebdavUrl,
                        ),
                      ),
                      GroupRow(
                        label: l10n.syncWebdavUser,
                        value: _short(settings[SettingKeys.syncWebdavUser]),
                        onTap: () => _editText(
                          key: SettingKeys.syncWebdavUser,
                          title: l10n.syncWebdavUser,
                        ),
                      ),
                      GroupRow(
                        label: l10n.syncWebdavPassword,
                        value: '••••••',
                        onTap: _editPassword,
                      ),
                      GroupRow(
                        label: l10n.syncWebdavDir,
                        value:
                            settings[SettingKeys.syncWebdavDir] ?? 'moonletter',
                        onTap: () => _editText(
                          key: SettingKeys.syncWebdavDir,
                          title: l10n.syncWebdavDir,
                        ),
                      ),
                    ],
                    if (enabled && relay) ...<Widget>[
                      GroupRow(
                        label: l10n.syncRelayUrl,
                        value: _short(settings[SettingKeys.syncRelayUrl]),
                        onTap: () => _editText(
                          key: SettingKeys.syncRelayUrl,
                          title: l10n.syncRelayUrl,
                        ),
                      ),
                      GroupRow(
                        label: l10n.syncNamespace,
                        value: _short(settings[SettingKeys.syncNamespace]),
                        onTap: _editNamespace,
                      ),
                    ],
                  ],
                ),
                if (enabled) ...<Widget>[
                  GroupSection(
                    title: l10n.syncTitle,
                    rows: <Widget>[
                      GroupRow(
                        label: l10n.syncNow,
                        value: sync.running ? '…' : null,
                        onTap: _busy || sync.running ? null : _syncNow,
                      ),
                      GroupRow(
                        label: l10n.syncLastAt,
                        value: lastAt.isEmpty ? l10n.syncNever : lastAt,
                      ),
                      GroupRow(
                        label: l10n.syncReset,
                        destructive: true,
                        onTap: _busy ? null : _reset,
                      ),
                    ],
                  ),
                ],
              ],
            ),
            if (sync.error != null || sync.message != null) ...<Widget>[
              const SizedBox(height: AppSpacing.x2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x1),
                child: Text(
                  switch (sync.error) {
                    kSyncSetupRequired => l10n.syncSetupRequired,
                    kSyncPassphraseRequired => l10n.syncPassphraseNeeded,
                    _ => sync.error ?? sync.message ?? '',
                  },
                  style: AppType.caption.copyWith(
                    color: sync.error != null
                        ? colors.periodRed
                        : colors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String? _short(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final String trimmed = value.trim();
    return trimmed.length <= 24 ? trimmed : '${trimmed.substring(0, 22)}…';
  }

  Future<void> _toggleEnabled(bool value) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      if (value) {
        // 首次开启：显示一次性警告并设置口令。
        final bool confirmed = await showConfirmDialog(
          context: context,
          title: l10n.syncPassphraseWarn,
          message: l10n.syncPassphraseSet,
          confirmLabel: l10n.syncPassphraseSet,
        );
        if (!confirmed) {
          return;
        }
        final String? passphrase = await _askPassphrase();
        if (passphrase == null) {
          return;
        }
        final bool ready = await _ensureWebdavConfig();
        if (!ready) {
          return;
        }
        await ref
            .read(settingsRepositoryProvider)
            .setBool(SettingKeys.syncEnabled, true);
        await _syncNow(passphrase: passphrase);
        return;
      }
      await ref
          .read(settingsRepositoryProvider)
          .setBool(SettingKeys.syncEnabled, false);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  /// 索要口令，太短就带着提示重来（不是静默失败），用户取消才返回 null。
  Future<String?> _askPassphrase({String? errorText}) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String? value = await _askText(
      title: l10n.syncPassphrase,
      obscure: true,
      errorText: errorText,
    );
    if (value == null) {
      return null;
    }
    if (value.length < 8) {
      return _askPassphrase(errorText: l10n.syncPassphraseTooShort);
    }
    return value;
  }

  /// 开启同步前补齐 WebDAV 服务地址与密码：都是同步的必要信息，
  /// 缺一个就当场问，避免开完开关只能看到「请先填写同步信息」。
  Future<bool> _ensureWebdavConfig() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Map<String, String> settings = switch (ref.read(settingsProvider)) {
      AsyncData<Map<String, String>>(value: final Map<String, String> v) => v,
      _ => const <String, String>{},
    };
    if ((settings[SettingKeys.syncWebdavUrl] ?? '').trim().isEmpty) {
      final String? url = await _askText(title: l10n.syncWebdavUrl);
      if (url == null || url.trim().isEmpty) {
        return false;
      }
      await ref
          .read(settingsRepositoryProvider)
          .set(SettingKeys.syncWebdavUrl, url.trim());
    }
    final String? password = await ref
        .read(secureStoreProvider)
        .read(SecureStore.keyWebdavPassword);
    if (password == null || password.isEmpty) {
      final String? typed = await _askText(
        title: l10n.syncWebdavPassword,
        obscure: true,
      );
      if (typed == null || typed.isEmpty) {
        return false;
      }
      await ref
          .read(secureStoreProvider)
          .write(SecureStore.keyWebdavPassword, typed);
    }
    return true;
  }

  Future<void> _pickBackend(bool relay) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String? picked = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        final AppColors colors = sheetContext.colors;
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(AppSpacing.x2),
            decoration: ShapeDecoration(
              color: colors.surface,
              shape: const SquircleBorder(radius: AppRadii.card),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                GroupRow(
                  label: l10n.syncBackendWebdav,
                  value: relay ? null : '✓',
                  onTap: () => Navigator.of(sheetContext).pop('webdav'),
                ),
                GroupRow(
                  label: l10n.syncBackendRelay,
                  value: relay ? '✓' : null,
                  onTap: () => Navigator.of(sheetContext).pop('relay'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (picked != null) {
      await ref
          .read(settingsRepositoryProvider)
          .set(SettingKeys.syncBackend, picked);
    }
  }

  Future<void> _editText({required String key, required String title}) async {
    final Map<String, String> settings = switch (ref.read(settingsProvider)) {
      AsyncData<Map<String, String>>(value: final Map<String, String> v) => v,
      _ => const <String, String>{},
    };
    final String? value = await _askText(title: title, initial: settings[key]);
    if (value != null) {
      await ref.read(settingsRepositoryProvider).set(key, value.trim());
    }
  }

  Future<void> _editPassword() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String? value = await _askText(
      title: l10n.syncWebdavPassword,
      obscure: true,
    );
    if (value != null) {
      await ref
          .read(secureStoreProvider)
          .write(SecureStore.keyWebdavPassword, value);
    }
  }

  Future<void> _editNamespace() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String current = switch (ref.read(settingsProvider)) {
      AsyncData<Map<String, String>>(value: final Map<String, String> v) =>
        v[SettingKeys.syncNamespace] ?? '',
      _ => '',
    };
    if (current.isNotEmpty) {
      await _editText(
        key: SettingKeys.syncNamespace,
        title: l10n.syncNamespace,
      );
      return;
    }
    final String generated = _generateNamespace();
    final String? value = await _askText(
      title: l10n.syncNamespace,
      initial: generated,
    );
    if (value != null && value.trim().isNotEmpty) {
      await ref
          .read(settingsRepositoryProvider)
          .set(SettingKeys.syncNamespace, value.trim());
    }
  }

  /// 同步 ID：16 随机字节的 base32（小写，与中转服务的正则一致）。
  static String _generateNamespace() {
    const String alphabet = 'abcdefghijklmnopqrstuvwxyz234567';
    final Random random = Random.secure();
    return List<String>.generate(
      26,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
  }

  Future<void> _syncNow({String? passphrase}) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(syncControllerProvider.notifier)
          .syncNow(passphrase: passphrase);
      // 远端还是空的、本机又没记住主密钥时，引擎只会说要口令：当场问一次
      // 再重试，否则用户看不到任何能输入口令的地方。
      final bool needsPassphrase =
          ref.read(syncControllerProvider).error == kSyncPassphraseRequired;
      if (mounted && needsPassphrase) {
        final String? entered = await _askPassphrase();
        if (entered != null) {
          await ref
              .read(syncControllerProvider.notifier)
              .syncNow(passphrase: entered);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _reset() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool confirmed = await showConfirmDialog(
      context: context,
      title: l10n.syncReset,
      message: l10n.syncResetConfirm,
      confirmLabel: l10n.syncReset,
    );
    if (!confirmed) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(syncControllerProvider.notifier).resetRemote();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<String?> _askText({
    required String title,
    String? initial,
    bool obscure = false,
    String? errorText,
  }) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppColors colors = context.colors;
    final TextEditingController controller = TextEditingController(
      text: initial ?? '',
    );
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: colors.surface,
        shape: const SquircleBorder(radius: AppRadii.card),
        title: Text(
          title,
          style: AppType.headline.copyWith(color: colors.text),
        ),
        content: TextField(
          controller: controller,
          obscureText: obscure,
          autofocus: true,
          style: AppType.body.copyWith(color: colors.text),
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.surfaceAlt,
            border: const SquircleInputBorder(),
            errorText: errorText,
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(
              l10n.commonSave,
              style: TextStyle(color: colors.accent),
            ),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }
}
