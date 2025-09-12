import 'package:flutter/material.dart';
import 'package:refills/features/core/views/homescreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _volumeUnit = prefs.getString('volumeUnit') ?? _volumeUnit;
      _distanceUnit = prefs.getString('distanceUnit') ?? _distanceUnit;
      _currencySymbol = prefs.getString('currencySymbol') ?? _currencySymbol;
    });
  }

  String _volumeUnit = 'L';
  String _distanceUnit = 'km';

  String _currencySymbol = '\$'; // Default to $

  final List<String> volumeUnits = ['L', 'gal'];
  final List<String> distanceUnits = ['km', 'mi'];

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('volumeUnit', _volumeUnit);
    await prefs.setString('distanceUnit', _distanceUnit);
    await prefs.setString('currencySymbol', _currencySymbol);
  }

  void _onContinue() async {
    await _savePreferences();
    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? colorScheme.surface : Colors.white;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Setup',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        backgroundColor: bgColor,
        elevation: 0,
        foregroundColor: colorScheme.onSurface,
      ),
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Volume Unit'),
              Row(
                children: volumeUnits.map((unit) {
                  final bool selected = _volumeUnit == unit;
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  final selectedColor = selected
                      ? (isDark ? Colors.white : Colors.black)
                      : colorScheme.surface;
                  final selectedTextColor = selected
                      ? (isDark ? Colors.black : Colors.white)
                      : colorScheme.onSurface;
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: Material(
                        color: selectedColor,
                        borderRadius: BorderRadius.circular(24),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => setState(() => _volumeUnit = unit),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: selected
                                  ? null
                                  : Border.all(
                                      color: colorScheme.onSurface,
                                      width: 1,
                                    ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Center(
                              child: Text(
                                unit,
                                style: TextStyle(
                                  color: selectedTextColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Distance Unit'),
              Row(
                children: distanceUnits.map((unit) {
                  final bool selected = _distanceUnit == unit;
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  final selectedColor = selected
                      ? (isDark ? Colors.white : Colors.black)
                      : colorScheme.surface;
                  final selectedTextColor = selected
                      ? (isDark ? Colors.black : Colors.white)
                      : colorScheme.onSurface;
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: Material(
                        color: selectedColor,
                        borderRadius: BorderRadius.circular(24),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => setState(() => _distanceUnit = unit),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: selected
                                  ? null
                                  : Border.all(
                                      color: colorScheme.onSurface,
                                      width: 1,
                                    ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Center(
                              child: Text(
                                unit,
                                style: TextStyle(
                                  color: selectedTextColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Currency Symbol'),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outline, width: 1),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter currency symbol',
                  ),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
                  onChanged: (val) => setState(() => _currencySymbol = val),
                  controller: TextEditingController(text: _currencySymbol),
                ),
              ),
              const Spacer(),
              Center(
                child: SizedBox(
                  width: double.infinity,
                  child: Builder(
                    builder: (context) {
                      final isDark =
                          Theme.of(context).brightness == Brightness.dark;
                      final buttonColor = isDark ? Colors.white : Colors.black;
                      final textColor = isDark ? Colors.black : Colors.white;
                      return Material(
                        color: buttonColor,
                        borderRadius: BorderRadius.circular(24),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: _onContinue,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: Text(
                                'Continue',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
