import 'package:flutter/material.dart';


class EmojiTextWidget extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const EmojiTextWidget({
    super.key,
    required this.text,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: textAlign ?? TextAlign.start,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      text: _buildTextSpan(text, style),
    );
  }

  TextSpan _buildTextSpan(String text, TextStyle? baseStyle) {
    final List<TextSpan> spans = [];
    final characters = text.characters;
    
    String currentText = '';
    
    for (final char in characters) {
      if (_isEmoji(char)) {
        // Add any accumulated regular text first
        if (currentText.isNotEmpty) {
          spans.add(TextSpan(
            text: currentText,
            style: baseStyle?.copyWith(fontFamily: 'SFProDisplay'),
          ));
          currentText = '';
        }
        
        // Add emoji with custom font
        spans.add(TextSpan(
          text: char,
          style: (baseStyle ?? const TextStyle()).copyWith(
            fontFamily: 'AnonEmoji',
            fontFamilyFallback: ['SFProDisplay'],
          ),
        ));
      } else {
        currentText += char;
      }
    }
    
    // Add any remaining regular text
    if (currentText.isNotEmpty) {
      spans.add(TextSpan(
        text: currentText,
        style: baseStyle?.copyWith(fontFamily: 'SFProDisplay'),
      ));
    }
    
    return TextSpan(children: spans);
  }

  bool _isEmoji(String char) {
    final int codeUnit = char.codeUnitAt(0);
    
    // Common emoji ranges
    return (codeUnit >= 0x1F600 && codeUnit <= 0x1F64F) || // Emoticons
           (codeUnit >= 0x1F300 && codeUnit <= 0x1F5FF) || // Misc Symbols and Pictographs
           (codeUnit >= 0x1F680 && codeUnit <= 0x1F6FF) || // Transport and Map
           (codeUnit >= 0x1F1E0 && codeUnit <= 0x1F1FF) || // Regional indicators (flags)
           (codeUnit >= 0x2600 && codeUnit <= 0x26FF) ||   // Misc symbols
           (codeUnit >= 0x2700 && codeUnit <= 0x27BF) ||   // Dingbats
           (codeUnit >= 0xFE00 && codeUnit <= 0xFE0F) ||   // Variation Selectors
           (codeUnit >= 0x1F900 && codeUnit <= 0x1F9FF) || // Supplemental Symbols and Pictographs
           (codeUnit >= 0x1F018 && codeUnit <= 0x1F270) || // Various symbols
           char == '❤' || char == '💙' || char == '💚' || char == '💛' || char == '🧡' || char == '💜' ||
           char == '🖤' || char == '🤍' || char == '🤎' || char == '💔' || char == '❣' || char == '💕' ||
           char == '💖' || char == '💗' || char == '💘' || char == '💝' || char == '💞' || char == '💟';
  }
}