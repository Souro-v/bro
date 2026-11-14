class CommandHandler {
  /// Takes what the user said and returns what the assistant should say.
  static String handle(String input) {
    final text = input.toLowerCase().trim();
    final words = text.split(' ');

    // Order matters: the first match wins.
    if (text.contains('how are you')) {
      return "I'm doing great, thanks for asking!";
    }

    if (words.contains('hello') ||
        words.contains('hi') ||
        words.contains('hey')) {
      return 'Hello bro! How can I help?';
    }

    // Later phases: add alarm, call, open app, time, battery here.

    return "You said: $input. I can't do that yet, but I'm learning!";
  }
}
