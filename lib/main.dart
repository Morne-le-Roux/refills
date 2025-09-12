import 'package:flutter/material.dart';
import 'package:refills/features/core/views/homescreen.dart';
import 'package:refills/features/core/setup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  Future<bool> _isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return !prefs.containsKey('volumeUnit');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: Colors.white,

      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        // Remove primarySwatch to avoid default blue/purple color
        // Use plain white for backgrounds
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0.5,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0.5,
        ),
      ),
      themeMode: ThemeMode.system, // Follows system setting
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<bool>(
        future: _isFirstLaunch(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.data! ? const SetupScreen() : const HomeScreen();
        },
      ),
    );
  }
}
