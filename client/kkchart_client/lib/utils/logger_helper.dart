import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

class FileOutput extends LogOutput {
  final File file;

  FileOutput(this.file);

  @override
  void output(OutputEvent event) {
    for (var line in event.lines) {
      file.writeAsStringSync('${DateTime.now().toIso8601String()} - $line\n',
          mode: FileMode.append);
    }
  }
}

class AppLogger {
  static Logger? _logger;
  static File? _logFile;

  static Future<void> init() async {
    if (_logger != null) return;

    final dir = await getApplicationDocumentsDirectory();
    final logDir = Directory(p.join(dir.path, 'KKChart_Logs'));
    if (!await logDir.exists()) {
      await logDir.create();
    }

    final String today = DateTime.now().toIso8601String().split('T')[0];
    _logFile = File(p.join(logDir.path, 'app_$today.log'));

    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 5,
        lineLength: 80,
        colors: false, // 写入文件不需要 ANSI 颜色
        printEmojis: true,
        printTime: true,
      ),
      output: MultiOutput([
        ConsoleOutput(),
        FileOutput(_logFile!),
      ]),
    );
  }

  static void i(String message) {
    _logger?.i(message);
  }

  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger?.e(message, error: error, stackTrace: stackTrace);
  }

  static void w(String message) {
    _logger?.w(message);
  }
}
