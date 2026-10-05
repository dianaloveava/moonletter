; 月信 Moonletter —— Windows 安装包脚本（Inno Setup 6）
; 用法：
;   1. cd app && flutter build windows --release
;   2. ISCC.exe packaging\windows\moonletter.iss
; 安装到用户目录（不需要管理员），开始菜单快捷方式同时用于 Windows 通知的 AUMID。

#define MyAppName "Moonletter"
#define MyAppVersion "0.1.0"
#define MyAppPublisher "Moonletter contributors"
#define MyAppExeName "moonletter.exe"
#define BuildDir "..\..\app\build\windows\x64\runner\Release"

[Setup]
AppId={{8F6C1B74-3C62-4F5C-9D2F-9D5F0F1B6A31}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\Moonletter
DefaultGroupName=Moonletter
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=..\..\build\installer
OutputBaseFilename=Moonletter-{#MyAppVersion}-setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "chinesesimplified"; MessagesFile: "ChineseSimplified.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
; 开始菜单快捷方式：Windows 通知（未打包应用）依赖它注册 AUMID
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"
