# 月信 · Moonletter

多人经期记录应用。数据全部保存在本机 SQLite，离线可用；可选端到端加密同步
（WebDAV 或对象存储经中转服务）。Windows 与 Android 首发，架构预留 iOS / macOS / Linux。

- 日历：按月展示所有成员的经期开始日，点某天看当天有谁在经期
- 档案：每个成员独立档案（周期/经期天数、最近一次开始日、提醒天数、头像），
  底部彩色圆底个人日历区分经期 / 排卵与危险期 / 安全期
- 预测：周期与经期天数取最近 6 次记录平均，不足时用档案值；排卵 = 下次开始前 14 天，
  危险期 = 排卵前 5 后 4，全部参数可在设置里调整
- 提醒：系统通知按每人预测的下次开始日提前 N 天触发；Windows 上通知依赖程序运行
- 隐私：应用锁（PIN / 生物识别）、切后台隐藏预览、同步前本地加密、无统计与追踪

> 预测结果仅供参考，不能作为避孕或医疗依据。

## 目录结构

```
app/                 Flutter 应用（Windows + Android）
server/relay/        中转同步服务（Cloudflare Worker + R2）
tools/icon-gen/      图标栅格化脚本（开发期使用，正常构建不需要）
packaging/windows/   Windows 安装包脚本（Inno Setup 6）
```

## 构建与运行

前置：

- Flutter 3.47+（stable）
- Windows：Visual Studio 2022+，需要「使用 C++ 的桌面开发」工作负载
  以及 **C++ ATL**（`atlbase.h`，通知与安全存储插件需要）
- Android：Android SDK（platform 36+）、JDK 17+
- 其余依赖由 `flutter pub get` 自动拉取；SQLite 原生库由 `package:sqlite3` 的
  native assets 提供，首次构建会编译一次

```bash
cd app
flutter pub get
flutter run -d windows      # Windows
flutter run -d <device-id>  # Android
```

图标资源已随仓库提交。改过 `app/assets/icon/*.svg` 之后重新生成（需要 Node）：

```bash
cd tools/icon-gen
npm install
node gen.mjs
```

## 打包

Windows（先装 `winget install JRSoftware.InnoSetup`）：

```bash
cd app && flutter build windows --release
"%LOCALAPPDATA%\Programs\Inno Setup 6\ISCC.exe" ..\packaging\windows\moonletter.iss
# 产物：build/installer/Moonletter-<版本>-setup.exe
```

Android（正式签名需要 `app/android/key.properties`，仓库中不含）：

```bash
cd app && flutter build apk --release
# 产物：build/app/outputs/flutter-apk/app-release.apk
```

`key.properties` 形如：

```properties
storeFile=../keystore.jks
storePassword=…
keyAlias=…
keyPassword=…
```

打标签 `v0.1.0` 推送后，`.github/workflows/release.yml` 会同时产出安装包与 APK
并附到 GitHub Release（Android 签名从仓库 secrets 读取）。

## 同步

同步默认关闭。开启后本地数据先加密再上传，服务端只保存密文；口令只在本机保存，
**丢失后无法解密已上传的数据**。

- **WebDAV**：Nextcloud、坚果云等任意 WebDAV 服务。设置 → 云同步里填地址、用户名、
  密码与子目录。
- **中转服务**：仓库自带 `server/relay`（Cloudflare Worker + R2）。

```bash
cd server/relay
npm install
npx wrangler login
npx wrangler r2 bucket create moonletter-sync
npx wrangler deploy
```

部署后把 Worker 地址和「同步 ID」（应用里生成）填进设置。同步按记录合并，以最新
修改时间为准；删除用标记保留，不会被旧数据复活。

## 数据

设置 → 数据 里可以导出 JSON（完整备份，含头像）或导出经期 CSV（Excel 可直接打开），
导入时按记录合并，不会覆盖更新的本地数据。

## 开发

```bash
cd app
flutter analyze
flutter test
```

主要目录：`lib/core`（主题、路由、平台能力）、`lib/data`（drift 数据库与仓储）、
`lib/domain`（预测、提醒、同步、备份的纯逻辑）、`lib/features`（界面）。

## 许可证

MIT
