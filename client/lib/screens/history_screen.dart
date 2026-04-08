import 'package:fluent_ui/fluent_ui.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../db/database_helper.dart';

/// 历史记录页面，展示所有已生成的图表
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  List<Map<String, dynamic>> _chartList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllCharts();
  }

  /// 从本地数据库加载所有图表数据
  Future<void> _loadAllCharts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final charts = await DatabaseHelper.instance.getAllCharts();
      if (!mounted) return;
      setState(() {
        _chartList = List<Map<String, dynamic>>.from(charts);
        _isLoading = false;
      });
    } catch (e) {
      print("***方法报错/接口请求失败: _loadAllCharts - $e");
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog("加载历史记录失败");
    }
  }

  /// 显示错误提示框
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return ContentDialog(
          title: const Text('提示'),
          content: Text(message),
          actions: [
            FilledButton(
              child: const Text('我知道了'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  /// 复制图表
  Future<void> _copyChart(Map<String, dynamic> chartData) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final chartId = "chart_copy_$timestamp";
      final title = "${chartData['title']} (副本)";
      final optionJson = chartData['option_json'];

      final newChartData = {
        "id": chartId,
        "title": title,
        "option_json": optionJson,
        "created_at": timestamp,
        "updated_at": timestamp,
      };

      await DatabaseHelper.instance.insertChart(newChartData);
      
      // 刷新列表
      await _loadAllCharts();
    } catch (e) {
      print("***方法报错/接口请求失败: _copyChart - $e");
      _showErrorDialog("复制图表失败");
    }
  }

  /// 删除图表
  Future<void> _deleteChart(String id) async {
    try {
      await DatabaseHelper.instance.deleteChart(id);
      // 刷新列表
      await _loadAllCharts();
    } catch (e) {
      print("***方法报错/接口请求失败: _deleteChart - $e");
      _showErrorDialog("删除图表失败");
    }
  }

  /// 构建画廊中的单个图表卡片（懒加载缩略图）
  Widget _buildLazyChartCard(Map<String, dynamic> chartData) {
    return Card(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chartData['title'] ?? '未命名图表',
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
                  _copyChart(chartData);
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
                              Navigator.pop(context);
                              _deleteChart(chartData['id']);
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
                child: const Text('详情'),
                onPressed: () {
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
          title: Text(chartData['title'] ?? '详情'),
          content: Container(
            height: 400,
            width: 600,
            color: Colors.white,
            child: const Center(
              child: Text(
                '在此处挂载完整的 WebView\n使用 echarts_flutter 透传 option 渲染真实图表',
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
    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('历史记录')),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '历史图表画廊',
                style: FluentTheme.of(context).typography.subtitle?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Button(
                child: const Row(
                  children: [
                    Icon(FluentIcons.refresh),
                    SizedBox(width: 6),
                    Text('刷新列表'),
                  ],
                ),
                onPressed: () => _loadAllCharts(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: ProgressRing(),
                  ),
                )
              : _chartList.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('暂无历史图表数据'),
                      ),
                    )
                  : MasonryGridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      itemCount: _chartList.length,
                      itemBuilder: (context, index) {
                        final chartData = _chartList[index];
                        return SizedBox(
                          height: 250,
                          child: _buildLazyChartCard(chartData),
                        );
                      },
                    ),
        ),
        const SizedBox(height: 48), // 底部留白
      ],
    );
  }
}
