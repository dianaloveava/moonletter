import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/tokens.dart';
import '../data/data_providers.dart';
import '../data/db/database.dart';
import 'squircle.dart';

/// 昵称首字：中文取第一个字，英文取首字母大写。
String memberInitial(String name) {
  final String trimmed = name.trim();
  if (trimmed.isEmpty) {
    return '?';
  }
  final String first = String.fromCharCode(trimmed.runes.first);
  return RegExp(r'[A-Za-z]').hasMatch(first) ? first.toUpperCase() : first;
}

/// 成员头像：有照片显示照片，否则显示 `colorIndex` 底色的昵称首字。
class MemberAvatar extends ConsumerStatefulWidget {
  const MemberAvatar({super.key, required this.member, this.size = 40});

  final Member member;
  final double size;

  @override
  ConsumerState<MemberAvatar> createState() => _MemberAvatarState();
}

class _MemberAvatarState extends ConsumerState<MemberAvatar> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(MemberAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.member.avatarHash != widget.member.avatarHash) {
      _load();
    }
  }

  Future<void> _load() async {
    final String? hash = widget.member.avatarHash;
    if (hash == null) {
      if (_bytes != null) {
        setState(() => _bytes = null);
      }
      return;
    }
    final Uint8List? bytes = await ref.read(avatarStoreProvider).read(hash);
    if (!mounted || widget.member.avatarHash != hash) {
      return;
    }
    setState(() => _bytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    final double size = widget.size;
    final Uint8List? bytes = _bytes;
    final Color background =
        kDefaultAvatarColors[widget.member.colorIndex %
            kDefaultAvatarColors.length];

    return SizedBox(
      width: size,
      height: size,
      child: ClipPath(
        clipper: SquircleClipper(radius: size / 2),
        child: bytes != null
            ? Image.memory(
                bytes,
                width: size,
                height: size,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
              )
            : ColoredBox(
                color: background,
                child: Center(
                  child: Text(
                    memberInitial(widget.member.name),
                    style: TextStyle(
                      fontFamily: AppFonts.family,
                      fontFamilyFallback: AppFonts.fallback,
                      fontSize: size * 0.42,
                      height: 1,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
