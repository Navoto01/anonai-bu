import 'package:flutter/material.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'settings_manager.dart';
import 'push_effect_button.dart';

class LanguageSelectorPage extends StatefulWidget {
  final Locale currentLocale;
  final Function(Locale) onLanguageChanged;

  const LanguageSelectorPage({
    super.key,
    required this.currentLocale,
    required this.onLanguageChanged,
  });

  @override
  State<LanguageSelectorPage> createState() => _LanguageSelectorPageState();
}

class _LanguageSelectorPageState extends State<LanguageSelectorPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> _filteredLanguages = [];

  final List<Map<String, dynamic>> _allLanguages = [
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'hu', 'name': 'Magyar', 'flag': '🇭🇺'},
    {'code': 'zh', 'name': '中文', 'flag': '🇨🇳'},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'ro', 'name': 'Moldovenească', 'flag': '🇷🇴'},
    {'code': 'iw', 'name': 'עברית (ישראל)', 'flag': '🇮🇱'},
    {'code': 'ka', 'name': 'Anon', 'flag': '🤫'},
  ];

  Locale? _selectedLocale;

  @override
  void initState() {
    super.initState();
    _filteredLanguages = List.from(_allLanguages);
    _searchController.addListener(_filterLanguages);
    _selectedLocale =
        widget.currentLocale; // Initialize with the current locale
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterLanguages);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _filterLanguages() {
    final query = _searchController.text.toLowerCase().trim();

    setState(() {
      if (query.isEmpty) {
        _filteredLanguages = List.from(_allLanguages);
      } else {
        _filteredLanguages =
            _allLanguages.where((language) {
              final name = (language['name'] as String).toLowerCase();
              final code = (language['code'] as String).toLowerCase();
              return name.contains(query) || code.contains(query);
            }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsManager();
    final isDark = settings.isDarkMode;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppLocalizations.of(context)!.setupChooseLanguage,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'SFProDisplay',
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search input section
            Container(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                decoration: ShapeDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  shape: SmoothRectangleBorder(
                    borderRadius: SmoothBorderRadius(
                      cornerRadius: 50, // Fully rounded
                      cornerSmoothing: 0.6,
                    ),
                  ),
                  shadows: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 16,
                    fontFamily: 'SFProDisplay',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search languages...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontSize: 16,
                      fontFamily: 'SFProDisplay',
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 20, right: 16),
                      child: Icon(
                        Icons.search,
                        color: isDark ? Colors.white54 : Colors.black54,
                        size: 20,
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ),

            // Languages list
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: ClipSmoothRect(
                  radius: SmoothBorderRadius(
                    cornerRadius: 20,
                    cornerSmoothing: 0.6,
                  ),
                  child: Container(
                    decoration: ShapeDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      shape: SmoothRectangleBorder(
                        borderRadius: SmoothBorderRadius(
                          cornerRadius: 20,
                          cornerSmoothing: 0.6,
                        ),
                      ),
                      shadows: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child:
                        _filteredLanguages.isEmpty
                            ? _buildEmptyState(isDark)
                            : ListView.separated(
                              padding: const EdgeInsets.all(8.0),
                              itemCount: _filteredLanguages.length,
                              separatorBuilder:
                                  (context, index) => Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                    ),
                                    height: 1,
                                    color:
                                        isDark
                                            ? const Color(0xFF2C2C2C)
                                            : const Color(0xFFE0E0E0),
                                  ),
                              itemBuilder: (context, index) {
                                final language = _filteredLanguages[index];
                                final isSelected =
                                    _selectedLocale?.languageCode ==
                                    language['code'];

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 4.0,
                                  ),
                                  child: PushEffectButton(
                                    onPressed: () async {
                                      final newLocale = Locale(
                                        language['code']!,
                                        '',
                                      );

                                      // Apply the language change
                                      widget.onLanguageChanged(newLocale);
                                      await SettingsManager().setLocale(
                                        newLocale,
                                      );

                                      // Update the local state to reflect the new selection
                                      setState(() {
                                        _selectedLocale = newLocale;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      padding: const EdgeInsets.all(16),
                                      decoration: ShapeDecoration(
                                        color:
                                            isSelected
                                                ? const Color(
                                                  0xFF00A9FF,
                                                ).withOpacity(0.1)
                                                : Colors.transparent,
                                        shape: SmoothRectangleBorder(
                                          borderRadius: SmoothBorderRadius(
                                            cornerRadius: 12,
                                            cornerSmoothing: 0.6,
                                          ),
                                          side:
                                              isSelected
                                                  ? const BorderSide(
                                                    color: Color(0xFF00A9FF),
                                                    width: 2,
                                                  )
                                                  : BorderSide.none,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            language['flag']!,
                                            style: const TextStyle(
                                              fontSize: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Directionality(
                                              textDirection:
                                                  TextDirection
                                                      .ltr, // Force LTR for consistent visuals
                                              child: Text(
                                                language['name']!,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight:
                                                      isSelected
                                                          ? FontWeight.w600
                                                          : FontWeight.normal,
                                                  color:
                                                      isSelected
                                                          ? const Color(
                                                            0xFF00A9FF,
                                                          )
                                                          : (isDark
                                                              ? Colors.white
                                                              : Colors.black),
                                                  fontFamily: 'SFProDisplay',
                                                ),
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
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            const SizedBox(height: 16),
            Text(
              'No languages found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black54,
                fontFamily: 'SFProDisplay',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black38,
                fontFamily: 'SFProDisplay',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
