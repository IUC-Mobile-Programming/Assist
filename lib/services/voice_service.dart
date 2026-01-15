import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isAvailable = false;
  bool _isInitialized = false;
  Function(String)? _statusHandler;
  Function(String)? _errorHandler;

  Future<bool> initialize({
    Function(String)? onStatus,
    Function(String)? onError,
  }) async {
    if (onStatus != null) {
      _statusHandler = onStatus;
    }
    if (onError != null) {
      _errorHandler = onError;
    }
    if (_isInitialized && _isAvailable) {
      return _isAvailable;
    }
    try {
      _isAvailable = await _speechToText.initialize(
        onError: (error) {
          _errorHandler?.call(error.toString());
          print('VoiceService error: $error');
        },
        onStatus: (status) {
          _statusHandler?.call(status);
          print('VoiceService status: $status');
        },
      );
      _isInitialized = _isAvailable;
    } catch (e) {
      print('Speech initialization failed (likely unsupported platform): $e');
      _isAvailable = false;
    }
    return _isAvailable;
  }

  Future<void> startListening({
    required Function(String) onResult,
    required Function(String) onStatus,
    Function(String)? onError,
  }) async {
    _statusHandler = onStatus;
    if (onError != null) {
      _errorHandler = onError;
    }
    final initialized = await initialize();
    if (!initialized) {
      onStatus('notAvailable'); // Notify UI that it's not available
      return;
    }

    try {
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
    } catch (e) {
      onStatus('error');
      onError?.call(e.toString());
    }
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
  }

  bool get isListening => _speechToText.isListening;
  bool get isAvailable => _isAvailable;
}
