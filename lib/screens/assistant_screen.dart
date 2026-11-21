import 'package:flutter/material.dart';

import '../assistant/command_handler.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';
import '../widget/mic_button.dart';

enum AssistantState { idle, listening, speaking }

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final SpeechService _speech = SpeechService();
  final TtsService _tts = TtsService();

  AssistantState _state = AssistantState.idle;
  String _userText = '';
  String _assistantText = '';
  String _errorText = '';

  @override
  void initState() {
    super.initState();
    _tts.init();
  }

  @override
  void dispose() {
    _speech.cancel();
    _tts.stop();
    super.dispose();
  }

  // ---------------- Button ----------------

  Future<void> _onMicPressed() async {
    switch (_state) {
      case AssistantState.idle:
        await _startListening();
      case AssistantState.listening:
        await _stopListening();
      case AssistantState.speaking:
        await _tts.stop();
        setState(() => _state = AssistantState.idle);
    }
  }

  // ---------------- Listening ----------------

  Future<void> _startListening() async {
    setState(() {
      _userText = '';
      _assistantText = '';
      _errorText = '';
    });

    try {
      final result = await _speech.init(onStatus: _onStatus, onError: _onError);

      if (result == SpeechInitResult.permissionDenied) {
        setState(
          () => _errorText = 'Microphone permission denied.\nAllow it in Settings > Apps > Hey Bro > Permissions.',
        );
        return;
      }
      if (result == SpeechInitResult.unavailable) {
        setState(
          () => _errorText = 'Speech recognition is not available on this phone.\nInstall or update the Google app and try again.',
        );
        return;
      }

      setState(() => _state = AssistantState.listening);
      await _speech.start(onText: _onSpeechText);
    } catch (e) {
      setState(() {
        _state = AssistantState.idle;
        _errorText = 'Something went wrong: $e';
      });
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    _finishListening(); // use whatever was recognized so far
  }

  // Called while you speak (partial results) and at the end (final result).
  void _onSpeechText(String text, bool isFinal) {
    if (_state != AssistantState.listening) return;
    setState(() => _userText = text);
    if (isFinal) _finishListening();
  }

  // The plugin reports 'listening', 'notListening' and 'done'.
  void _onStatus(String status) {
    if (status == 'done') _finishListening();
  }

  void _onError(String errorMsg) {
    if (_state != AssistantState.listening) return;

    // These two just mean "nothing was heard", not a real failure.
    final nothingHeard =
        errorMsg == 'error_no_match' || errorMsg == 'error_speech_timeout';

    setState(() {
      _state = AssistantState.idle;
      _errorText = nothingHeard
          ? "I didn't catch that. Tap the mic and try again."
          : 'Speech error: $errorMsg';
    });
  }

  // Safe to call more than once: only the first call does anything.
  void _finishListening() {
    if (_state != AssistantState.listening) return;

    final text = _userText.trim();
    if (text.isEmpty) {
      setState(() {
        _state = AssistantState.idle;
        _errorText = "I didn't hear anything. Tap the mic and try again.";
      });
      return;
    }

    _respond(text);
  }

  // ---------------- Responding ----------------

  Future<void> _respond(String text) async {
    final reply = CommandHandler.handle(text);

    setState(() {
      _assistantText = reply;
      _state = AssistantState.speaking;
    });

    await _tts.speak(reply);

    // Only go back to idle if the user hasn't already tapped the mic again.
    if (mounted && _state == AssistantState.speaking) {
      setState(() => _state = AssistantState.idle);
    }
  }

  // ---------------- UI ----------------

  String get _statusText => switch (_state) {
    AssistantState.idle => 'Tap the mic to talk',
    AssistantState.listening => 'Listening...',
    AssistantState.speaking => 'Speaking... (tap to stop)',
  };

  Widget _message(String label, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(text, style: const TextStyle(fontSize: 22)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text(
                'Hey Bro',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_userText.isNotEmpty) _message('You:', _userText),
                      if (_assistantText.isNotEmpty)
                        _message('Hey Bro:', _assistantText),
                      if (_errorText.isNotEmpty)
                        Text(
                          _errorText,
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 16,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Text(
                _statusText,
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
              const SizedBox(height: 16),
              MicButton(
                isListening: _state == AssistantState.listening,
                isSpeaking: _state == AssistantState.speaking,
                onPressed: _onMicPressed,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
