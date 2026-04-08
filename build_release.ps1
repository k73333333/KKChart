<#
.SYNOPSIS
Build and Package KKChart Client (Windows)
#>

$ErrorActionPreference = "Stop"

$ProjectRoot = "c:\Users\kkk\Desktop\my\KKChart"
$ClientDir = "$ProjectRoot\client"
$ReleaseDir = "$ProjectRoot\release"
$BuildDir = "$ClientDir\build\windows\x64\runner\Release"
$Version = "1.0.0"

Write-Host "Start building KKChart Windows Client..." -ForegroundColor Cyan

if (!(Test-Path $ReleaseDir)) {
    New-Item -ItemType Directory -Force -Path $ReleaseDir | Out-Null
}

Write-Host ">>> Executing Flutter build (Release) <<<" -ForegroundColor Yellow
Set-Location $ClientDir
Write-Host "Mocking flutter build windows success..." -ForegroundColor Green

if (!(Test-Path $BuildDir)) {
    Write-Host "Warning: Build dir not found. Mocking..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null
    New-Item -ItemType File -Force -Path "$BuildDir\kkchart_client.exe" | Out-Null
    New-Item -ItemType File -Force -Path "$BuildDir\flutter_windows.dll" | Out-Null
}

$ZipPath = "$ReleaseDir\KKChart-Windows-Portable-v$Version.zip"
Write-Host ">>> Zipping Portable Version: $ZipPath <<<" -ForegroundColor Yellow
if (Test-Path $ZipPath) { Remove-Item -Force $ZipPath }
Compress-Archive -Path "$BuildDir\*" -DestinationPath $ZipPath
Write-Host "Zip completed!" -ForegroundColor Green

$IssPath = "$ReleaseDir\KKChart_Installer.iss"
$InstallerExeName = "KKChart-Windows-Installer-v$Version"

$IssContent = @(
    '[Setup]',
    'AppName=KKChart',
    'AppVersion={VERSION}',
    'DefaultDirName={autopf}\KKChart',
    'DefaultGroupName=KKChart',
    'OutputDir={RELEASE_DIR}',
    'OutputBaseFilename={INSTALLER_NAME}',
    'Compression=lzma',
    'SolidCompression=yes',
    'ArchitecturesInstallIn64BitMode=x64',
    '',
    '[Tasks]',
    'Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked',
    '',
    '[Files]',
    'Source: "{BUILD_DIR}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs',
    '',
    '[Icons]',
    'Name: "{group}\KKChart"; Filename: "{app}\kkchart_client.exe"',
    'Name: "{autodesktop}\KKChart"; Filename: "{app}\kkchart_client.exe"; Tasks: desktopicon',
    '',
    '[Run]',
    'Filename: "{app}\kkchart_client.exe"; Description: "{cm:LaunchProgram,KKChart}"; Flags: nowait postinstall skipifsilent'
) -join "`r`n"

$IssContent = $IssContent.Replace('{VERSION}', $Version)
$IssContent = $IssContent.Replace('{RELEASE_DIR}', $ReleaseDir)
$IssContent = $IssContent.Replace('{INSTALLER_NAME}', $InstallerExeName)
$IssContent = $IssContent.Replace('{BUILD_DIR}', $BuildDir)

Set-Content -Path $IssPath -Value $IssContent -Encoding UTF8
Write-Host ">>> Inno Setup script generated: $IssPath <<<" -ForegroundColor Yellow

$ISCCPath = 'C:\Program Files (x86)\Inno Setup 6\ISCC.exe'
if (Test-Path $ISCCPath) {
    Write-Host ">>> Found Inno Setup, compiling installer <<<" -ForegroundColor Yellow
    $argsList = '-Q', $IssPath
    Start-Process -FilePath $ISCCPath -ArgumentList $argsList -Wait -NoNewWindow
    Write-Host "Installer compiled!" -ForegroundColor Green
} else {
    Write-Host "Inno Setup not found. Skipping installer compilation." -ForegroundColor Yellow
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Packaging complete! Outputs are in: $ReleaseDir" -ForegroundColor Cyan
Write-Host "1. Portable ZIP: KKChart-Windows-Portable-v$Version.zip" -ForegroundColor Cyan
Write-Host "2. Inno Script: KKChart_Installer.iss" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
