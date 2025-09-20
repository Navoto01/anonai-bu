import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:io';
import 'settings_manager.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'push_effect_button.dart';
import 'package:lottie/lottie.dart';

class AppSetupScreen extends StatefulWidget {
  final VoidCallback onSetupComplete;

  const AppSetupScreen({super.key, required this.onSetupComplete});

  @override
  State<AppSetupScreen> createState() => _AppSetupScreenState();
}

class _AppSetupScreenState extends State<AppSetupScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _buttonMorphController;

  // Setup data
  late Locale _selectedLanguage;
  bool _isDarkMode = true;
  double _bubbleRoundness = 18.0;
  double _fontSize = 16.0;
  double _cornerSmoothing = 1.0;
  bool _animationsEnabled = true;
  bool _soundEnabled = true;
  bool _skipLogin = false;

  // Login variables
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _userIdFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  DatabaseReference? _dbRef;

  @override
  void initState() {
    super.initState();
    // Initialize with current settings
    _selectedLanguage = SettingsManager().locale;
    _isDarkMode = SettingsManager().isDarkMode;
    _fontSize = SettingsManager().fontSize;
    _animationsEnabled = SettingsManager().animationsEnabled;
    _soundEnabled = SettingsManager().soundEnabled;

    _pageController = PageController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _buttonMorphController = AnimationController(
      duration: const Duration(
        milliseconds: 300,
      ), // Match page transition duration
      vsync: this,
    );
    _fadeController.forward();
    _slideController.forward();

    // Initialize Firebase for login
    try {
      if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
        _dbRef = FirebaseDatabase.instance.ref('users');
      }
    } catch (e) {
      // Firebase initialization failed - login will use demo mode
    }

    // Listen to rebuild notifier for locale changes
    SettingsManager().rebuildNotifier.addListener(_rebuild);
  }

  void _rebuild() {
    // Rebuild the widget when settings change
    if (mounted) {
      setState(() {
        // Update local variables with current settings
        _selectedLanguage = SettingsManager().locale;
        _isDarkMode = SettingsManager().isDarkMode;
        _fontSize = SettingsManager().fontSize;
      });
    }
  }

  @override
  void dispose() {
    // Remove listener
    SettingsManager().rebuildNotifier.removeListener(_rebuild);

    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _buttonMorphController.dispose();
    _userIdController.dispose();
    _passwordController.dispose();
    _userIdFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 5) {
      // Special handling for account setup page (page 4)
      if (_currentPage == 4) {
        // If on account setup page, skip to completion page (page 5) with animation
        _pageController.animateToPage(
          5,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        return;
      }

      // Start button morph animation immediately with page transition
      if (_currentPage == 0) {
        _buttonMorphController.forward();
      }

      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      // Special handling for completion page (page 5)
      if (_currentPage == 5) {
        // If on completion page, go back to account setup page (page 4) with animation
        _pageController.animateToPage(
          4,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        return;
      }

      // Reset button morph animation when going back to first page
      if (_currentPage == 1) {
        _buttonMorphController.reverse();
      }

      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeSetup() async {
    final settings = SettingsManager();

    // Save all settings
    await settings.setLocale(_selectedLanguage);
    await settings.setDarkMode(_isDarkMode);
    await settings.setFontSize(_fontSize);
    await settings.setAnimationsEnabled(_animationsEnabled);
    await settings.setSoundEnabled(_soundEnabled);

    // Mark setup as complete
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setup_completed', true);

    widget.onSetupComplete();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(),

            // Main content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics:
                    const NeverScrollableScrollPhysics(), // Disable swiping
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });

                  // No animations needed for All Set page - buttons stay as they are
                },
                children: [
                  _buildWelcomePage(),
                  _buildLanguagePage(),
                  _buildThemePage(),
                  _buildCustomizationPage(),
                  _buildLoginPage(),
                  _buildCompletionPage(),
                ],
              ),
            ),

            // Navigation buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: List.generate(6, (index) {
          final isActive = index <= _currentPage;
          final isCompleted = index < _currentPage;

          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 5 ? 8 : 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: SmoothBorderRadius(
                    cornerRadius: 2,
                    cornerSmoothing: 0.6,
                  ),
                  color:
                      isCompleted
                          ? const Color(0xFF00A9FF)
                          : isActive
                          ? const Color(0xFF00A9FF).withOpacity(0.6)
                          : (_isDarkMode
                              ? const Color(0xFF2C2C2C)
                              : const Color(0xFFE0E0E0)),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return FadeTransition(
      opacity: _fadeController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Icon
              ClipSmoothRect(
                radius: SmoothBorderRadius(
                  cornerRadius: 30,
                  cornerSmoothing: 0.6,
                ),
                child: Container(
                  width: 120,
                  height: 120,
                  child: Image.asset(
                    'assets/appicon.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Welcome Title
              Text(
                AppLocalizations.of(
                  context,
                )!.setupWelcomeTitle, // Changed from appTitle
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: _isDarkMode ? Colors.white : const Color(0xFF1A1A1A),
                  fontFamily: 'SFProDisplay',
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Welcome Subtitle
              Text(
                AppLocalizations.of(
                  context,
                )!.setupWelcomeSubtitle, // Changed from setupPersonalizedDesc
                style: TextStyle(
                  fontSize: 18,
                  color: _isDarkMode ? Colors.white70 : const Color(0xFF666666),
                  fontFamily: 'SFProDisplay',
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Features List
              Column(
                children: [
                  _buildFeatureItem(
                    Icons.language,
                    AppLocalizations.of(context)!.setupMultipleLanguages,
                  ),
                  _buildFeatureItem(
                    Icons.palette,
                    AppLocalizations.of(context)!.setupCustomizableThemes,
                  ),
                  _buildFeatureItem(
                    Icons.tune,
                    AppLocalizations.of(context)!.setupPersonalizedExperience,
                  ),
                  _buildFeatureItem(
                    Icons.security,
                    AppLocalizations.of(context)!.setupPrivacyFocused,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          ClipSmoothRect(
            radius: SmoothBorderRadius(cornerRadius: 10, cornerSmoothing: 0.6),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF00A9FF).withOpacity(0.1),
              ),
              child: Icon(icon, color: const Color(0xFF00A9FF), size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: _isDarkMode ? Colors.white : const Color(0xFF1A1A1A),
              fontFamily: 'SFProDisplay',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagePage() {
    final languages = [
      {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
      {'code': 'hu', 'name': 'Magyar', 'flag': '🇭🇺'},
      {'code': 'zh', 'name': '中文', 'flag': '🇨🇳'},
      {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
      {'code': 'ro', 'name': 'Moldovenească', 'flag': '🇷🇴'},
      {'code': 'iw', 'name': 'עברית (ישראל)', 'flag': '🇮🇱'},
      {'code': 'ka', 'name': 'Anon', 'flag': '🤫'},
    ];

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          Text(
            AppLocalizations.of(
              context,
            )!.setupChooseLanguage, // Changed from chooseLanguageTitle
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : const Color(0xFF1A1A1A),
              fontFamily: 'SFProDisplay',
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            AppLocalizations.of(
              context,
            )!.setupChooseLanguageDesc, // Changed from chooseLanguageSubtitle
            style: TextStyle(
              fontSize: 16,
              color: _isDarkMode ? Colors.white70 : const Color(0xFF666666),
              fontFamily: 'SFProDisplay',
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          Expanded(
            child: ListView.builder(
              itemCount: languages.length,
              itemBuilder: (context, index) {
                final language = languages[index];
                final isSelected =
                    _selectedLanguage.languageCode == language['code'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: PushEffectButton(
                    onPressed: () async {
                      final newLocale = Locale(language['code']!, '');
                      setState(() {
                        _selectedLanguage = newLocale;
                      });
                      // Apply language immediately
                      await SettingsManager().setLocale(newLocale);
                      // Notify the rebuild notifier to trigger UI update
                      SettingsManager().rebuildNotifier.value =
                          !SettingsManager().rebuildNotifier.value;
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? const Color(0xFF00A9FF).withOpacity(0.1)
                                : (_isDarkMode
                                    ? const Color(0xFF1E1E1E)
                                    : Colors.white),
                        borderRadius: SmoothBorderRadius(
                          cornerRadius: 16,
                          cornerSmoothing: 0.6,
                        ),
                        border: Border.all(
                          color:
                              isSelected
                                  ? const Color(0xFF00A9FF)
                                  : (_isDarkMode
                                      ? const Color(0xFF2C2C2C)
                                      : const Color(0xFFE0E0E0)),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            language['flag']!,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              language['name']!,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                color:
                                    _isDarkMode
                                        ? Colors.white
                                        : const Color(0xFF1A1A1A),
                                fontFamily: 'SFProDisplay',
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF00A9FF),
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemePage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context)!.setupChooseTheme,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : const Color(0xFF1A1A1A),
              fontFamily: 'SFProDisplay',
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            AppLocalizations.of(context)!.setupChooseThemeDesc,
            style: TextStyle(
              fontSize: 16,
              color: _isDarkMode ? Colors.white70 : const Color(0xFF666666),
              fontFamily: 'SFProDisplay',
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          Expanded(
            child: Column(
              children: [
                // Dark Theme Option
                _buildThemeOption(
                  title: AppLocalizations.of(context)!.setupDarkTheme,
                  subtitle: AppLocalizations.of(context)!.setupDarkThemeDesc,
                  isDark: true,
                  isSelected: _isDarkMode,
                  onTap: () async {
                    setState(() {
                      _isDarkMode = true;
                    });
                    // Save theme setting immediately
                    await SettingsManager().setDarkMode(true);
                  },
                ),

                const SizedBox(height: 20),

                // Light Theme Option
                _buildThemeOption(
                  title: AppLocalizations.of(context)!.setupLightTheme,
                  subtitle: AppLocalizations.of(context)!.setupLightThemeDesc,
                  isDark: false,
                  isSelected: !_isDarkMode,
                  onTap: () async {
                    setState(() {
                      _isDarkMode = false;
                    });
                    // Save theme setting immediately
                    await SettingsManager().setDarkMode(false);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required String title,
    required String subtitle,
    required bool isDark,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return PushEffectButton(
      onPressed: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? const Color(0xFF00A9FF).withOpacity(0.1)
                  : (_isDarkMode ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: SmoothBorderRadius(
            cornerRadius: 20,
            cornerSmoothing: 0.6,
          ),
          border: Border.all(
            color:
                isSelected
                    ? const Color(0xFF00A9FF)
                    : (_isDarkMode
                        ? const Color(0xFF2C2C2C)
                        : const Color(0xFFE0E0E0)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Theme Preview
            Container(
              width: 80,
              height: 60,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF121212) : Colors.white,
                borderRadius: SmoothBorderRadius(
                  cornerRadius: 12,
                  cornerSmoothing: 0.6,
                ),
                border: Border.all(
                  color:
                      isDark
                          ? const Color(0xFF2C2C2C)
                          : const Color(0xFFE0E0E0),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? const Color(0xFF2C2C2C)
                                : const Color(0xFFE0E0E0),
                        borderRadius: SmoothBorderRadius(
                          cornerRadius: 2,
                          cornerSmoothing: 0.6,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A9FF),
                        borderRadius: SmoothBorderRadius(
                          cornerRadius: 6,
                          cornerSmoothing: 0.6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 20),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color:
                          _isDarkMode ? Colors.white : const Color(0xFF1A1A1A),
                      fontFamily: 'SFProDisplay',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          _isDarkMode
                              ? Colors.white70
                              : const Color(0xFF666666),
                      fontFamily: 'SFProDisplay',
                    ),
                  ),
                ],
              ),
            ),

            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF00A9FF),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomizationPage() {
    // Initialize with current settings values
    double _currentFontSize = _fontSize;
    double _currentBubbleRoundness = _bubbleRoundness;
    double _currentCornerSmoothing = _cornerSmoothing;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Text(
              AppLocalizations.of(context)!.setupCustomizeExperience,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : const Color(0xFF1A1A1A),
                fontFamily: 'SFProDisplay',
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            Text(
              AppLocalizations.of(context)!.setupCustomizeExperienceDesc,
              style: TextStyle(
                fontSize: 16,
                color: _isDarkMode ? Colors.white70 : const Color(0xFF666666),
                fontFamily: 'SFProDisplay',
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // Preview Section
            Container(
              width: double.infinity,
              decoration: ShapeDecoration(
                color:
                    _isDarkMode
                        ? const Color(0xFF1a1a1a)
                        : const Color(0xFFFFFFFF),
                shape: SmoothRectangleBorder(
                  borderRadius: SmoothBorderRadius(
                    cornerRadius: 16,
                    cornerSmoothing: 0.6,
                  ),
                ),
                shadows: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      AppLocalizations.of(context)!.setupCustomizeExperience,
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'SFProDisplay',
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // User message (right, blue)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14.0,
                                  vertical: 10.0,
                                ),
                                decoration: ShapeDecoration(
                                  color: Colors.blue,
                                  shape: SmoothRectangleBorder(
                                    borderRadius: SmoothBorderRadius.only(
                                      topLeft: SmoothRadius(
                                        cornerRadius: _currentBubbleRoundness,
                                        cornerSmoothing:
                                            _currentCornerSmoothing,
                                      ),
                                      bottomLeft: SmoothRadius(
                                        cornerRadius: _currentBubbleRoundness,
                                        cornerSmoothing:
                                            _currentCornerSmoothing,
                                      ),
                                      bottomRight: SmoothRadius(
                                        cornerRadius: _currentBubbleRoundness,
                                        cornerSmoothing:
                                            _currentCornerSmoothing,
                                      ),
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Hello! How are you today?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: _currentFontSize,
                                    fontFamily: 'SFProDisplay',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // AI message (left, white/dark)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14.0,
                                  vertical: 10.0,
                                ),
                                decoration: ShapeDecoration(
                                  color:
                                      _isDarkMode
                                          ? Colors.white
                                          : const Color(0xFFF0F0F0),
                                  shape: SmoothRectangleBorder(
                                    borderRadius: SmoothBorderRadius.only(
                                      topRight: SmoothRadius(
                                        cornerRadius: _currentBubbleRoundness,
                                        cornerSmoothing:
                                            _currentCornerSmoothing,
                                      ),
                                      bottomLeft: SmoothRadius(
                                        cornerRadius: _currentBubbleRoundness,
                                        cornerSmoothing:
                                            _currentCornerSmoothing,
                                      ),
                                      bottomRight: SmoothRadius(
                                        cornerRadius: _currentBubbleRoundness,
                                        cornerSmoothing:
                                            _currentCornerSmoothing,
                                      ),
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'I\'m doing great! Thanks for asking. How can I help you today?',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: _currentFontSize,
                                    fontFamily: 'SFProDisplay',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Font Settings Section
            Container(
              width: double.infinity,
              decoration: ShapeDecoration(
                color:
                    _isDarkMode
                        ? const Color(0xFF1a1a1a)
                        : const Color(0xFFFFFFFF),
                shape: SmoothRectangleBorder(
                  borderRadius: SmoothBorderRadius(
                    cornerRadius: 16,
                    cornerSmoothing: 0.6,
                  ),
                ),
                shadows: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      AppLocalizations.of(
                        context,
                      )!.fontSize, // Changed from hardcoded 'Font Settings'
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'SFProDisplay',
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: ShapeDecoration(
                                color: Colors.green.withValues(alpha: 0.2),
                                shape: SmoothRectangleBorder(
                                  borderRadius: SmoothBorderRadius(
                                    cornerRadius: 8,
                                    cornerSmoothing: 0.6,
                                  ),
                                ),
                              ),
                              child: const Icon(
                                Icons.text_fields,
                                color: Colors.green,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.fontSizeLabel, // Changed from hardcoded 'Font Size'
                                    style: TextStyle(
                                      color:
                                          _isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'SFProDisplay',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.fontSizeDesc, // Changed from hardcoded description
                                    style: TextStyle(
                                      color:
                                          _isDarkMode
                                              ? Colors.white.withValues(
                                                alpha: 0.6,
                                              )
                                              : Colors.black.withValues(
                                                alpha: 0.6,
                                              ),
                                      fontSize: 13,
                                      fontFamily: 'SFProDisplay',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${_currentFontSize.round()}px',
                              style: TextStyle(
                                color:
                                    _isDarkMode
                                        ? Colors.white.withValues(alpha: 0.8)
                                        : Colors.black.withValues(alpha: 0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'SFProDisplay',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        NeumorphicSlider(
                          value: _currentFontSize,
                          min: 12.0,
                          max: 24.0,
                          onChanged: (value) {
                            setState(() {
                              _currentFontSize = value;
                              _fontSize = value; // Update the main setting
                            });
                            // Apply immediately to settings
                            SettingsManager().setFontSize(value);
                          },
                          style: SliderStyle(
                            accent: Colors.blue,
                            variant: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Style Settings Section
            Container(
              width: double.infinity,
              decoration: ShapeDecoration(
                color:
                    _isDarkMode
                        ? const Color(0xFF1a1a1a)
                        : const Color(0xFFFFFFFF),
                shape: SmoothRectangleBorder(
                  borderRadius: SmoothBorderRadius(
                    cornerRadius: 16,
                    cornerSmoothing: 0.6,
                  ),
                ),
                shadows: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      AppLocalizations.of(
                        context,
                      )!.style, // Changed from hardcoded 'Style'
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'SFProDisplay',
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Bubble Roundness Setting
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: ShapeDecoration(
                                color: Colors.purple.withValues(alpha: 0.2),
                                shape: SmoothRectangleBorder(
                                  borderRadius: SmoothBorderRadius(
                                    cornerRadius: 8,
                                    cornerSmoothing: 0.6,
                                  ),
                                ),
                              ),
                              child: const Icon(
                                Icons.rounded_corner,
                                color: Colors.purple,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.bubbleRoundness, // Changed from hardcoded 'Message Bubble Roundness'
                                    style: TextStyle(
                                      color:
                                          _isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'SFProDisplay',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.bubbleRoundnessDesc, // Changed from hardcoded description
                                    style: TextStyle(
                                      color:
                                          _isDarkMode
                                              ? Colors.white.withValues(
                                                alpha: 0.6,
                                              )
                                              : Colors.black.withValues(
                                                alpha: 0.6,
                                              ),
                                      fontSize: 13,
                                      fontFamily: 'SFProDisplay',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${_currentBubbleRoundness.round()}',
                              style: TextStyle(
                                color:
                                    _isDarkMode
                                        ? Colors.white.withValues(alpha: 0.8)
                                        : Colors.black.withValues(alpha: 0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'SFProDisplay',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        NeumorphicSlider(
                          value: _currentBubbleRoundness,
                          min: 0.0,
                          max: 30.0,
                          onChanged: (value) {
                            setState(() {
                              _currentBubbleRoundness = value;
                              _bubbleRoundness =
                                  value; // Update the main setting
                            });
                            // Apply immediately to settings
                            SettingsManager().setBubbleRoundness(value);
                          },
                          style: SliderStyle(
                            accent: Colors.purple,
                            variant: Colors.purple,
                          ),
                        ),
                        const SizedBox(height: 30),
                        // Corner Smoothing Setting
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: ShapeDecoration(
                                color: Colors.orange.withValues(alpha: 0.2),
                                shape: SmoothRectangleBorder(
                                  borderRadius: SmoothBorderRadius(
                                    cornerRadius: 8,
                                    cornerSmoothing: 0.6,
                                  ),
                                ),
                              ),
                              child: const Icon(
                                Icons.auto_fix_high,
                                color: Colors.orange,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.cornerSmoothing, // Changed from hardcoded 'Corner Smoothing'
                                    style: TextStyle(
                                      color:
                                          _isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'SFProDisplay',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.cornerSmoothingDesc, // Changed from hardcoded description
                                    style: TextStyle(
                                      color:
                                          _isDarkMode
                                              ? Colors.white.withValues(
                                                alpha: 0.6,
                                              )
                                              : Colors.black.withValues(
                                                alpha: 0.6,
                                              ),
                                      fontSize: 13,
                                      fontFamily: 'SFProDisplay',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${(_currentCornerSmoothing * 10).round()}',
                              style: TextStyle(
                                color:
                                    _isDarkMode
                                        ? Colors.white.withValues(alpha: 0.8)
                                        : Colors.black.withValues(alpha: 0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'SFProDisplay',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        NeumorphicSlider(
                          value: _currentCornerSmoothing,
                          min: 0.0,
                          max: 1.0,
                          onChanged: (value) {
                            setState(() {
                              _currentCornerSmoothing = value;
                            });
                            // Apply immediately to settings
                            SettingsManager().setCornerSmoothing(value);
                          },
                          style: SliderStyle(
                            accent: Colors.orange,
                            variant: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Text(
              AppLocalizations.of(
                context,
              )!.setupAccountSetup, // Changed from hardcoded 'Account Setup'
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : const Color(0xFF1A1A1A),
                fontFamily: 'SFProDisplay',
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            Text(
              AppLocalizations.of(
                context,
              )!.setupAccountSetupDesc, // Changed from hardcoded description
              style: TextStyle(
                fontSize: 16,
                color: _isDarkMode ? Colors.white70 : const Color(0xFF666666),
                fontFamily: 'SFProDisplay',
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // Error message
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: SmoothBorderRadius(
                    cornerRadius: 12,
                    cornerSmoothing: 0.6,
                  ),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 14,
                    fontFamily: 'SFProDisplay',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // User ID field
            _buildTextField(
              controller: _userIdController,
              focusNode: _userIdFocusNode,
              label:
                  AppLocalizations.of(
                    context,
                  )!.userIdLabel, // Changed from hardcoded 'AnonID'
              hint:
                  AppLocalizations.of(
                    context,
                  )!.userIdHint, // Changed from hardcoded 'Enter your AnonID'
              isDark: _isDarkMode,
              onSubmitted: (_) => _passwordFocusNode.requestFocus(),
            ),

            const SizedBox(height: 20),

            // Password field
            _buildTextField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              label:
                  AppLocalizations.of(
                    context,
                  )!.passwordLabel, // Changed from hardcoded 'Password'
              hint:
                  AppLocalizations.of(
                    context,
                  )!.passwordHint, // Changed from hardcoded 'Enter your password'
              isDark: _isDarkMode,
              isPassword: true,
              obscureText: _obscurePassword,
              onToggleObscure: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              onSubmitted: (_) => _login(),
            ),

            const SizedBox(height: 32),

            // Login button
            _buildLoginButton(_isDarkMode),

            const SizedBox(height: 16),

            // Skip button
            _buildSkipButton(_isDarkMode),

            const SizedBox(height: 32),

            // Benefits
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color:
                    _isDarkMode
                        ? const Color(0xFF1E1E1E)
                        : const Color(0xFFF8F9FA),
                borderRadius: SmoothBorderRadius(
                  cornerRadius: 16,
                  cornerSmoothing: 0.6,
                ),
                border: Border.all(
                  color:
                      _isDarkMode
                          ? const Color(0xFF2C2C2C)
                          : const Color(0xFFE0E0E0),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.setupBenefitsTitle, // Changed from hardcoded 'Benefits of signing in:'
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color:
                          _isDarkMode ? Colors.white : const Color(0xFF1A1A1A),
                      fontFamily: 'SFProDisplay',
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildBenefitItem(
                    Icons.sync,
                    AppLocalizations.of(context)!.setupSyncAcrossDevices,
                  ), // Changed from hardcoded 'Sync across devices'
                  _buildBenefitItem(
                    Icons.backup,
                    AppLocalizations.of(context)!.setupBackupData,
                  ), // Changed from hardcoded 'Backup your data'
                  _buildBenefitItem(
                    Icons.star,
                    AppLocalizations.of(context)!.setupAccessPremium,
                  ), // Changed from hardcoded 'Access premium features'
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF00A9FF)),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: _isDarkMode ? Colors.white70 : const Color(0xFF666666),
              fontFamily: 'SFProDisplay',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionPage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success Animation/Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF00C851).withOpacity(0.1),
                borderRadius: SmoothBorderRadius(
                  cornerRadius: 60,
                  cornerSmoothing: 0.6,
                ),
              ),
              child: Lottie.asset(
                'assets/lottie/Succesfull.json',
                repeat: false,
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(height: 40),

            Text(
              AppLocalizations.of(
                context,
              )!.setupAllSet, // Changed from hardcoded 'All Set!'
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : const Color(0xFF1A1A1A),
                fontFamily: 'SFProDisplay',
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            Text(
              AppLocalizations.of(
                context,
              )!.setupAllSetDesc, // Changed from hardcoded description
              style: TextStyle(
                fontSize: 16,
                color: _isDarkMode ? Colors.white70 : const Color(0xFF666666),
                fontFamily: 'SFProDisplay',
                height: 1,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 48),

            // Summary of selections
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color:
                    _isDarkMode
                        ? const Color(0xFF1E1E1E)
                        : const Color(0xFFF8F9FA),
                borderRadius: SmoothBorderRadius(
                  cornerRadius: 16,
                  cornerSmoothing: 0.6,
                ),
                border: Border.all(
                  color:
                      _isDarkMode
                          ? const Color(0xFF2C2C2C)
                          : const Color(0xFFE0E0E0),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.setupYourSetup, // Changed from hardcoded 'Your Setup:'
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color:
                          _isDarkMode ? Colors.white : const Color(0xFF1A1A1A),
                      fontFamily: 'SFProDisplay',
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryItem(
                    AppLocalizations.of(context)!.setupLanguageLabel,
                    _getLanguageName(_selectedLanguage.languageCode),
                  ), // Changed from hardcoded 'Language'
                  _buildSummaryItem(
                    AppLocalizations.of(context)!.setupThemeLabel,
                    _isDarkMode
                        ? AppLocalizations.of(context)!.setupDark
                        : AppLocalizations.of(context)!.setupLight,
                  ), // Changed from hardcoded 'Theme', 'Dark', 'Light'
                  _buildSummaryItem(
                    AppLocalizations.of(context)!.setupFontSizeLabel,
                    '${_fontSize.round()}sp',
                  ), // Changed from hardcoded 'Font Size'
                  _buildSummaryItem(
                    AppLocalizations.of(context)!.setupAccountLabel,
                    _isLoggedIn()
                        ? AppLocalizations.of(context)!.setupSignedIn
                        : AppLocalizations.of(context)!.setupNotSignedIn,
                  ), // Changed from hardcoded 'Account', 'Signed in', 'Not signed in'
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Enter AnonAI Button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00A9FF), Color(0xFF0080FF)],
                ),
                borderRadius: SmoothBorderRadius(
                  cornerRadius: 16,
                  cornerSmoothing: 0.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00A9FF).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: PushEffectButton(
                onPressed: _completeSetup,
                child: ElevatedButton(
                  onPressed: null, // Handled by PushEffectButton
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: SmoothBorderRadius(
                        cornerRadius: 16,
                        cornerSmoothing: 0.6,
                      ),
                    ),
                    disabledBackgroundColor:
                        Colors
                            .transparent, // Maintain transparency when disabled
                  ),
                  child: Text(
                    AppLocalizations.of(
                      context,
                    )!.setupEnterAnonAI, // Changed from hardcoded 'Enter AnonAI'
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'SFProDisplay',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: _isDarkMode ? Colors.white70 : const Color(0xFF666666),
              fontFamily: 'SFProDisplay',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _isDarkMode ? Colors.white : const Color(0xFF1A1A1A),
              fontFamily: 'SFProDisplay',
            ),
          ),
        ],
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'hu':
        return 'Magyar';
      case 'zh':
        return '中文';
      case 'de':
        return 'Deutsch';
      case 'ro':
        return 'Moldovai';
      case 'iw':
        return 'עברית (ישראל)';
      case 'ka':
        return 'Anon';
      default:
        return 'English';
    }
  }

  bool _isLoggedIn() {
    // Check if user is actually logged in
    // In a real implementation, this would check shared preferences
    // For now, we'll check if we have a user ID and haven't skipped login
    return !_skipLogin && _userIdController.text.trim().isNotEmpty;
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      height: 96, // Fixed height to prevent layout shifts
      child: Stack(
        children: [
          // Back Button - animate appearance with fixed position
          AnimatedBuilder(
            animation: _buttonMorphController,
            builder: (context, child) {
              // Show back button when page > 0 OR when animation is halfway through from page 0
              final shouldShowBack =
                  _currentPage > 0 ||
                  (_currentPage == 0 && _buttonMorphController.value > 0.3);

              return AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: shouldShowBack ? 0 : -200, // Slide in from left
                top: 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: shouldShowBack ? 1.0 : 0.0,
                  child: Container(
                    width:
                        (MediaQuery.of(context).size.width - 60) *
                        0.48, // 48% of available width for equal buttons
                    height: 48,
                    child: PushEffectButton(
                      onPressed: shouldShowBack ? _previousPage : null,
                      child: OutlinedButton(
                        onPressed: null, // Handled by PushEffectButton
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color:
                                _isDarkMode
                                    ? const Color(0xFF2C2C2C)
                                    : const Color(0xFFE0E0E0),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: SmoothBorderRadius(
                              cornerRadius: 16,
                              cornerSmoothing: 0.6,
                            ),
                          ),
                          disabledForegroundColor:
                              _isDarkMode
                                  ? Colors.white70
                                  : const Color(
                                    0xFF666666,
                                  ), // Maintain text color when disabled
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.setupBack,
                          style: TextStyle(
                            color:
                                _isDarkMode
                                    ? Colors.white70
                                    : const Color(0xFF666666),
                            fontFamily: 'SFProDisplay',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Continue/Skip Button - animate with fixed position
          if (_currentPage < 5)
            AnimatedBuilder(
              animation: _buttonMorphController,
              builder: (context, child) {
                // Calculate position and width for smooth animation
                final screenWidth =
                    MediaQuery.of(context).size.width - 48; // minus padding

                // Position calculation
                double leftPosition;
                double buttonWidth;

                if (_currentPage == 0) {
                  // Animate from full width to sharing space with back button
                  if (_buttonMorphController.value <= 0.3) {
                    // First phase: just shrink width, stay in center
                    leftPosition = 0;
                    buttonWidth = screenWidth;
                  } else {
                    // Second phase: move right and continue shrinking to equal width
                    final progress = (_buttonMorphController.value - 0.3) / 0.7;
                    final backButtonWidth =
                        (screenWidth - 12) * 0.48; // 48% width + 12px gap
                    leftPosition =
                        (backButtonWidth + 12) *
                        progress; // Move right with gap
                    buttonWidth =
                        screenWidth - (leftPosition); // Shrink to equal width
                  }
                } else {
                  // On other pages, stay in right position with equal width
                  final equalButtonWidth =
                      (screenWidth - 12) * 0.48; // 48% each + 12px gap
                  leftPosition =
                      equalButtonWidth + 12; // Right position with gap
                  buttonWidth = equalButtonWidth; // Equal width
                }

                // Determine if we should show "Skip" button (on account setup page)
                final isSkipButton = _currentPage == 4; // Account setup page

                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  left: leftPosition,
                  top: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: buttonWidth,
                    height: 48,
                    child: PushEffectButton(
                      onPressed: _nextPage,
                      child: ElevatedButton(
                        onPressed: null, // Handled by PushEffectButton
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isSkipButton
                                  ? Colors.grey[600] // Gray for skip button
                                  : const Color(
                                    0xFF00A9FF,
                                  ), // Blue for continue button
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: SmoothBorderRadius(
                              cornerRadius: 16,
                              cornerSmoothing: 0.6,
                            ),
                          ),
                          elevation: 0,
                          disabledBackgroundColor:
                              isSkipButton
                                  ? Colors.grey[600]
                                  : const Color(
                                    0xFF00A9FF,
                                  ), // Maintain color when disabled
                          disabledForegroundColor:
                              Colors.white, // Maintain white text when disabled
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.0, 0.3),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeInOut,
                                  ),
                                ),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            isSkipButton
                                ? AppLocalizations.of(context)!.setupSkipForNow
                                : (_buttonMorphController.value < 0.5
                                    ? AppLocalizations.of(
                                      context,
                                    )!.setupGetStarted
                                    : AppLocalizations.of(
                                      context,
                                    )!.setupContinue),
                            key: ValueKey(
                              isSkipButton
                                  ? 'skip'
                                  : (_buttonMorphController.value < 0.5
                                      ? 'get_started'
                                      : 'continue'),
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontFamily: 'SFProDisplay',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    if (_userIdController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'All fields are required';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final enteredUserId = _userIdController.text.trim();
      final enteredPassword = _passwordController.text.trim();

      // Check if we're on a desktop platform
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // For desktop platforms, use demo login
        if (enteredUserId.isNotEmpty && enteredPassword.isNotEmpty) {
          // Simulate network delay
          await Future.delayed(const Duration(milliseconds: 500));

          // Successful demo login
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('loggedInUserId', enteredUserId);

          setState(() {
            _skipLogin = false; // User logged in
          });

          if (mounted) {
            _nextPage(); // Continue to next setup page
          }
        } else {
          setState(() {
            _errorMessage = 'All fields are required';
          });
        }
      } else {
        // Mobile platforms - use Firebase authentication
        if (_dbRef == null) {
          throw Exception('Firebase not initialized on this platform');
        }
        final query = _dbRef!.orderByChild('userID').equalTo(enteredUserId);
        final snapshot = await query.get();

        if (snapshot.exists) {
          final userData = Map<String, dynamic>.from(
            (snapshot.value as Map).values.first as Map,
          );

          final storedPassword = userData['password'] as String?;

          if (storedPassword == enteredPassword) {
            // Successful login
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('isLoggedIn', true);
            await prefs.setString('loggedInUserId', enteredUserId);

            // Update pro status
            final isProUser = userData['anonlabpro'] == true;
            await SettingsManager().setProUser(isProUser);

            setState(() {
              _skipLogin = false; // User logged in
            });

            if (mounted) {
              _nextPage(); // Continue to next setup page
            }
          } else {
            setState(() {
              _errorMessage = 'Invalid AnonID or password';
            });
          }
        } else {
          setState(() {
            _errorMessage = 'User not found';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Login failed: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required bool isDark,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleObscure,
    Function(String)? onSubmitted,
  }) {
    return Container(
      decoration: ShapeDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: 16,
            cornerSmoothing: 0.6,
          ),
        ),
        shadows: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        onSubmitted: onSubmitted,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 16,
          fontFamily: 'SFProDisplay',
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontFamily: 'SFProDisplay',
          ),
          hintStyle: TextStyle(
            color: isDark ? Colors.grey[500] : Colors.grey[400],
            fontFamily: 'SFProDisplay',
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
          suffixIcon:
              isPassword
                  ? PushEffectButton(
                    onPressed: onToggleObscure,
                    child: IconButton(
                      onPressed: null, // Handled by PushEffectButton
                      icon: Icon(
                        obscureText ? Icons.visibility : Icons.visibility_off,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  )
                  : null,
        ),
      ),
    );
  }

  Widget _buildLoginButton(bool isDark) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: ShapeDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00A9FF), Color(0xFF0080FF)],
        ),
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: 16,
            cornerSmoothing: 0.6,
          ),
        ),
        shadows: [
          BoxShadow(
            color: const Color(0xFF00A9FF).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: PushEffectButton(
        onPressed: _isLoading ? null : _login,
        child: ElevatedButton(
          onPressed: null, // Handled by PushEffectButton
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: SmoothBorderRadius(
                cornerRadius: 16,
                cornerSmoothing: 0.6,
              ),
            ),
            disabledBackgroundColor:
                Colors.transparent, // Maintain transparency when disabled
          ),
          child:
              _isLoading
                  ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : Text(
                    AppLocalizations.of(
                      context,
                    )!.setupSignIn, // Changed from hardcoded 'Sign In'
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'SFProDisplay',
                    ),
                  ),
        ),
      ),
    );
  }

  Widget _buildSkipButton(bool isDark) {
    return PushEffectButton(
      onPressed: () {
        setState(() {
          _skipLogin = true;
        });
        _nextPage();
      },
      child: TextButton(
        onPressed: null, // Handled by PushEffectButton
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
        child: Text(
          AppLocalizations.of(
            context,
          )!.setupSkipForNow, // Changed from hardcoded 'Skip for now'
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white70 : const Color(0xFF666666),
            fontFamily: 'SFProDisplay',
          ),
        ),
      ),
    );
  }
}
