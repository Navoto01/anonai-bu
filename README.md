# AnonAI

A free, modern, limited AI ChatBot built with Flutter.

## Features

- Clean, modern chat interface
- Real-time AI responses using Groq API
- Multi-language support (English, Hungarian, Chinese Simplified, German)
- **Markdown formatting support** - AI responses support bold, italic, code blocks, lists, headers, and more
- **Independent chunk animations** - Each new token gets its own fade-in and blur animation that runs to completion without interruption
- Custom emoji font support
- Dark theme optimized for better user experience
- Cross-platform compatibility (Windows, Android, iOS)

## Internationalization

This app supports multiple languages using Flutter's built-in internationalization system:

### Supported Languages
- English (en) - Default
- Hungarian (hu)
- Chinese Simplified (zh)
- German (de)

### Adding New Languages

1. Create a new `.arb` file in `lib/l10n/` (e.g., `app_es.arb` for Spanish)
2. Copy the structure from `app_en.arb` and translate the strings
3. Add the new locale to the `supportedLocales` list in `main.dart`
4. Run `flutter gen-l10n` to generate the localization files

### Language Files Location
- Source files: `lib/l10n/app_*.arb`
- Generated files: `.dart_tool/flutter_gen/gen_l10n/`

## Setup

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Replace the API key in Firebase Remote Config with your Groq API key
4. Run `flutter gen-l10n` to generate localization files
5. Run the app with `flutter run`

## Usage

- Type messages in the input field and press send
- Use the language selector (🌐) in the app bar to switch between languages
- The AI will respond in real-time with streaming responses

**Note:** The system prompt sent to the AI is always in English regardless of the UI language. Only the user interface elements (buttons, labels, error messages) change based on the selected language.
