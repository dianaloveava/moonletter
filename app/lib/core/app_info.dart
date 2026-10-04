/// 应用级常量。仓库地址等占位值集中在此，便于替换。
abstract final class AppInfo {
  static const String nameZh = '月信';
  static const String nameEn = 'Moonletter';
  static const String displayName = '月信 · Moonletter';

  /// 占位：换成真实 owner 后同步更新 README。
  static const String repoOwner = 'YOURNAME';
  static const String repoName = 'moonletter';
  static const String repoUrl = 'https://github.com/$repoOwner/$repoName';
  static const String releasesApiUrl =
      'https://api.github.com/repos/$repoOwner/$repoName/releases/latest';
  static const String releasesPageUrl = '$repoUrl/releases/latest';
}
