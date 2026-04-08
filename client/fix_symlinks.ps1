# PowerShell script to create directory junctions instead of symlinks for Flutter plugins
# Useful when CreateSymbolicLinkW is blocked by strict Enterprise Antivirus.

$ErrorActionPreference = "Stop"

$PluginSymlinksDir = "windows\flutter\ephemeral\.plugin_symlinks"
$DependenciesFile = ".flutter-plugins-dependencies"

if (-not (Test-Path $PluginSymlinksDir)) {
    New-Item -ItemType Directory -Path $PluginSymlinksDir | Out-Null
}

if (-not (Test-Path $DependenciesFile)) {
    Write-Host "File $DependenciesFile not found. Please run flutter pub get first (it may fail but will generate the file)."
    exit
}

$content = Get-Content $DependenciesFile | ConvertFrom-Json

if ($content.plugins.windows) {
    foreach ($plugin in $content.plugins.windows) {
        $pluginName = $plugin.name
        $pluginPath = $plugin.path
        
        $targetJunctionPath = Join-Path $PluginSymlinksDir $pluginName
        
        if (Test-Path $targetJunctionPath) {
            Write-Host "Junction already exists for $pluginName. Skipping."
        } else {
            Write-Host "Creating Junction for $pluginName -> $pluginPath"
            # Using cmd /c mklink /J because New-Item -ItemType Junction can sometimes be finicky depending on PS version
            cmd /c mklink /J "$targetJunctionPath" "$pluginPath"
        }
    }
    Write-Host "All Windows plugin junctions created successfully!"
} else {
    Write-Host "No Windows plugins found in dependencies file."
}
