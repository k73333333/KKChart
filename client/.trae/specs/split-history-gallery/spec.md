# 图表画廊与历史记录分离 Spec

## Why
当前工作台（DashboardScreen）下方的图表画廊默认加载了所有历史图表，并且使用模拟数据。为了提升用户体验和满足实际需求，工作台的图表画廊应该默认保持为空，每次 AI 生成图表成功后更新并展示当前新生成的图表，并且自动将生成的图表缓存在本地数据库中。同时，提供一个独立的“历史记录”页面，专门用于从本地数据库加载并查看、管理之前生成的所有图表。

## What Changes
- 修改 `DashboardScreen`：
  - 移除初始化时模拟加载历史图表的逻辑，使画廊默认留空。
  - 在生成新图表成功后，将其展示在当前画廊列表中（只显示本次生成的最新图表）。
  - 生成的图表数据需调用 `DatabaseHelper.instance.insertChart` 持久化存储到本地 SQLite 数据库中。
- 新增 `HistoryScreen`：
  - 创建独立的历史记录页面。
  - 从本地数据库调用 `DatabaseHelper.instance.getAllCharts` 加载所有历史缓存的图表。
  - 实现图表在历史记录页面的展示、复制副本以及从本地数据库真实删除的功能。
- 修改 `main.dart`：在主侧边栏导航中增加“历史记录”入口。

## Impact
- Affected specs: 图表生成流程、本地持久化流程、历史图表展示流程
- Affected code: 
  - `lib/screens/dashboard_screen.dart`
  - `lib/main.dart`
  - `lib/screens/history_screen.dart` (新增)

## ADDED Requirements
### Requirement: 基于本地缓存的独立历史记录页
The system SHALL provide a dedicated history screen that loads data from local SQLite storage.
#### Scenario: Success case
- **WHEN** 用户在侧边栏点击“历史记录”
- **THEN** 页面跳转至历史记录页，调用本地数据库加载所有已保存的历史图表卡片并展示。

## MODIFIED Requirements
### Requirement: 工作台展示并保存当前生成的图表
工作台下方的图表画廊默认应当为空。当生成新图表时，仅在工作台展示本次生成的图表，同时将其持久化到本地数据库。
#### Scenario: Success case
- **WHEN** 用户进入工作台
- **THEN** 下方图表画廊提示为空。
- **WHEN** 用户生成图表
- **THEN** 生成结果存入本地 SQLite，且仅在工作台下方画廊显示刚才生成的图表结果。