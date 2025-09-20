# Design Document

## Overview

The Voice Mode feature will integrate seamlessly into the existing AnonAI Flutter application, providing users with an intuitive voice-based interaction system. The feature consists of two main components: an adaptive send button that transforms into a voice icon when appropriate, and a dedicated Voice Mode screen with real-time speech recognition, automatic silence detection, and professional animations.

The design leverages Flutter's existing architecture and maintains consistency with the current neumorphic design language while introducing modern voice interaction patterns.

## Architecture

### Component Structure

```
Voice Mode Feature
├── UI Components
│   ├── AdaptiveSendButton (Modified existing)
│   ├── VoiceModeScreen (New)
│   ├── VoiceVisualizerWidget (New)
│   └── VoiceControlButtons (New)
├── Services
│   ├── SpeechRecognitionService (New)
│   ├── VoiceStateManager (New)
│   └── GroqService (Modified existing)
└── Models
    ├── VoiceState (New)
    └── SpeechResult (New)
```

### State Management

The voice mode will use Flutter's built-in state management with StatefulWidget and will integrate with the existing message flow. Key states include:

- **Idle**: Ready to start listening
- **Listening**: Actively recording speech
- **Processing**: Converting speech to text
- **Responding**: AI is generating response
- **Paused**: User has paused the session
- **Error**: Handling speech recognition or API errors

## Components and Interfaces

### 1. AdaptiveSendButton

**Purpose**: Modify the existing send button to show voice icon when appropriate

**Interface**:
```dart
class AdaptiveSendButton extends StatefulWidget {
  final bool hasTextInput;
  final bool isAIResponding;
  final VoidCallback onSendPressed;
  final VoidCallback onVoicePressed;
  
  const AdaptiveSendButton({
    required this.hasTextInput,
    required this.isAIResponding,
    required this.onSendPressed,
    required this.onVoicePressed,
  });
}
```

**Behavior**:
- Shows microphone icon when `!hasTextInput && !isAIResponding`
- Shows send icon when `hasTextInput || isAIResponding`
- Smooth animated transitions between states
- Maintains existing neumorphic styling

### 2. VoiceModeScreen

**Purpose**: Full-screen voice interaction interface

**Interface**:
```dart
class VoiceModeScreen extends StatefulWidget {
  final Function(String) onMessageSent;
  
  const VoiceModeScreen({
    required this.onMessageSent,
  });
}
```

**Layout**:
- **Header**: "Voice Mode" title with modern typography
- **Center**: Large voice visualizer with animated waveforms/pulse
- **Status Area**: Current state indicator (Listening, Processing, etc.)
- **Response Area**: AI response display with typewriter animation
- **Bottom Controls**: Pause/Resume and Finish buttons

### 3. SpeechRecognitionService

**Purpose**: Handle speech-to-text conversion and silence detection

**Interface**:
```dart
class SpeechRecognitionService {
  Stream<SpeechResult> get speechStream;
  VoiceState get currentState;
  
  Future<void> startListening();
  Future<void> stopListening();
  Future<void> pauseListening();
  Future<void> resumeListening();
  void dispose();
}
```

**Key Features**:
- Continuous speech recognition
- 2-second silence detection
- English language focus
- Error handling and recovery
- Permission management

### 4. VoiceVisualizerWidget

**Purpose**: Provide visual feedback during voice interaction

**Interface**:
```dart
class VoiceVisualizerWidget extends StatefulWidget {
  final VoiceState state;
  final double audioLevel;
  
  const VoiceVisualizerWidget({
    required this.state,
    required this.audioLevel,
  });
}
```

**Visual States**:
- **Idle**: Subtle pulsing microphone icon
- **Listening**: Animated waveform responding to audio input
- **Processing**: Spinning/loading animation
- **Responding**: Gentle pulse while AI responds

## Data Models

### VoiceState Enum
```dart
enum VoiceState {
  idle,
  listening,
  processing,
  responding,
  paused,
  error,
}
```

### SpeechResult Model
```dart
class SpeechResult {
  final String text;
  final bool isFinal;
  final double confidence;
  final DateTime timestamp;
  
  const SpeechResult({
    required this.text,
    required this.isFinal,
    required this.confidence,
    required this.timestamp,
  });
}
```

