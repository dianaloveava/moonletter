import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/app_info.dart';

/// 检查到的可用更新。
class UpdateInfo {
  const UpdateInfo({required this.version, required this.url});

  final String version;
  final String url;
}

/// 通过 GitHub Releases 检查更新（首版只在有新版时打开下载页，不自动替换文件）。
Future<UpdateInfo?> checkForUpdate({required String currentVersion}) async {
  if (AppInfo.repoOwner == 'YOURNAME') {
    // 还没填真实仓库地址时不做网络请求。
    return null;
  }
  try {
    final http.Response response = await http.get(
      Uri.parse(AppInfo.releasesApiUrl),
      headers: const <String, String>{'Accept': 'application/vnd.github+json'},
    );
    if (response.statusCode != 200) {
      return null;
    }
    final Map<String, dynamic> json =
        jsonDecode(response.body) as Map<String, dynamic>;
    final String tag = (json['tag_name'] as String? ?? '').trim();
    final String version = tag.startsWith('v') ? tag.substring(1) : tag;
    if (version.isEmpty || !isNewerVersion(version, currentVersion)) {
      return null;
    }
    return UpdateInfo(
      version: version,
      url: (json['html_url'] as String?) ?? AppInfo.releasesPageUrl,
    );
  } catch (_) {
    // 网络不可用/被墙都不影响应用使用。
    return null;
  }
}

/// `a` 是否比 `b` 新（按 `1.2.3` 数字段比较，忽略 `+build`）。
bool isNewerVersion(String a, String b) {
  List<int> parse(String value) {
    final String core = value.split('+').first.split('-').first;
    return core
        .split('.')
        .map((String part) => int.tryParse(part) ?? 0)
        .toList(growable: false);
  }

  final List<int> left = parse(a);
  final List<int> right = parse(b);
  final int length = left.length > right.length ? left.length : right.length;
  for (int i = 0; i < length; i++) {
    final int l = i < left.length ? left[i] : 0;
    final int r = i < right.length ? right[i] : 0;
    if (l != r) {
      return l > r;
    }
  }
  return false;
}
