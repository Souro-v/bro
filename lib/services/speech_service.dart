import 'package:speech_to_text/speech_to_text.dart';

enum SpeechInitResult { ready, permissionDenied, unavailable }

class SpeechService {
  final SpeechToText _speech = SpeechToText();

  // Recognition language. Change it if you want (e.g. 'en_GB').
  static const String _localeId = 'en_US';

  /// Asks for mic permission (if needed) and prepares speech recognition.
  /// Safe to call every time the mic button is tapped.
  Future<SpeechInitResult> init({
    required void Function(String status) onStatus,
    required void Function(String errorMsg) onError,
  }) async {
    final ok = await _speech.initialize(
      onStatus: onStatus,
      onError: (error) => onError(error.errorMsg),
    );

    if (ok) return SpeechInitResult.ready;

    // Failed: was it the permission, or is recognition missing on this phone?
    final hasPermission = await _speech.hasPermission;
    return hasPermission
        ? SpeechInitResult.unavailable
        : SpeechInitResult.permissionDenied;
  }

  Future<void> start({
    required void Function(String text, bool isFinal) onText,
  }) {
    return _speech.listen(
      onResult: (result) => onText(result.recognizedWords, result.finalResult),
      localeId: _localeId,
      listenFor: const Duration(seconds: 30),
      // max total time
      pauseFor: const Duration(seconds: 3),
      // stop after 3s of silence
      listenOptions: SpeechListenOptions(
        partialResults: true, // show words while you speak
        cancelOnError: true,
      ),
    );
  }

  Future<void> stop() => _speech.stop();

  Future<void> cancel() => _speech.cancel();
}
