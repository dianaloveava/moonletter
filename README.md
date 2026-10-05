<div align="center">

<img src="app/assets/icon/logo_512.png" width="112" alt="月信">

# 月信 · Moonletter

**安静地记录，清楚地知道。**

本地优先的多人经期记录应用。数据保存在你自己的设备上，离线可用；
需要多台设备时，再打开端到端加密的同步。

![平台](https://img.shields.io/badge/平台-Windows%20·%20Android-C4737F?style=flat-square&labelColor=8A8A8E)
![框架](https://img.shields.io/badge/Flutter-3.47-C4737F?style=flat-square&labelColor=8A8A8E&logo=flutter&logoColor=white)
![许可证](https://img.shields.io/badge/许可证-MIT-C4737F?style=flat-square&labelColor=8A8A8E)
![版本](https://img.shields.io/badge/版本-0.1.0-C4737F?style=flat-square&labelColor=8A8A8E)

</div>

> 预测由历史记录推算得出，仅供参考，不能作为避孕、诊断或医疗决策的依据。

## 截图

| 日历 | 档案 | 预测与记录 |
| :---: | :---: | :---: |
| <img src="docs/screenshots/android-calendar.png" width="240"> | <img src="docs/screenshots/android-profiles.png" width="240"> | <img src="docs/screenshots/android-prediction.png" width="240"> |
| 只标注经期开始日，点开看当天有谁 | 多人各一份档案，互不打扰 | 周期、经期与排卵自动推算 |

| 个人日历 | 深色模式 |
| :---: | :---: |
| <img src="docs/screenshots/android-personal-calendar.png" width="240"> | <img src="docs/screenshots/android-calendar-dark.png" width="240"> |
| 实心、描边、浅底区分经期与危险期 | 深色配色单独调整，夜间不刺眼 |

<img src="docs/screenshots/windows-calendar.png" width="760" alt="Windows 版日历">

Windows 上底部栏收成左侧边栏，窗口拉宽时日历与当天摘要并排展开。

## 主要功能

### 一眼看清的日历

月历上只标记经期的开始日：有记录的日子画一圈，当天处于经期的人以头像显示，超过三位折叠成 `+N`。
点任意一天，下方列出当天有谁、处于经期第几天。今天与选中的日期用不同形态的圈区分。

### 每人一份档案

为每个人独立建档：头像、昵称、年龄、身高、体重与描述，周期天数、经期天数、提醒提前天数也各自保存。
没有头像时用昵称首字与自动分配的颜色代替。
档案底部是她自己的日历，把推算出来的日子画出来：

<img src="docs/screenshots/android-personal-calendar.png" width="260" alt="个人日历">

### 会跟着记录走的预测

周期与经期天数取**最近 6 次记录**的平均值（次数可改），记录不足时退回档案里的设定值。
下次开始日 = 最近一次开始日 + 周期天数；排卵日 = 下次开始前 14 天；危险期 = 排卵前后若干天；其余为安全期。
这些参数都在「设置 → 预测规则」里，随时可调。

<img src="docs/screenshots/android-settings.png" width="260" alt="设置">

### 只在该提醒的时候提醒

按每个人预测的下次开始日，提前若干天发出系统通知，个人设定优先于全局设定。
锁屏通知可以隐去人名，只显示「经期将至」。

- **Windows**：常驻托盘，可随开机启动；关闭主窗口后仍在后台计时。
- **Android**：需要通知与「闹钟和提醒」权限，「提醒设置」页会显示当前状态并一步步引导；建议把应用加入电池优化白名单并允许自启动，否则部分系统会在重启后延迟唤醒提醒。

### 隐私是默认设置

数据只写在本机的 SQLite 文件里。没有账号，没有统计，没有追踪，不申请无关权限。
可以开启应用锁：6 位 PIN，或 Windows Hello / Android 生物识别。切到后台时内容自动盖住，任务切换器里看不到日期与人名。
同步是可选项，且**先在本机加密再上传**，服务端只保存密文。

### 数据始终在你手里

- 导出 JSON：含头像与全部记录的完整备份。
- 导出 CSV：只含经期记录，Excel 可直接打开。
- 导入按记录合并：文件中比本地新的记录会覆盖本地；本地已删除、而文件里仍然存在的成员会被还原。

### 需要时才开启的同步

同步默认关闭。开启后可以选用：

- **WebDAV**：Nextcloud、坚果云等任意 WebDAV 服务。
- **中转服务**：仓库自带 `server/relay`（Cloudflare Worker + R2），自己部署即可。

两端按记录合并，以最新修改时间为准；删除会保留标记，不会被旧设备上的数据复活。
同步口令由你自己设定，只保存在本机 —— 丢失后已经上传的数据无法解密。

### 外观

8 款预设主题色、浅色与深色模式，圆角、留白与动效按同一套规范打磨；
底栏与弹层使用毛玻璃，在老设备上自动降级为纯色。界面语言支持中文与英文，默认跟随系统。

## 下载

到 [Releases](https://github.com/dianaloveava/moonletter/releases) 下载最新版本：

| 平台 | 文件 | 说明 |
| :--- | :--- | :--- |
| Windows 10 / 11（64 位） | `Moonletter-0.1.0-setup.exe` | 安装包，注册开始菜单与桌面快捷方式 |
| Android 7.0 及以上 | `app-release.apk` | 直接安装。首次使用不需要注册或登录 |

也可以从源码构建，见下文「构建与打包」。

## 开始使用

1. 打开「档案」，点右上角 `+` 添加一位成员，填昵称与周期天数。
2. 记下最近一次经期的开始日；结束后补上结束日，预测会自动更新。
3. 到「设置 → 提醒设置」允许通知权限，选定提前几天提醒。
4. 换设备或备份时，用「设置 → 数据」导出 JSON，在新设备导入即可。

## 常见问题

**提醒没有按时到达**

- Android：确认通知与「闹钟和提醒」权限都已允许（「设置 → 提醒设置」会显示状态）；把应用加入电池优化白名单；在系统设置里允许自启动，否则重启后需要先打开一次应用。部分厂商系统（ColorOS、MIUI 等）还会额外限制后台活动。
- Windows：通知依赖应用处于运行状态。关闭了托盘常驻的话，退出后就不会再提醒。
- 系统本身也可能把闹钟推迟几分钟送达，这是省电策略的一部分。

**忘记同步口令，或者换了设备**

口令只保存在本机，丢失后无法解密已经上传的数据，请在开启同步时另外记一份。
迁移数据可以用「导出 JSON → 在新设备导入」，也可以在新设备上填同一个远端地址与口令继续同步。

**会上传我的数据吗**

不会。唯一的网络请求是你主动开启的同步，以及检查更新（可关闭）。应用没有统计与追踪代码。

**日历上为什么只有开始日**

主日历只呈现真实记录。推算出来的经期、排卵与危险期画在每个人的档案日历里，不会混进已记录的事实中。

## 同步服务

**WebDAV**：在「设置 → 云同步」里填地址、用户名、密码与子目录，同步前本地加密。

**中转服务**（Cloudflare Worker + R2）：

```bash
cd server/relay
npm install
npx wrangler login
npx wrangler r2 bucket create moonletter-sync
npx wrangler deploy
```

部署后把 Worker 地址与「同步 ID」填进应用。

## 构建与打包

前置：

- Flutter 3.47+（stable）
- Windows：Visual Studio 2022+，需要「使用 C++ 的桌面开发」工作负载，以及 **C++ ATL**（`flutter_secure_storage_windows` 需要 `atlstr.h`）
- Android：Android SDK（platform 36+）、JDK 17+
- 其余依赖由 `flutter pub get` 拉取；SQLite 原生库由 `package:sqlite3` 的 native assets 提供，首次构建会编译一次

```bash
cd app
flutter pub get
flutter run -d windows      # Windows
flutter run -d <device-id>  # Android
```

图标资源随仓库提交。改过 `app/assets/icon/*.svg` 之后重新生成（需要 Node）：

```bash
cd tools/icon-gen
npm install
node gen.mjs
```

### 打包

Windows（先装 `winget install JRSoftware.InnoSetup`）：

```bash
cd app && flutter build windows --release
"%LOCALAPPDATA%\Programs\Inno Setup 6\ISCC.exe" ..\packaging\windows\moonletter.iss
# 产物：build/installer/Moonletter-<版本>-setup.exe
```

安装界面用的 `packaging/windows/ChineseSimplified.isl` 随仓库提供（Inno Setup 官方安装包里不带中文语言文件）。

Android（正式签名需要 `app/android/key.properties`，仓库中不含；缺它时命令仍能构建，但产物是 **debug 证书签名**，只能自测不能发布）：

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

打标签 `v0.1.0` 推送后，`.github/workflows/release.yml` 会产出安装包与 APK 并附到 GitHub Release（Android 签名从仓库 secrets 读取）。

## 目录结构

```
app/                 Flutter 应用（Windows + Android）
server/relay/        中转同步服务（Cloudflare Worker + R2）
tools/icon-gen/      图标栅格化脚本（开发期使用，正常构建不需要）
packaging/windows/   Windows 安装包脚本（Inno Setup 6）
docs/screenshots/    界面截图
```

主要代码在 `app/lib`：`core`（主题、路由、平台能力）、`data`（drift 数据库与仓储）、
`domain`（预测、提醒、同步、备份的纯逻辑）、`features`（界面）。

## 贡献

Issue 与 Pull Request 都欢迎。改动之后请先跑通：

```bash
cd app
flutter analyze
flutter test
```

## 许可证

[MIT](LICENSE)。

月信是一个记录工具。它的预测来自历史记录的平均与推算，**不能作为避孕、诊断或医疗决策的依据**；
身体有异常时请咨询医生。
