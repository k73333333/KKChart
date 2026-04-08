<#
.SYNOPSIS
修复 Flutter Windows 构建时因为权限或杀毒软件拦截导致无法创建软链接 (symlink) 的问题。

.DESCRIPTION
该脚本读取 Flutter 插件依赖配置，将原本需要高权限的 Symbolic Link 替换为无需特殊权限的目录联接 (Directory Junction)。
#>

# 设置错误行为，遇到错误即刻停止
$ErrorActionPreference = "Stop"

# 获取当前脚本所在目录（即 client 目录）
$clientDir = $PSScriptRoot
# 拼接 .flutter-plugins-dependencies 文件路径，用于读取当前项目的插件依赖信息
$depsFile = Join-Path $clientDir ".flutter-plugins-dependencies"
# 拼接 Windows 平台下存放插件符号链接的临时目录路径
$symlinksDir = Join-Path $clientDir "windows\flutter\ephemeral\.plugin_symlinks"

# 检查依赖信息文件是否存在
if (-not (Test-Path $depsFile)) {
    Write-Host "未找到 .flutter-plugins-dependencies 文件。请先执行一次 flutter pub get。" -ForegroundColor Yellow
    exit
}

# 读取并解析 JSON 格式的依赖配置
$json = Get-Content -Raw $depsFile | ConvertFrom-Json
# 提取 Windows 平台的插件列表
$windowsPlugins = $json.plugins.windows

# 检查是否存在 Windows 插件依赖
if ($null -eq $windowsPlugins) {
    Write-Host "没有找到 Windows 插件依赖。" -ForegroundColor Green
    exit
}

# 如果临时符号链接目录不存在，则强制创建它
if (-not (Test-Path $symlinksDir)) {
    New-Item -ItemType Directory -Path $symlinksDir -Force | Out-Null
}

Write-Host "开始为 Windows 插件创建目录联接 (Junction)..." -ForegroundColor Cyan

# 遍历每一个 Windows 插件并为其创建目录联接
foreach ($plugin in $windowsPlugins) {
    # 插件名称
    $name = $plugin.name
    # 插件真实的磁盘缓存路径，去除末尾的斜杠以防路径拼接错误
    $target = $plugin.path.TrimEnd('\')
    # 目标要创建的目录联接的完整路径
    $link = Join-Path $symlinksDir $name
    
    # 如果已存在（可能是失效的链接或旧联接），则强制递归删除
    if (Test-Path $link) {
        Remove-Item -Recurse -Force $link
    }
    
    # 使用 Junction 模式创建目录联接，这种方式不需要管理员权限，也不会被安全软件（如奇安信）拦截
    New-Item -ItemType Junction -Path $link -Value $target | Out-Null
    Write-Host "已创建联接: $name -> $target" -ForegroundColor Green
}

Write-Host "修复完成！现在可以正常运行 flutter run -d windows 了。" -ForegroundColor Cyan
