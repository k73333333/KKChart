import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';

/// 图表画廊，展示 AI 生成的多个图表
class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  // 模拟从 SQLite 或 AI 接口返回的图表配置列表
  List<Map<String, dynamic>> _chartList = [];

  @override
  void initState() {
    super.initState();
    // TODO: 从数据库加载历史生成的图表数据
    _loadCharts();
  }

  void _loadCharts() async {
    // 模拟数据加载
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _chartList = List.generate(
        10,
        (index) => {
          "title": {"text": "图表示例 $index"},
          "id": "chart_$index",
        },
      );
    });
  }

  /// 懒加载与降级渲染策略
  /// 在列表页中，为防止过多的 ECharts WebView 导致主线程卡死
  /// 我们仅渲染图表的缩略图缓存 (Base64) 或简单的占位符。
  /// 点击进入详情页后，再实例化完整的带有动画和交互的 WebView。
  Widget _buildLazyChartCard(Map<String, dynamic> chartData) {
    return Card(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chartData['title']?['text'] ?? '未命名图表',
            style: FluentTheme.of(context).typography.subtitle,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              color: Colors.grey.withOpacity(0.1),
              child: const Center(child: Text('图表缩略图 (轻量级渲染/占位)')),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(FluentIcons.copy),
                onPressed: () {
                  // 复制副本
                  setState(() {
                    final newChart = jsonDecode(jsonEncode(chartData));
                    newChart['id'] =
                        "chart_${DateTime.now().millisecondsSinceEpoch}";
                    if (newChart['title'] != null) {
                      newChart['title']['text'] =
                          "${newChart['title']['text']} (副本)";
                    }
                    _chartList.insert(0, newChart);
                  });
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(FluentIcons.delete),
                onPressed: () {
                  // 删除图表
                  showDialog(
                    context: context,
                    builder: (context) {
                      return ContentDialog(
                        title: const Text('确认删除'),
                        content: const Text('删除后无法恢复，确定要删除这个图表吗？'),
                        actions: [
                          Button(
                            child: const Text('取消'),
                            onPressed: () => Navigator.pop(context),
                          ),
                          FilledButton(
                            child: const Text('删除'),
                            onPressed: () {
                              setState(() {
                                _chartList.removeWhere(
                                  (element) => element['id'] == chartData['id'],
                                );
                              });
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(width: 8),
              FilledButton(
                child: const Text('详情与编辑'),
                onPressed: () {
                  // TODO: 路由到全屏的 ECharts 交互渲染详情页
                  _showChartDetail(chartData);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 展示全屏高清详情 (含真实的 ECharts 渲染与 AI 洞察)
  void _showChartDetail(Map<String, dynamic> chartData) {
    showDialog(
      context: context,
      builder: (context) {
        return ContentDialog(
          title: Text(chartData['title']?['text'] ?? '详情'),
          content: Container(
            height: 400,
            width: 600,
            color: Colors.white,
            child: const Center(
              child: Text(
                '在此处挂载完整的 WebView\n使用 echarts_flutter 透传 option 渲染真实图表\n(支持双轴/混合/冷门图表)',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          actions: [
            Button(
              child: const Text('关闭'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_chartList.isEmpty) {
      return const Center(child: ProgressRing());
    }

    return ScaffoldPage(
      header: const PageHeader(title: Text('图表画廊 (Gallery)')),
      content: Padding(
        padding: const EdgeInsets.all(24.0),
        child: MasonryGridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          itemCount: _chartList.length,
          itemBuilder: (context, index) {
            final chartData = _chartList[index];
            return SizedBox(
              height: 250, // 瀑布流可设定不同高度
              child: _buildLazyChartCard(chartData),
            );
          },
        ),
      ),
    );
  }
}
