import 'package:fluent_ui/fluent_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 数据输入仪表盘，支持多行文本输入与文件拖拽/导入
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final TextEditingController _textController = TextEditingController();
  String _statusMessage = "请在此输入自然语言或导入结构化数据...";
  bool _isLoading = false;

  /// 最大字符数限制
  static const int maxCharLength = 10000;

  /// 最大文件限制 5MB
  static const int maxFileSize = 5 * 1024 * 1024;

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

    setState(() {
      _isLoading = false;
      _statusMessage = "图表生成成功！(模拟)";
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('新建图表分析')),
      children: [
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
                maxLines: 15,
                placeholder:
                    '请粘贴您的业务数据，或者使用自然语言描述您想要分析的内容...\n支持的内容长度最大为 10000 个字符。',
                maxLength: maxCharLength,
              ),
              const SizedBox(height: 24),
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
      ],
    );
  }
}
