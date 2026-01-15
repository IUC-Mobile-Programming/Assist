import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isAvailable = false;

  Future<bool> initialize() async {
    try {
      _isAvailable = await _speechToText.initialize(
        onError: (error) => print('VoiceService error: $error'),
        onStatus: (status) => print('VoiceService status: $status'),
      );
    } catch (e) {
      print('Speech initialization failed (likely unsupported platform): $e');
      _isAvailable = false;
    }
    return _isAvailable;
  }

  Future<void> startListening({
    required Function(String) onResult,
    required Function(String) onStatus,
  }) async {
    if (!_isAvailable) {
      final initialized = await initialize();
      if (!initialized) {
        onStatus('notAvailable'); // Notify UI that it's not available
        return;
      }
    }

    await _speechToText.listen(
      onResult: (result) {
        if (result.finalResult || result.recognizedWords.isNotEmpty) {
          onResult(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      partialResults: true,
      cancelOnError: true,
      listenMode: ListenMode.dictation,
    );
     // Listen for status changes implicitly via the initialize callback or we can check isListening
    onStatus('listening');
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
  }

  bool get isListening => _speechToText.isListening;
  bool get isAvailable => _isAvailable;
}
