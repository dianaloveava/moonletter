import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:moonletter/core/app_paths.dart';
import 'package:moonletter/data/data_providers.dart';
import 'package:moonletter/data/db/database.dart';
import 'package:moonletter/data/media/avatar_store.dart';
import 'package:moonletter/widgets/member_avatar.dart';

Member _member({String? avatarHash, String name = '小月'}) => Member(
  id: 'm1',
  name: name,
  avatarHash: avatarHash,
  colorIndex: 2,
  sortOrder: 0,
  createdAt: 1,
  updatedAt: 1,
  updatedBy: 'test',
);

Uint8List _pngBytes({int size = 8}) {
  final img.Image image = img.Image(width: size, height: size);
  img.fill(image, color: img.ColorRgb8(200, 80, 120));
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  late Directory dir;
  late AppPaths paths;
  late AvatarStore store;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('moonletter-avatar-test');
    paths = AppPaths.forTesting(dir);
    store = AvatarStore(paths);
  });

  tearDown(() {
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  test('saveFromImage 落盘为内容寻址 PNG，重复内容只存一份', () async {
    final Uint8List source = _pngBytes();
    final String hash = await store.saveFromImage(source);
    expect(hash, hasLength(64));

    final File file = paths.avatarFile(hash);
    expect(file.existsSync(), isTrue);
    expect(file.path.endsWith('$hash.png'), isTrue);

    final Uint8List? stored = await store.read(hash);
    expect(stored, isNotNull);
    expect(img.decodePng(stored!), isNotNull, reason: '存的是可解码的 PNG');

    // 同一张图再存一次不会产生第二个文件
    final String again = await store.saveFromImage(source);
    expect(again, hash);
    expect(paths.avatarsDir.listSync().length, 1);
  });

  test('saveFromImage 会把过大的图片缩到 512', () async {
    final img.Image large = img.Image(width: 1200, height: 600);
    img.fill(large, color: img.ColorRgb8(10, 120, 200));
    final String hash = await store.saveFromImage(
      Uint8List.fromList(img.encodePng(large)),
    );
    final img.Image? decoded = img.decodePng((await store.read(hash))!);
    expect(decoded!.width, 512);
    expect(decoded.height, 256);
  });

  testWidgets('有头像 hash 时渲染图片，没有时渲染昵称首字', (WidgetTester tester) async {
    // 文件读写与图片解码要放在 runAsync 里，testWidgets 的假时钟不会推进真实 I/O。
    final String hash =
        await tester.runAsync(() => store.save(_pngBytes())) ?? '';
    expect(hash, hasLength(64));

    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appPathsProvider.overrideWithValue(paths)],
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: <Widget>[
                  MemberAvatar(member: _member(avatarHash: hash), size: 40),
                  MemberAvatar(member: _member(name: 'Moon'), size: 40),
                ],
              ),
            ),
          ),
        ),
      );
      // 给头像文件的真实读取留出时间
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();

    expect(find.byType(Image), findsOneWidget, reason: '有 hash 的显示图片');
    expect(find.text('M'), findsOneWidget, reason: '没有 hash 的显示首字母');
  });
}