### VoiceSession Model
```dart
class VoiceSession {
  final String sessionId;
  final DateTime startTime;
  final List<String> transcripts;
  final List<String> responses;
  
  const VoiceSession({
    required this.sessionId,
    required this.startTime,
    required this.transcripts,
    required this.responses,
  });
}
```

## Technical Implementation Details

### Speech Recognition Integration

**Dependencies Required**:
- `speech_to_text: ^6.6.0` - Primary speech recognition
- `permission_handler: ^11.0.1` - Microphone permissions

**Implementation Strategy**:
1. Initialize speech recognition service on app start
2. Request microphone permissions on first voice mode access
3. Use continuous recognition with silence detection
4. Implement fallback error handling for recognition failures

### Silence Detection Algorithm

```dart
class SilenceDetector {
  static const Duration silenceThreshold = Duration(seconds: 2);
  Timer? _silenceTimer;
  
  void onSpeechResult(SpeechResult result) {
    _silenceTimer?.cancel();
    
    if (result.isFinal) {
      _silenceTimer = Timer(silenceThreshold, () {
        _onSilenceDetected();
      });
    }
  }
  
  void _onSilenceDetected() {
    // Stop listening and process speech
  }
}
```

### Animation System

**Voice Visualizer Animations**:
- Use `AnimationController` with custom curves
- Implement real-time audio level visualization
- Smooth state transitions with `AnimatedSwitcher`
- Custom painting for waveform visualization

**Button Animations**:
- Morphing between send and microphone icons
- Haptic feedback on button presses
- Scale and color transitions for state changes

### Integration with Existing Chat System

**Message Flow Integration**:
1. Voice input captured and converted to text
2. Text sent through existing `_sendMessage()` method
3. AI response handled by existing streaming system
4. Response displayed in voice mode with text-to-speech option

**State Synchronization**:
- Voice mode state syncs with main chat state
- Messages appear in both voice mode and main chat
- Existing message history accessible in voice mode

## Error Handling

### Speech Recognition Errors
- **Permission Denied**: Show permission request dialog
- **Network Issues**: Retry with exponential backoff
- **Recognition Failure**: Provide manual text input fallback
- **Microphone Unavailable**: Show appropriate error message

### API Integration Errors
- **Groq AI Timeout**: Show retry option
- **Rate Limiting**: Implement queue system
- **Invalid Response**: Graceful error display

### Recovery Strategies
- Automatic retry for transient errors
- Manual retry buttons for user-initiated recovery
- Fallback to text input when voice fails
- Session persistence across errors

## Testing Strategy

### Unit Tests
- Speech recognition service functionality
- Silence detection algorithm accuracy
- State management transitions
- Error handling scenarios

### Integration Tests
- Voice mode screen navigation
- Speech-to-text-to-AI flow
- Button state transitions
- Permission handling

### User Experience Tests
- Voice recognition accuracy in various environments
- Animation smoothness and performance
- Battery usage during extended voice sessions
- Accessibility compliance

### Performance Tests
- Memory usage during continuous listening
- CPU usage during speech processing
- Network usage optimization
- Battery drain analysis

## Accessibility Considerations

### Voice Accessibility
- Visual indicators for deaf/hard-of-hearing users
- Text alternatives for all voice interactions
- Screen reader compatibility
- High contrast mode support

### Motor Accessibility
- Large touch targets for buttons
- Voice activation alternatives
- Gesture-based controls
- Switch control compatibility

## Security and Privacy

### Audio Data Handling
- No audio data stored locally
- Real-time processing only
- Secure transmission to speech services
- User consent for microphone access

### API Security
- Secure API key management
- Request encryption
- Rate limiting protection
- Error message sanitization

## Performance Optimization

### Memory Management
- Efficient audio buffer management
- Proper disposal of speech recognition resources
- Optimized animation controllers
- Garbage collection optimization

### Battery Optimization
- Intelligent microphone usage
- Background processing limitations
- Screen brightness management during voice mode
- CPU usage optimization

### Network Optimization
- Compressed audio transmission
- Request batching where possible
- Offline capability for basic functions
- Bandwidth usage monitoring