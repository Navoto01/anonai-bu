import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsManager extends ChangeNotifier {
  static final SettingsManager _instance = SettingsManager._internal();
  factory SettingsManager() => _instance;
  SettingsManager._internal();

  // Value notifier for efficient rebuilds without full app restart
  final ValueNotifier<bool> _rebuildNotifier = ValueNotifier<bool>(false);
  ValueNotifier<bool> get rebuildNotifier => _rebuildNotifier;

  // Settings values
  bool _isDarkMode = true;
  double _fontSize = 16.0;
  bool _animationsEnabled = true;
  bool _soundEnabled = true;
  Locale _locale = const Locale('en', '');
  bool _isProUser = false;
  double _bubbleRoundness = 18.0;
  double _cornerSmoothing = 1.0;
  bool _setupCompleted = false;

  // Getters
  bool get isDarkMode => _isDarkMode;
  double get fontSize => _fontSize;
  bool get animationsEnabled => _animationsEnabled;
  bool get soundEnabled => _soundEnabled;
  Locale get locale => _locale;
  bool get isProUser => _isProUser;
  double get bubbleRoundness => _bubbleRoundness;
  double get cornerSmoothing => _cornerSmoothing;
  bool get setupCompleted => _setupCompleted;

  // Initialize settings from SharedPreferences
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    _fontSize = prefs.getDouble('fontSize') ?? 16.0;
    _animationsEnabled = prefs.getBool('animationsEnabled') ?? true;
    _soundEnabled = prefs.getBool('soundEnabled') ?? true;

    final localeCode = prefs.getString('locale') ?? 'en';
    _locale = Locale(localeCode, '');

    _isProUser = prefs.getBool('isProUser') ?? false;
    _bubbleRoundness = prefs.getDouble('bubbleRoundness') ?? 18.0;
    _cornerSmoothing = prefs.getDouble('cornerSmoothing') ?? 1.0;
    _setupCompleted = prefs.getBool('setup_completed') ?? false;

    notifyListeners();
  }

  // Dark mode
  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    _rebuildNotifier.value = !_rebuildNotifier.value;
    notifyListeners();
  }

  // Font size
  Future<void> setFontSize(double value) async {
    _fontSize = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', value);
    _rebuildNotifier.value = !_rebuildNotifier.value;
  }

  // Animations
  Future<void> setAnimationsEnabled(bool value) async {
    _animationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('animationsEnabled', value);
    _rebuildNotifier.value = !_rebuildNotifier.value;
  }

  // Sound effects
  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundEnabled', value);
    _rebuildNotifier.value = !_rebuildNotifier.value;
  }

  // Locale
  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.languageCode);
    _rebuildNotifier.value = !_rebuildNotifier.value;
  }

  // Pro user status - now syncs with Firebase instead of just local storage
  Future<void> setProUser(bool value) async {
    _isProUser = value;
    // Still store locally for quick access, but Firebase is the source of truth
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isProUser', value);
    _rebuildNotifier.value = !_rebuildNotifier.value;
    notifyListeners();
  }

  // Setup completion
  Future<void> setSetupCompleted(bool value) async {
    _setupCompleted = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setup_completed', value);
    _rebuildNotifier.value = !_rebuildNotifier.value;
    notifyListeners();
  }

  // Bubble roundness
  Future<void> setBubbleRoundness(double value) async {
    _bubbleRoundness = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('bubbleRoundness', value);
    _rebuildNotifier.value = !_rebuildNotifier.value;
  }

  // Corner smoothing
  Future<void> setCornerSmoothing(double value) async {
    _cornerSmoothing = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('cornerSmoothing', value);
    _rebuildNotifier.value = !_rebuildNotifier.value;
  }
}
