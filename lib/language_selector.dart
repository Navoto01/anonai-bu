import 'package:flutter/material.dart';

class LanguageSelector extends StatelessWidget {
  final Locale currentLocale;
  final Function(Locale) onLanguageChanged;

  const LanguageSelector({
    super.key,
    required this.currentLocale,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final languages = [
      {'locale': const Locale('en', ''), 'name': 'English', 'flag': '🇺🇸'},
      {'locale': const Locale('hu', ''), 'name': 'Magyar', 'flag': '🇭🇺'},
      {'locale': const Locale('zh', ''), 'name': '中文', 'flag': '🇨🇳'},
      {'locale': const Locale('de', ''), 'name': 'Deutsch', 'flag': '🇩🇪'},
      {'locale': const Locale('ro', ''), 'name': 'Moldovenească', 'flag': '��'},
      {
        'locale': const Locale('iw', ''),
        'name': 'עברית (ישראל)',
        'flag': '🇮🇱',
      },
    ];

    return IconButton(
      icon: const Icon(Icons.language),
      onPressed: () async {
        final selected = await showDialog<Locale>(
          context: context,
          builder: (context) {
            return Dialog(
              child: SizedBox(
                width: 320,
                height: 400,
                child: PageView.builder(
                  itemCount: (languages.length / 4.0).ceil(),
                  itemBuilder: (context, pageIndex) {
                    final start = pageIndex * 4;
                    final end = (start + 4).clamp(0, languages.length);
                    final pageLanguages = languages.sublist(start, end);
                    return ListView(
                      children: [
                        for (final lang in pageLanguages)
                          ListTile(
                            leading: Text(
                              lang['flag'] as String,
                              style: const TextStyle(fontSize: 22),
                            ),
                            title: Text(lang['name'] as String),
                            selected:
                                currentLocale.languageCode ==
                                (lang['locale'] as Locale).languageCode,
                            onTap:
                                () => Navigator.of(
                                  context,
                                ).pop(lang['locale'] as Locale),
                          ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        );
        if (selected != null) {
          onLanguageChanged(selected);
        }
      },
    );
  }
}
