// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:she/features/device/presentation/pages/device_page.dart';
import 'package:she/features/history/presentation/pages/history_page.dart';
import 'package:she/features/home/presentation/pages/home_page.dart';
import 'package:toastification/toastification.dart';

// Project imports:
import 'package:she/config/theme/app_themes.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    initialization();
  }

  void initialization() async {
    await Future.delayed(const Duration(seconds: 2));
    FlutterNativeSplash.remove();
  }

  final List<Widget> _pages = const [HomePage(), HistoryPage(), DevicePage()];

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: MaterialApp(
        title: 'Smart Home Environment',
        theme: theme(),
        home: Scaffold(
          body: IndexedStack(index: _currentIndex, children: _pages),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
              child: BottomNavigationBar(
                backgroundColor: Colors.white,
                elevation: 0,
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });

                  HapticFeedback.lightImpact();
                },
                selectedItemColor: Colors.blue[700],
                unselectedItemColor: Colors.grey[400],
                selectedFontSize: 12,
                unselectedFontSize: 11,
                type: BottomNavigationBarType.fixed,
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
                unselectedLabelStyle: const TextStyle(height: 1.5),
                items: [
                  BottomNavigationBarItem(
                    icon: _buildNavIcon(Icons.home_outlined, 0),
                    activeIcon: _buildActiveNavIcon(Icons.home_rounded, 0),
                    label: 'Beranda',
                  ),
                  BottomNavigationBarItem(
                    icon: _buildNavIcon(Icons.history_outlined, 1),
                    activeIcon: _buildActiveNavIcon(Icons.history_rounded, 1),
                    label: 'Riwayat',
                  ),
                  BottomNavigationBarItem(
                    icon: _buildNavIcon(Icons.devices_outlined, 2),
                    activeIcon: _buildActiveNavIcon(Icons.devices_rounded, 2),
                    label: 'Perangkat',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Icon(icon, size: 26),
    );
  }

  Widget _buildActiveNavIcon(IconData icon, int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Icon(icon, size: 26, color: Colors.blue[700]),
    );
  }
}
