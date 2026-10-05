<div align="center">

<img src="app/assets/icon/logo_512.png" width="112" alt="Moonletter">

# Moonletter

**A letter each month, a date to keep.**

[中文](README.md) · English

![Platform](https://img.shields.io/badge/platform-Windows%20·%20Android-C4737F?style=flat-square&labelColor=8A8A8E)
![License](https://img.shields.io/badge/license-MIT-C4737F?style=flat-square&labelColor=8A8A8E)
![Version](https://img.shields.io/badge/version-0.1.0-C4737F?style=flat-square&labelColor=8A8A8E)

</div>

Moonletter tracks periods for several people at once. It is written in Flutter and runs on Windows and Android. Data stays on your device by default: no account, no internet required. If you want the same records on more than one device, you can turn on end-to-end encrypted sync.

> Predictions are calculated from your records. They are for reference only and must not be used for contraception, diagnosis, or medical decisions. If something seems wrong, see a doctor.

## Screenshots

| Calendar | Profiles | Prediction and records |
| :---: | :---: | :---: |
| <img src="docs/screenshots/android-calendar.png" width="240"> | <img src="docs/screenshots/android-profiles.png" width="240"> | <img src="docs/screenshots/android-prediction.png" width="240"> |

| Personal calendar | Dark mode |
| :---: | :---: |
| <img src="docs/screenshots/android-personal-calendar.png" width="240"> | <img src="docs/screenshots/android-calendar-dark.png" width="240"> |

<img src="docs/screenshots/windows-calendar.png" width="760" alt="Calendar on Windows">

On Windows the bottom bar becomes a side bar, and a wide window shows the calendar and the day summary next to each other.

## Features

### Calendar

The month view only marks the day a period starts: that day gets a ring, the people who are on their period that day show their avatars, and more than three of them collapse into `+N`. Tap any day and the panel below lists who is on their period and which day they are on. Today and the selected day are marked with different rings.

### Profiles

Each person gets a profile: avatar, name, age, height, weight, note, plus their own cycle length, period length, and how many days ahead to remind. Without an avatar, the first character of the name is used together with an automatically assigned colour.

At the bottom of a profile is a personal calendar that draws the predicted period, ovulation day, and fertile window, each with a different ring style.

<img src="docs/screenshots/android-personal-calendar.png" width="260" alt="Personal calendar">

### Prediction

Cycle length and period length are the average of the most recent 6 records (the count is configurable); when there are too few records, the values set on the profile are used.

- Next start = most recent start + cycle length
- Ovulation day = 14 days before the next start
- The fertile window is a few days around the ovulation day, the rest is the safe period

All of these parameters can be adjusted in Settings → Prediction rules.

<img src="docs/screenshots/android-settings.png" width="260" alt="Settings">

### Reminders

A system notification is sent a few days before each person's predicted start date. A per-person setting takes priority over the global one. Lock-screen notifications can hide names and show only “period is coming”.

On Windows the app stays in the tray and can start with the system; closing the main window keeps it running in the background. On Android the app needs the notification and “alarms and reminders” permissions; the Reminder settings page shows their current state and how to grant them. Some systems also need the app excluded from battery optimisation, see [Reminders arrive late](#reminders-arrive-late).

### Privacy

Data lives in a local SQLite file. No account, no analytics or tracking code, and no permissions the app does not need.

You can turn on an app lock with a 6-digit PIN, or with Windows Hello / Android biometrics. When the app goes to the background its content is covered, so the task switcher shows neither dates nor names.

Sync is optional: data is encrypted on your device before it is uploaded, and the server only ever stores ciphertext.

### Import and export

- Export JSON: a full backup including avatars and every record.
- Export CSV: period records only, ready to open in Excel.
- Import merges record by record: records in the file that are newer than yours win, and a member you deleted locally is restored if the file still has her.

### Sync

Sync is off by default. Once enabled you can use WebDAV (Nextcloud, Jianguoyun, …) or your own relay service. The two sides merge record by record, newest change first. Deletions are kept as tombstones, so data on an old device cannot bring them back.

The sync passphrase is set by you and kept on your device only. If you lose it, the data already uploaded cannot be decrypted. See [Sync service](#sync-service) for the setup.

### Appearance

Eight preset accent colours, with light and dark modes. The interface is available in Chinese and English and follows the system language by default. The bottom bar and sheets use a translucent blur, which falls back to a solid colour on older devices.

## Download

Get the latest version from [Releases](https://github.com/dianaloveava/moonletter/releases):

| Platform | File | Notes |
| :--- | :--- | :--- |
| Windows 10 / 11 (64-bit) | `Moonletter-0.1.0-setup.exe` | Installer; creates Start menu and desktop shortcuts |
| Android 7.0 or newer | `app-release.apk` | Install directly, no sign-up or login |

You can also build from source, see [Build and packaging](#build-and-packaging).

## Getting started

1. Open Profiles, tap `+` in the top right corner, and fill in a name and cycle length.
2. Record the start of the most recent period and add the end date once it is over; the prediction follows.
3. In Settings → Reminder settings, allow notifications and choose how many days ahead to be reminded.
4. To move to another device or make a backup, export JSON in Settings → Data and import it on the new device.

## FAQ

### Reminders arrive late

Android:

- Make sure the notification and “alarms and reminders” permissions are granted; Settings → Reminder settings shows their state.
- Add the app to the battery optimisation whitelist.
- Allow auto-start in the system settings, otherwise reminders only come back after you open the app once following a restart.
- Systems such as ColorOS and MIUI add further restrictions on background activity.

Windows: reminders need the app to be running. If you turn off staying in the tray and quit the app, nothing will be sent.

Also, the system may delay an alarm by a few minutes to save power.

### I forgot the sync passphrase, or I switched device

The passphrase is kept on your device only. Once lost, data already uploaded cannot be decrypted, so keep a copy of it when you enable sync.

To switch device, either export JSON and import it on the new device, or enter the same remote address and passphrase there to keep syncing.

### Does it upload my data

No. The app makes only two kinds of network requests: the sync you turn on yourself, and the update check (which can be disabled).

### Why does the calendar only show start days

The main calendar shows real records only. Predicted periods, ovulation days, and fertile windows are drawn in each personal calendar, kept apart from what has actually been recorded.

## Sync service

### WebDAV

Enter the address, username, password, and sub-directory in Settings → Cloud sync. Data is encrypted on your device before it is uploaded.

### Relay service

Built on Cloudflare Worker + R2, the code is in `server/relay`:

```bash
cd server/relay
npm install
npx wrangler login
npx wrangler r2 bucket create moonletter-sync
npx wrangler deploy
```

After deploying, enter the Worker address and the sync ID in the app.

## Build and packaging

Prerequisites:

- Flutter 3.47+ (stable)
- Windows: Visual Studio 2022+, with the “Desktop development with C++” workload and C++ ATL (`flutter_secure_storage_windows` needs `atlstr.h`)
- Android: Android SDK (platform 36+), JDK 17+
- Everything else comes from `flutter pub get`. The native SQLite library is provided by `package:sqlite3` native assets and is compiled once on the first build

```bash
cd app
flutter pub get
flutter run -d windows      # Windows
flutter run -d <device-id>  # Android
```

The icon assets are committed. After changing `app/assets/icon/*.svg` they have to be regenerated (Node required):

```bash
cd tools/icon-gen
npm install
node gen.mjs
```

### Packaging

Windows (install Inno Setup first with `winget install JRSoftware.InnoSetup`):

```bash
cd app && flutter build windows --release
"%LOCALAPPDATA%\Programs\Inno Setup 6\ISCC.exe" ..\packaging\windows\moonletter.iss
# output: build/installer/Moonletter-<version>-setup.exe
```

The installer uses `packaging/windows/ChineseSimplified.isl`, which is included in this repository because the official Inno Setup installer does not ship a Chinese language file.

Android: release signing needs `app/android/key.properties`, which is not part of this repository. Without it the command still builds, but the result is signed with the debug certificate — fine for testing, not for distribution.

```bash
cd app && flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```

The format of `key.properties`:

```properties
storeFile=../keystore.jks
storePassword=…
keyAlias=…
keyPassword=…
```

Pushing a tag such as `v0.1.0` makes `.github/workflows/release.yml` build the installer and the APK and attach them to a GitHub Release (the Android signing key is read from repository secrets).

## Project layout

```
app/                 Flutter app (Windows + Android)
server/relay/        Relay sync service (Cloudflare Worker + R2)
tools/icon-gen/      Icon rasterisation script (development only, not needed for a normal build)
packaging/windows/   Windows installer script (Inno Setup 6)
docs/screenshots/    Interface screenshots
```

The code is in `app/lib`: `core` (theme, routing, platform capabilities), `data` (drift database and repositories), `domain` (pure logic for prediction, reminders, sync, and backup), `features` (interface).

## Contributing

Issues and pull requests are welcome. After a change, please run:

```bash
cd app
flutter analyze
flutter test
```

## License

[MIT](LICENSE)
