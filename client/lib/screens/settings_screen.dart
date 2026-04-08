import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../db/database_helper.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _apiUrlController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _modelNameController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    try {
      final apiUrl = await DatabaseHelper.instance.getSetting('ai_api_url') ?? '';
      final apiKey = await DatabaseHelper.instance.getSetting('ai_api_key') ?? '';
      final modelName =
          await DatabaseHelper.instance.getSetting('ai_model_name') ?? '';

      if (!mounted) return;
      setState(() {
        _apiUrlController.text = apiUrl;
        _apiKeyController.text = apiKey;
        _modelNameController.text = modelName;
        _isLoading = false;
      });
    } catch (e) {
      print("***方法报错/接口请求失败: _loadSettings - $e");
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      showDialog(
        context: context,
        builder: (context) {
          return ContentDialog(
            title: const Text('提示'),
            content: Text('加载配置失败: $e'),
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
  }

  void _saveSettings() async {
    try {
      await DatabaseHelper.instance.saveSetting(
        'ai_api_url',
        _apiUrlController.text,
      );
      await DatabaseHelper.instance.saveSetting(
        'ai_api_key',
        _apiKeyController.text,
      );
      await DatabaseHelper.instance.saveSetting(
        'ai_model_name',
        _modelNameController.text,
      );

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) {
          return ContentDialog(
            title: const Text('保存成功'),
            content: const Text('AI 配置已成功更新到本地存储。'),
            actions: [
              FilledButton(
                child: const Text('关闭'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print("***方法报错/接口请求失败: _saveSettings - $e");
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) {
          return ContentDialog(
            title: const Text('保存失败'),
            content: Text('配置保存失败: $e'),
            actions: [
              FilledButton(
                child: const Text('关闭'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        },
      );
    }
  }

  void _exportLogs() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logDir = Directory(p.join(dir.path, 'KKChart_Logs'));

      if (!logDir.existsSync()) {
        logDir.createSync(recursive: true);
        // 创建一个测试日志以防为空
        final testLog = File(p.join(logDir.path, 'app.log'));
        testLog.writeAsStringSync('KKChart 日志初始化...\n');
      }

      var encoder = ZipFileEncoder();
      // 将压缩包输出到用户的桌面方便获取
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile == null) return;

      final desktopPath = p.join(
        userProfile,
        'Desktop',
        'KKChart_Logs_Export.zip',
      );
      encoder.zipDirectory(logDir, filename: desktopPath);

      showDialog(
        context: context,
        builder: (context) {
          return ContentDialog(
            title: const Text('导出成功'),
            content: Text('日志压缩包已成功保存至桌面:\n$desktopPath'),
            actions: [
              FilledButton(
                child: const Text('关闭'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print("日志导出失败: $e");
      // 真实项目中应该弹窗提示错误
    }
  }

  void _feedback() async {
    // 1. 打包日志目录
    String attachmentPath = "";
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logDir = Directory(p.join(dir.path, 'KKChart_Logs'));
      if (logDir.existsSync()) {
        var encoder = ZipFileEncoder();
        final zipPath = p.join(dir.path, 'KKChart_Logs.zip');
        encoder.zipDirectory(logDir, filename: zipPath);
        attachmentPath = zipPath;
        print("日志打包成功: $zipPath");
      }
    } catch (e) {
      print("打包日志失败: $e");
    }

    // 2. 唤起邮箱
    // 注意：url_launcher 在 mailto 协议下挂载文件附件可能因客户端不同而受限。
    // 在后续开发中，若发现不支持，可引入 flutter_email_sender。
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'qiji777@yeah.net',
      query: 'subject=KKChart 使用反馈与问题报告', // 理想情况可附带 &attach=$attachmentPath
    );
    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        print("无法唤起邮件客户端");
      }
    } catch (e) {
      print("邮件拉起异常: $e");
    }
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    _apiKeyController.dispose();
    _modelNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: ProgressRing());
    }

    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('系统设置')),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI 接口配置 (脱机模式)',
                style: FluentTheme.of(context).typography.subtitle,
              ),
              const SizedBox(height: 16),
              InfoLabel(
                label: '第三方 AI API 地址 (Base URL)',
                child: TextBox(
                  controller: _apiUrlController,
                  placeholder: 'https://api.openai.com/v1/chat/completions',
                ),
              ),
              const SizedBox(height: 16),
              InfoLabel(
                label: 'API 密钥 (API Key)',
                child: TextBox(
                  controller: _apiKeyController,
                  placeholder: 'sk-...',
                  obscureText: true,
                ),
              ),
              const SizedBox(height: 16),
              InfoLabel(
                label: '自定义模型名称',
                child: TextBox(
                  controller: _modelNameController,
                  placeholder: 'gpt-3.5-turbo',
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(onPressed: _saveSettings, child: const Text('保存配置')),

              const SizedBox(height: 48),
              Text('关于与诊断', style: FluentTheme.of(context).typography.subtitle),
              const SizedBox(height: 16),
              Row(
                children: [
                  Button(onPressed: _exportLogs, child: const Text('一键导出日志')),
                  const SizedBox(width: 16),
                  Button(
                    onPressed: _feedback,
                    child: const Text('反馈问题 (拉起邮箱)'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '当前版本: 1.0.0 (Beta)',
                style: FluentTheme.of(context).typography.caption,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
