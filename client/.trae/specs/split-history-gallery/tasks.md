# Tasks
- [x] Task 1: 改造工作台页面 `DashboardScreen`
  - [x] SubTask 1.1: 移除 `initState` 中的历史图表加载逻辑 `_loadCharts()` 以及界面上的“刷新列表”按钮。
  - [x] SubTask 1.2: 修改画廊为空时的展示提示为“当前暂无生成的图表”。
  - [x] SubTask 1.3: 引入 `database_helper.dart`，在每次点击“一键生成”成功后，清空当前列表（或每次只展示最新生成的图表），将生成的图表添加到 `_chartList`。
  - [x] SubTask 1.4: 组装一条真实的图表数据（必须包含 `id`, `title`, `option_json`, `created_at`, `updated_at` 字段以符合数据库要求），并调用 `DatabaseHelper.instance.insertChart` 将其保存到本地数据库。

- [x] Task 2: 新建历史记录页面 `HistoryScreen`
  - [x] SubTask 2.1: 创建 `lib/screens/history_screen.dart`。
  - [x] SubTask 2.2: 使用 `MasonryGridView` 布局实现历史图表列表的展示结构。
  - [x] SubTask 2.3: 在 `initState` 中调用 `DatabaseHelper.instance.getAllCharts()` 从本地加载真实的图表历史数据并解析展示。
  - [x] SubTask 2.4: 完善页面内的交互：点击“删除”能够调用 `deleteChart` 并刷新列表；点击“复制”能够生成副本、保存至数据库并刷新列表。

- [x] Task 3: 更新导航栏侧边菜单 `main.dart`
  - [x] SubTask 3.1: 导入 `history_screen.dart`。
  - [x] SubTask 3.2: 在侧边导航的 `items` 列表中，增加一个使用 `FluentIcons.history` 图标的“历史记录”入口。

# Task Dependencies
- [Task 2] depends on [Task 1] (由于需要在工作台先实现数据存入数据库的逻辑，再在历史记录页面测试加载效果)
- [Task 3] depends on [Task 2] (需要引入新创建的历史记录页面)