import 'package:fluent_ui/fluent_ui.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'screens/dashboard_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/history_screen.dart';
import 'utils/logger_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppLogger.init();
  AppLogger.i("KKChart 应用启动");

  // 初始化热键管理器
  await hotKeyManager.unregisterAll();

  // 必须加上这一行。
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1200, 800),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const ProviderScope(child: KKChartApp()));

  doWhenWindowReady(() {
    const initialSize = Size(1200, 800);
    appWindow.minSize = const Size(800, 600);
    appWindow.size = initialSize;
    appWindow.alignment = Alignment.center;
    appWindow.show();
  });
}

class KKChartApp extends ConsumerWidget {
  const KKChartApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FluentApp(
      title: 'KKChart',
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      color: Colors.blue,
      darkTheme: FluentThemeData(
        brightness: Brightness.dark,
        accentColor: Colors.blue,
        visualDensity: VisualDensity.standard,
        focusTheme: FocusThemeData(
          glowFactor: is10footScreen(context) ? 2.0 : 0.0,
        ),
      ),
      theme: FluentThemeData(
        accentColor: Colors.blue,
        visualDensity: VisualDensity.standard,
        focusTheme: FocusThemeData(
          glowFactor: is10footScreen(context) ? 2.0 : 0.0,
        ),
      ),
      home: const MainLayout(),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int topIndex = 0;

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      titleBar: TitleBar(
        title: const DragToMoveArea(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text('KKChart'),
          ),
        ),
        icon: const Center(child: Icon(FluentIcons.chart)),
        captionControls: const WindowButtons(),
      ),
      pane: NavigationPane(
        selected: topIndex,
        onChanged: (index) => setState(() => topIndex = index),
        displayMode: PaneDisplayMode.compact,
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.home),
            title: const Text('工作台'),
            body: const DashboardScreen(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.history),
            title: const Text('历史记录'),
            body: const HistoryScreen(),
          ),
        ],
        footerItems: [
          PaneItem(
            icon: const Icon(FluentIcons.settings),
            title: const Text('系统设置'),
            body: const SettingsScreen(),
          ),
        ],
      ),
    );
  }
}

class WindowButtons extends StatelessWidget {
  const WindowButtons({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final colors = WindowButtonColors(
      iconNormal: FluentTheme.of(context).typography.body?.color,
      mouseOver: FluentTheme.of(context).accentColor,
      mouseDown: FluentTheme.of(context).accentColor.dark,
      iconMouseOver: Colors.white,
      iconMouseDown: Colors.white,
    );
    final closeButtonColors = WindowButtonColors(
      mouseOver: const Color(0xFFD32F2F),
      mouseDown: const Color(0xFFB71C1C),
      iconNormal: FluentTheme.of(context).typography.body?.color,
      iconMouseOver: Colors.white,
    );
    return Row(
      children: [
        MinimizeWindowButton(colors: colors),
        MaximizeWindowButton(colors: colors),
        CloseWindowButton(colors: closeButtonColors),
      ],
    );
  }
}
