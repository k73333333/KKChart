import 'package:fluent_ui/fluent_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../db/database_helper.dart';

/// 统一的工作台页面，上方为数据输入与生成区，下方为图表画廊展示区
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final TextEditingController _textController = TextEditingController();
  String _statusMessage = "请在此输入自然语言或导入结构化数据...";
  bool _isLoading = false;

  // 画廊数据：模拟从 SQLite 或 AI 接口返回的图表配置列表
  List<Map<String, dynamic>> _chartList = [];

  /// 最大字符数限制
  static const int maxCharLength = 10000;

  /// 最大文件限制 5MB
  static const int maxFileSize = 5 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// 选择本地文件
  Future<void> _pickFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'md', 'csv', 'json'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);

        // 1. 校验文件大小
        if (await file.length() > maxFileSize) {
          _showErrorDialog("文件大小不能超过 5MB！");
          return;
        }

        // 2. 尝试以 UTF-8 读取文件内容
        try {
          String contents = await file.readAsString(encoding: utf8);

          if (contents.length > maxCharLength) {
            _showErrorDialog("解析内容超出 $maxCharLength 字符限制！");
            return;
          }

          setState(() {
            _textController.text = contents;
            _statusMessage = "已成功导入文件: ${result.files.single.name}";
          });
        } catch (e) {
          // 捕获编码错误或其他读取错误
          print("文件读取错误: $e");
          _showErrorDialog("文件读取失败，可能不是标准的 UTF-8 编码格式。请转换后重试！");
        }
      }
    } catch (e) {
      print("文件选择异常: $e");
    }
  }

  /// 显示错误提示框
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return ContentDialog(
          title: const Text('输入校验失败'),
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

  /// 提交并生成图表
  void _generateChart() async {
    String inputData = _textController.text.trim();
    if (inputData.isEmpty) {
      _showErrorDialog("请输入或导入需要分析的数据。");
      return;
    }

    if (inputData.length > maxCharLength) {
      _showErrorDialog("输入内容长度超出 10000 字符限制，请删减后重试。");
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = "AI 正在深度解析与筛选数据，请稍候...";
    });

    // TODO: 调用 AI 代理进行批量图表生成
    await Future.delayed(const Duration(seconds: 2));

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final chartId = "chart_new_$timestamp";
      final title = "新生成图表 ${DateTime.now().second}";
      final optionJson = jsonEncode({
        "title": {"text": title},
      }); // 模拟的 option_json

      // 组装数据库要求的数据结构
      final chartData = {
        "id": chartId,
        "title": title,
        "option_json": optionJson,
        "created_at": timestamp,
        "updated_at": timestamp,
      };

      // 保存至本地数据库
      await DatabaseHelper.instance.insertChart(chartData);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _statusMessage = "图表生成成功！(已保存至本地数据库)";
        // 清空当前列表，只展示最新生成的图表
        _chartList = [
          {
            "id": chartId,
            "title": {"text": title}, // UI 渲染需要这种结构
            "option_json": optionJson,
            "created_at": timestamp,
            "updated_at": timestamp,
          },
        ];
      });
    } catch (e) {
      print("***方法报错/接口请求失败: _generateChart - $e");
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _statusMessage = "图表生成或保存失败！";
      });
      _showErrorDialog("图表生成或保存失败，请稍后重试。");
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
                child: const Text('详情'),
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
      header: const PageHeader(title: Text('工作台')),
      children: [
        // ---------- 顶部：数据输入区域 ----------
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _statusMessage,
                style: TextStyle(
                  color: _isLoading ? Colors.orange : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // 文本输入区域
              TextBox(
                controller: _textController,
                maxLines: 10,
                placeholder:
                    '请粘贴您的业务数据，或者使用自然语言描述您想要分析的内容...\n支持的内容长度最大为 10000 个字符。',
                maxLength: maxCharLength,
              ),
              const SizedBox(height: 16),
              // 操作按钮组
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Button(
                    onPressed: _isLoading ? null : _pickFile,
                    child: const Row(
                      children: [
                        Icon(FluentIcons.fabric_folder),
                        SizedBox(width: 8),
                        Text('导入本地文件 (MD/TXT)'),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: _isLoading ? null : _generateChart,
                    child: _isLoading
                        ? const ProgressRing(strokeWidth: 2.0)
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(FluentIcons.edit),
                              SizedBox(width: 8),
                              Text('AI 一键生成图表'),
                            ],
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 24),

        // ---------- 底部：图表画廊展示区域 ----------
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '历史图表画廊',
                style: FluentTheme.of(
                  context,
                ).typography.subtitle?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: _chartList.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('当前暂无生成的图表'),
                  ),
                )
              : MasonryGridView.count(
                  shrinkWrap: true, // 必须设置 shrinkWrap 为 true
                  physics:
                      const NeverScrollableScrollPhysics(), // 禁用内部滚动，交给外部 ScaffoldPage 统一滚动
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  itemCount: _chartList.length,
                  itemBuilder: (context, index) {
                    final chartData = _chartList[index];
                    return SizedBox(
                      height: 250, // 指定高度以呈现瀑布流效果或统一高度
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
