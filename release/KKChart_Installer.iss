[Setup]
AppName=KKChart
AppVersion=1.0.0
DefaultDirName={autopf}\KKChart
DefaultGroupName=KKChart
OutputDir=c:\Users\kkk\Desktop\my\KKChart\release
OutputBaseFilename=KKChart-Windows-Installer-v1.0.0
Compression=lzma
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "c:\Users\kkk\Desktop\my\KKChart\client\kkchart_client\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\KKChart"; Filename: "{app}\kkchart_client.exe"
Name: "{autodesktop}\KKChart"; Filename: "{app}\kkchart_client.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\kkchart_client.exe"; Description: "{cm:LaunchProgram,KKChart}"; Flags: nowait postinstall skipifsilent
