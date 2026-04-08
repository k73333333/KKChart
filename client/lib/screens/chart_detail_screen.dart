import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_echarts/flutter_echarts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:pasteboard/pasteboard.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import '../services/ai_service.dart';
import '../db/database_helper.dart';

/// 图表详情与属性可视化编辑器
class ChartDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> initialChartData;

  const ChartDetailScreen({Key? key, required this.initialChartData})
    : super(key: key);

  @override
  ConsumerState<ChartDetailScreen> createState() => _ChartDetailScreenState();
}

class _ChartDetailScreenState extends ConsumerState<ChartDetailScreen> {
  late Map<String, dynamic> _currentOption;

  // 撤销/重做栈
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];

  // AI 洞察相关
  bool _isAnalyzing = false;
  String _insightMarkdown = "";

  late HotKey _undoHotKey;
  late HotKey _saveHotKey;

  final AIService _aiService = AIService();
  final GlobalKey _chartKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _currentOption = Map<String, dynamic>.from(widget.initialChartData);
    _saveToHistory();
    _registerHotkeys();
  }

  void _registerHotkeys() {
    _undoHotKey = HotKey(
      key: PhysicalKeyboardKey.keyZ,
      modifiers: [HotKeyModifier.control],
      scope: HotKeyScope.inapp,
    );
    _saveHotKey = HotKey(
      key: PhysicalKeyboardKey.keyS,
      modifiers: [HotKeyModifier.control],
      scope: HotKeyScope.inapp,
    );

    hotKeyManager.register(
      _undoHotKey,
      keyDownHandler: (hotKey) {
        if (_undoStack.length > 1) _undo();
      },
    );
    hotKeyManager.register(
      _saveHotKey,
      keyDownHandler: (hotKey) {
        print("触发手动保存");
        // TODO: 保存至云端或本地
      },
    );
  }

  @override
  void dispose() {
    hotKeyManager.unregister(_undoHotKey);
    hotKeyManager.unregister(_saveHotKey);
    super.dispose();
  }

  void _saveToHistory() {
    if (_undoStack.isEmpty || _undoStack.last != jsonEncode(_currentOption)) {
      _undoStack.add(jsonEncode(_currentOption));
      _redoStack.clear(); // 清空重做栈
    }
  }

  void _undo() {
    if (_undoStack.length > 1) {
      setState(() {
        _redoStack.add(_undoStack.removeLast());
        _currentOption = jsonDecode(_undoStack.last);
      });
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      setState(() {
        final optionStr = _redoStack.removeLast();
        _currentOption = jsonDecode(optionStr);
        _undoStack.add(optionStr);
      });
    }
  }

  /// 弹出 JSON 源码编辑器
  void _showJsonEditor() {
    final TextEditingController jsonController = TextEditingController(
      text: const JsonEncoder.withIndent('  ').convert(_currentOption),
    );
    String errorMessage = "";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return ContentDialog(
              title: const Text('JSON 源码编辑器'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 300,
                    child: TextBox(
                      controller: jsonController,
                      maxLines: null,
                      style: const TextStyle(fontFamily: 'Consolas'),
                    ),
                  ),
                  if (errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        errorMessage,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
              actions: [
                Button(
                  child: const Text('取消'),
                  onPressed: () => Navigator.pop(context),
                ),
                FilledButton(
                  child: const Text('应用'),
                  onPressed: () {
                    try {
                      final parsed = jsonDecode(jsonController.text);
                      if (parsed is Map<String, dynamic>) {
                        setState(() {
                          _currentOption = parsed;
                        });
                        _saveToHistory();
                        Navigator.pop(context);
                      } else {
                        setDialogState(() => errorMessage = "必须是有效的 JSON 对象");
                      }
                    } catch (e) {
                      setDialogState(() => errorMessage = "JSON 格式错误");
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 发起 AI 洞察请求
  Future<void> _analyzeChart() async {
    setState(() {
      _isAnalyzing = true;
      _insightMarkdown = "正在分析数据...";
    });

    try {
      final apiUrl =
          await DatabaseHelper.instance.getSetting('ai_api_url') ?? '';
      final apiKey =
          await DatabaseHelper.instance.getSetting('ai_api_key') ?? '';
      final modelName =
          await DatabaseHelper.instance.getSetting('ai_model_name') ?? '';

      if (apiUrl.isEmpty || apiKey.isEmpty) {
        setState(() {
          _insightMarkdown = "> 请先在设置中配置 AI 接口和密钥。";
        });
        return;
      }

      final insight = await _aiService.analyzeChart(
        _currentOption,
        apiKey,
        apiUrl,
        modelName,
      );

      setState(() {
        _insightMarkdown = insight;
      });
    } catch (e) {
      setState(() {
        _insightMarkdown = "> 分析失败：\n> $e";
      });
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  /// 构建左侧的动态配置表单 (基础通用属性)
  Widget _buildDynamicPropertiesPanel() {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      color: FluentTheme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('基础属性配置', style: FluentTheme.of(context).typography.subtitle),
          const SizedBox(height: 16),
          // 标题编辑
          InfoLabel(
            label: '图表标题',
            child: TextBox(
              controller: TextEditingController(
                text: _currentOption['title']?['text'] ?? '',
              ),
              onChanged: (value) {
                setState(() {
                  if (_currentOption['title'] == null)
                    _currentOption['title'] = {};
                  _currentOption['title']['text'] = value;
                });
                _saveToHistory();
              },
            ),
          ),
          const SizedBox(height: 16),
          // 图例开关
          ToggleSwitch(
            checked:
                _currentOption['legend'] != null &&
                _currentOption['legend']['show'] != false,
            onChanged: (v) {
              setState(() {
                if (_currentOption['legend'] == null)
                  _currentOption['legend'] = {};
                _currentOption['legend']['show'] = v;
              });
              _saveToHistory();
            },
            content: const Text('显示图例 (Legend)'),
          ),
          const SizedBox(height: 16),
          // 兜底的 JSON 源码编辑器入口
          Button(
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(FluentIcons.code),
                SizedBox(width: 8),
                Text('JSON 源码级微调 (高级)'),
              ],
            ),
            onPressed: _showJsonEditor,
          ),
        ],
      ),
    );
  }

  /// 构建右侧的 AI 洞察抽屉
  Widget _buildInsightsPanel() {
    return Container(
      width: 350,
      padding: const EdgeInsets.all(16),
      color: FluentTheme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI 深度分析',
                style: FluentTheme.of(context).typography.subtitle,
              ),
              FilledButton(
                onPressed: _isAnalyzing ? null : _analyzeChart,
                child: _isAnalyzing
                    ? const ProgressRing(strokeWidth: 2)
                    : const Text('重新分析'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _insightMarkdown.isEmpty
                ? const Center(
                    child: Text(
                      '点击右上角按钮获取图表洞察',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : Markdown(data: _insightMarkdown),
          ),
        ],
      ),
    );
  }

  /// 模拟导出 PPT/图片并给出反馈
  Future<void> _exportAction(String type) async {
    // 这里使用 RepaintBoundary 截图（注：部分桌面端 WebView 截图可能为空白，需依赖原生方案）
    try {
      RenderRepaintBoundary boundary =
          _chartKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        if (type == 'png') {
          await Pasteboard.writeImage(byteData.buffer.asUint8List());
        }

        showDialog(
          context: context,
          builder: (context) => ContentDialog(
            title: const Text('导出成功'),
            content: Text(
              '已成功导出为 $type 格式${type == 'png' ? '，并已复制到剪贴板。' : '。'}',
            ),
            actions: [
              FilledButton(
                child: const Text('确定'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => ContentDialog(
          title: const Text('导出失败'),
          content: Text('出现错误：$e'),
          actions: [
            FilledButton(
              child: const Text('关闭'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('图表详情与编辑'),
        commandBar: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(FluentIcons.undo),
              onPressed: _undoStack.length > 1 ? _undo : null,
            ),
            IconButton(
              icon: const Icon(FluentIcons.redo),
              onPressed: _redoStack.isNotEmpty ? _redo : null,
            ),
            const SizedBox(width: 16),
            Button(
              child: const Row(
                children: [
                  Icon(FluentIcons.download_document),
                  SizedBox(width: 8),
                  Text('导出 PPT'),
                ],
              ),
              onPressed: () => _exportAction('ppt'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              child: const Row(
                children: [
                  Icon(FluentIcons.photo2),
                  SizedBox(width: 8),
                  Text('导出 / 复制 PNG'),
                ],
              ),
              onPressed: () => _exportAction('png'),
            ),
          ],
        ),
      ),
      content: Row(
        children: [
          // 左侧属性表单
          _buildDynamicPropertiesPanel(),

          // 中央预览区 (ECharts 真实渲染)
          Expanded(
            child: RepaintBoundary(
              key: _chartKey,
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Echarts(
                    option: jsonEncode(_currentOption),
                    extraScript: '''
                      // 可以在这里注入 ECharts 主题或自定义的事件监听脚本
                    ''',
                  ),
                ),
              ),
            ),
          ),

          // 右侧 AI 洞察区域
          _buildInsightsPanel(),
        ],
      ),
    );
  }
}
