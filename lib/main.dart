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
      theme: ThemeData(scaffoldBackgroundColor: Colors.white),
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
