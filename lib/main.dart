import 'package:library_project/page/classify/classify_page.dart';

import 'utils/sql.dart';
import 'package:flutter/material.dart';
import 'page/home/home_page.dart';
import 'page/search/search_page.dart';


void main() async {
  runApp(const MyApp());
}

class GlobalThemData {
  static final Color _lightFocusColor = Colors.black.withOpacity(0.12);
  static final Color _darkFocusColor = Colors.white.withOpacity(0.12);

  static ThemeData lightThemeData =
      themeData(lightColorScheme, _lightFocusColor);
  static ThemeData darkThemeData = themeData(darkColorScheme, _darkFocusColor);

  static ThemeData themeData(ColorScheme colorScheme, Color focusColor) {
    return ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        canvasColor: colorScheme.surface,
        scaffoldBackgroundColor: colorScheme.surface,
        highlightColor: Colors.transparent,
        focusColor: focusColor);
  }

  static const ColorScheme lightColorScheme = ColorScheme(
    primary: Color(0xFFB93C5D),
    onPrimary: Colors.black,
    secondary: Color(0xFFEFF3F3),
    onSecondary: Color(0xFF322942),
    error: Colors.redAccent,
    onError: Colors.white,
    surface: Color(0xFFFAFBFB),
    onSurface: Color(0xFF241E30),
    brightness: Brightness.light,
  );

  static const ColorScheme darkColorScheme = ColorScheme(
    primary: Color(0xFFFF8383),
    secondary: Color(0xFF4D1F7C),
    surface: Color.fromARGB(255, 42, 33, 55), // 使用 surface 作为主要背景颜色
    error: Colors.redAccent,
    onError: Colors.white,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.white,
    brightness: Brightness.dark,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData =MediaQuery.of(context).platformBrightness == Brightness.dark
            ? GlobalThemData.darkThemeData
            : GlobalThemData.lightThemeData;
    return MaterialApp(
      theme: themeData,
      home: const MainWindow(),
    );
  }
}

class _MainWindowState extends State<MainWindow> {
  int _selectedIndex = 0;
  bool _isLoading = false;

  final List<Widget> _pages = const [
    HomePage(),
    ClassifyPage(),
    SearchPage()
  ];

  Future<void> _init() async {
    if (!_isLoading) {
      _isLoading = await Sql().init();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _init(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.done || _isLoading) {
          return Scaffold(
              appBar: AppBar(
                title: const Text('书库Pro版'),
              ),
              drawer: const Drawer(
                child: Center(
                  child: Column(
                    children: [
                    ],
                  ),
                ),
              ),
              body: _pages[_selectedIndex],
              bottomNavigationBar: BottomNavigationBar(
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: '主页',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.list_alt_sharp),
                    label: '分类',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.search),
                    label: '搜索',
                  ),
                ],
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
              ),
            );
        } else {
          return const Center(
            child: CircularProgressIndicator(
              backgroundColor: Color.fromARGB(255, 205, 198, 198),
            ),
          );
        }
      },
    );
  }
}

class MainWindow extends StatefulWidget {
  const MainWindow({super.key});

  @override
  State<MainWindow> createState() => _MainWindowState();
}
