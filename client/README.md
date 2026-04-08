# KKChart Client (Windows 桌面端)

![KKChart](https://img.shields.io/badge/Platform-Windows-blue) ![Flutter](https://img.shields.io/badge/Framework-Flutter-02569B?logo=flutter)

KKChart 是一款基于 **Flutter** 开发的 Windows 桌面端应用程序，采用了现代化的 Windows 11 **Fluent Design** (通过 `fluent_ui` 包)。该应用旨在帮助用户快速将杂乱的文本或文件数据，通过调用 AI 大语言模型（如 OpenAI、千问等）智能分析并生成丰富多样的 **Apache ECharts** 可视化图表。

## ✨ 核心功能

*   **🪄 AI 智能生成图表**：用户只需粘贴杂乱数据，内置的 AI Prompt 会自动清洗、归纳数据，并一次性生成多个不同维度的图表 (支持饼图、柱状图、折线图、散点图等)。
*   **🖼️ 画廊模式与懒加载**：生成的图表会在画廊中以卡片形式展示，支持一键复制与删除。
*   **✏️ 深度编辑与 JSON 微调**：点击图表可进入全屏编辑器。除提供图形化基础属性调整外，还支持直接编辑底层 ECharts JSON 源码，并在客户端实现 `Ctrl+Z` 撤销/重做栈。
*   **🧠 AI 深度洞察报告**：在图表详情页，一键请求 AI 根据当前图表的数据分布提供专业的洞察报告与业务建议。
*   **📤 一键导出**：支持一键将图表导出并复制为高清 PNG 图片，以及后续规划的 PPT 导出支持。
*   **🌐 灵活的 API 配置**：支持脱机模式，用户可在“系统设置”中自定义配置第三方 AI API 地址和密钥，数据更安全。
*   **🪲 日志与反馈**：自带本地日志记录系统，并支持一键将日志打包至桌面或通过默认邮件客户端快速向开发者发送反馈。

## 🛠️ 技术栈

*   **UI 框架**: Flutter (Desktop)
*   **UI 风格**: `fluent_ui` (Windows 11 风格), `bitsdojo_window` (无边框窗口与拖拽)
*   **状态管理**: `flutter_riverpod`
*   **图表引擎**: `flutter_echarts` (内部挂载 WebView 渲染真实 ECharts)
*   **网络与持久化**: `dio`, `sqflite`
*   **工具库**: `hotkey_manager` (全局快捷键), `pasteboard` (剪贴板图片操作), `archive` (日志压缩)

---

## 🚀 本地开发与运行指南

### 1. 环境准备

确保您的电脑上已安装并配置好以下环境：
*   **Flutter SDK** (建议 >= 3.19.0)
*   **Visual Studio** (安装了 "Desktop development with C++" 工作负载，用于编译 Windows 原生插件)

### 2. 依赖安装与权限问题处理

进入客户端目录并拉取依赖：

```powershell
cd client
flutter pub get
```

> **⚠️ [重要] Windows Symlink 权限错误 (ERROR_ACCESS_DENIED)**
> 如果您在运行 `flutter pub get` 或 `flutter build windows` 时遇到了关于创建符号链接 (`.plugin_symlinks`) 被拒绝的错误。这通常是因为企业级杀毒软件（如奇安信）拦截或没有管理员权限。
> 
> **解决方案：**
> 1. 打开终端（无需管理员权限），确保已执行 `flutter pub get`。
> 2. 在项目根目录执行环境修复脚本：
>    ```powershell
>    .\create_junctions.ps1
>    ```
>    *(该脚本会自动读取依赖并创建安全的目录联接 Junction，从而完美绕过系统的软链接拦截)*
> 3. 再次运行 `flutter run -d windows` 或构建命令即可顺利通过。

### 3. 运行应用

确保依赖获取成功且插件链接创建完毕后，运行应用：

```powershell
flutter run -d windows
```

---

## 📦 构建与发布

本项目提供了一键打包脚本 `build_release.ps1` (位于项目根目录)，它可以自动执行 Flutter Release 构建，并打包输出绿色免安装版 ZIP 和 Inno Setup 安装包 EXE。

### 步骤

1. 返回项目根目录。
2. 确保系统已安装 **[Inno Setup 6](https://jrsoftware.org/isinfo.php)**（如果只需要 ZIP 绿色版则不需要）。
3. 执行打包脚本：

```powershell
cd ../../ # 回到项目根目录
powershell -ExecutionPolicy Bypass -File .\build_release.ps1
```

构建成功后，所有产物将输出在项目根目录的 `release/` 文件夹下。

---

## 📁 目录结构简介

```text
lib/
├── db/                 # SQLite 数据库助手 (配置存储)
├── screens/            # 页面组件
│   ├── dashboard_screen.dart    # 数据输入与 AI 触发页
│   ├── gallery_screen.dart      # 图表画廊列表页
│   ├── chart_detail_screen.dart # 图表详情与高级编辑页
│   └── settings_screen.dart     # 系统设置与日志反馈页
├── services/           # 业务逻辑与网络服务
│   └── ai_service.dart          # AI 接口代理与 JSON 清洗提取逻辑
├── utils/              # 工具类 (日志记录等)
└── main.dart           # 应用入口与全局路由布局 (NavigationView)
```
