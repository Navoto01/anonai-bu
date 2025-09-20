import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GroqService {
  static const String _groqBase = 'https://api.groq.com/openai/v1';

  final String _apiKey;
  http.Client? _client;

  GroqService(this._apiKey);

  Future<Stream<String>> streamChat({
    required String prompt,
    required List<Map<String, dynamic>> messages,
    String model = 'moonshotai/kimi-k2-instruct-0905',
    double temperature = 1.0,
    int maxTokens = 1024,
  }) async {
    _client?.close();
    _client = http.Client();

    final uri = Uri.parse('$_groqBase/chat/completions');
    final req =
        http.Request('POST', uri)
          ..headers.addAll({
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
            'Accept': 'text/event-stream',
          })
          ..body = jsonEncode({
            'model': model,
            'messages': messages,
            'temperature': temperature,
            'top_p': 1,
            'max_tokens': maxTokens,
            'stream': true,
          });

    final resp = await _client!.send(req);
    if (resp.statusCode != 200) {
      final err = await resp.stream.bytesToString();
      throw Exception('Groq ${resp.statusCode}: $err');
    }

    // SSE processing
    final controller = StreamController<String>();
    final lines = resp.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    void finish() {
      if (!controller.isClosed) controller.close();
      _client?.close();
      _client = null;
    }

    lines.listen(
      (line) {
        // SSE format: "data: {...}" or empty line
        if (!line.startsWith('data:')) return;
        final data = line.substring(5).trim();
        if (data == '[DONE]') {
          finish();
          return;
        }

        try {
          final Map<String, dynamic> json = jsonDecode(data);
          final choice = json['choices']?[0];

          // OpenAI stream: delta.content contains the chunk
          final delta = choice?['delta']?['content'];
          if (delta is String && delta.isNotEmpty) {
            controller.add(delta);
            return;
          }

          // Sometimes the first chunk contains message.content
          final msg = choice?['message']?['content'];
          if (msg is String && msg.isNotEmpty) {
            controller.add(msg);
          }
        } catch (_) {
          // If fragmented JSON comes, silently skip
        }
      },
      onError: (e, st) {
        controller.addError(e, st);
        finish();
      },
      onDone: () {
        finish();
      },
    );

    return controller.stream;
  }

  // TTS functionality using Groq's playai-tts model
  Future<List<int>> generateTTS({
    required String text,
    String model = 'playai-tts',
    String voice = 'Aaliyah-PlayAI',
    String responseFormat = 'mp3',
  }) async {
    _client?.close();
    _client = http.Client();

    final uri = Uri.parse('$_groqBase/audio/speech');

    try {
      final response = await _client!.post(
        uri,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': model,
          'voice': voice,
          'input': text,
          'response_format': responseFormat,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'TTS API Error ${response.statusCode}: ${response.body}',
        );
      }

      // Check if we actually received audio data
      if (response.bodyBytes.isEmpty) {
        throw Exception('Empty audio response from TTS API');
      }

      return response.bodyBytes;
    } finally {
      _client?.close();
      _client = null;
    }
  }

  void dispose() {
    _client?.close();
    _client = null;
  }
}
