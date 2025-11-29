; Inno Setup Script for Spendly
; This script creates an MSI-equivalent installer for Windows

[Setup]
AppName=Spendly
AppVersion=1.1.5
AppPublisher=Spendly
AppPublisherURL=https://spendly.app
AppSupportURL=https://spendly.app
AppUpdatesURL=https://spendly.app
DefaultDirName={autopf}\Spendly
DefaultGroupName=Spendly
OutputDir=build\windows\installer
OutputBaseFilename=Spendly-Setup-1.1.5
Compression=lzma2
SolidCompression=yes
DisableProgramGroupPage=yes
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
SetupIconFile=windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\expense_tracker.exe
LicenseFile=LICENSE.txt
PrivilegesRequired=lowest
AllowUNCPath=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Copy the executable
Source: "build\windows\x64\runner\Release\expense_tracker.exe"; DestDir: "{app}"; Flags: ignoreversion

; Copy all DLLs
Source: "build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion

; Copy data folder (Flutter assets)
Source: "build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Spendly"; Filename: "{app}\expense_tracker.exe"; IconFilename: "{app}\expense_tracker.exe"
Name: "{group}\{cm:UninstallProgram,Spendly}"; Filename: "{uninstallexe}"
Name: "{commondesktop}\Spendly"; Filename: "{app}\expense_tracker.exe"; IconFilename: "{app}\expense_tracker.exe"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\Spendly"; Filename: "{app}\expense_tracker.exe"; IconFilename: "{app}\expense_tracker.exe"; Tasks: quicklaunchicon

[Run]
Filename: "{app}\expense_tracker.exe"; Description: "{cm:LaunchProgram,Spendly}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: dirifempty; Name: "{app}"
