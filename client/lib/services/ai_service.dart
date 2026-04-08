import 'dart:convert';
import 'package:dio/dio.dart';

/// 自定义图表解析异常
class ChartParseError implements Exception {
  final String message;
  ChartParseError(this.message);
  @override
  String toString() => "ChartParseError: $message";
}

/// AI 交互核心服务
class AIService {
  final Dio _dio;

  AIService() : _dio = Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    // 拦截器统一处理网络异常
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException e, handler) {
          // 在实际应用中可抛出特定的业务异常或使用 EventBus 发出 Toast 通知
          if (e.response?.statusCode == 401) {
            print("***接口请求失败: 未授权或 API Key 无效");
          } else if (e.response?.statusCode == 429) {
            print("***接口请求失败: 请求过于频繁 (Rate Limit)");
          } else if (e.type == DioExceptionType.connectionTimeout) {
            print("***接口请求失败: 请求超时");
          }
          return handler.next(e);
        },
      ),
    );
  }

  /// 动态拼接 System Prompt
  String _buildSystemPrompt() {
    return '''
你是一个资深的数据发掘与可视化专家。请根据用户提供的原始数据，从中筛选、清洗并进行多维度分析。
请生成尽可能多的、合适的 ECharts 图表来展示这些数据。
你必须只返回一个 JSON 数组，数组格式如下：
[
  {
    "title": { "text": "图表标题" },
    "tooltip": {},
    "legend": {},
    "xAxis": { "type": "category", "data": ["A", "B"] },
    "yAxis": { "type": "value" },
    "series": [
      { "type": "bar", "data": [10, 20] }
    ]
  }
]
不要包含任何其他解释性文本或 Markdown 标记。确保这是一个合法的 JSON 数组。
''';
  }

  /// 清洗 AI 返回的数据，尝试提取有效的 JSON 数组
  List<Map<String, dynamic>> _sanitizeAndParse(String responseText) {
    try {
      // 1. 尝试直接解析
      final directParse = jsonDecode(responseText);
      if (directParse is List) {
        return List<Map<String, dynamic>>.from(directParse);
      }
    } catch (_) {
      // 解析失败，走正则截取
    }

    // 2. 正则提取 ```json ... ``` 或直接提取 [ ... ]
    final RegExp regExp = RegExp(r'\[\s*\{.*\}\s*\]', dotAll: true);
    final match = regExp.firstMatch(responseText);

    if (match != null) {
      try {
        final extractedJson = match.group(0);
        final parsed = jsonDecode(extractedJson!);
        if (parsed is List) {
          return List<Map<String, dynamic>>.from(parsed);
        }
      } catch (e) {
        throw ChartParseError("提取到的 JSON 数组无法被解析: $e");
      }
    }

    throw ChartParseError("未能从 AI 的回复中找到合法的 JSON 数组结构。");
  }

  /// 请求第三方大模型生成批量图表
  Future<List<Map<String, dynamic>>> generateCharts(
    String inputData,
    String apiKey,
    String baseUrl,
    String modelName,
  ) async {
    final systemPrompt = _buildSystemPrompt();

    try {
      final response = await _dio.post(
        baseUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          "model": modelName,
          "messages": [
            {"role": "system", "content": systemPrompt},
            {"role": "user", "content": "这是我的数据，请帮我分析并生成图表：\n\n$inputData"},
          ],
          "temperature": 0.7,
        },
      );

      // 获取大模型的回答内容
      final String reply = response.data['choices'][0]['message']['content'];

      // 清洗并反序列化
      return _sanitizeAndParse(reply);
    } on DioException catch (e) {
      throw Exception("网络请求异常: ${e.message}");
    } catch (e) {
      if (e is ChartParseError) rethrow;
      throw Exception("未知错误: $e");
    }
  }

  /// 请求第三方大模型对特定图表进行洞察分析
  Future<String> analyzeChart(
    Map<String, dynamic> chartOption,
    String apiKey,
    String baseUrl,
    String modelName,
  ) async {
    // 剔除一些纯样式的冗余数据以节约 Token
    final cleanOption = Map<String, dynamic>.from(chartOption);
    cleanOption.remove('color');
    cleanOption.remove('backgroundColor');
    cleanOption.remove('animation');

    final optionJson = jsonEncode(cleanOption);

    final systemPrompt = '''
你是一个资深的数据分析师。请根据以下 ECharts 的配置（包含数据和图表结构），用中文为用户提供一份简短的洞察报告。
报告需要包含：
1. 数据的核心趋势或规律。
2. 异常值或值得注意的特征。
3. 一条针对业务决策或后续分析的建议。
请使用 Markdown 格式返回。
''';

    try {
      final response = await _dio.post(
        baseUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          "model": modelName,
          "messages": [
            {"role": "system", "content": systemPrompt},
            {"role": "user", "content": "这是图表数据，请分析：\n\n$optionJson"},
          ],
          "temperature": 0.5,
        },
      );

      final String reply = response.data['choices'][0]['message']['content'];
      return reply;
    } on DioException catch (e) {
      throw Exception("网络请求异常: ${e.message}");
    } catch (e) {
      throw Exception("分析异常: $e");
    }
  }
}
