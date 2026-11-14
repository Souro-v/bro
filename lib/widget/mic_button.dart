import 'package:flutter/material.dart';

class MicButton extends StatefulWidget {
  final bool isListening;
  final bool isSpeaking;
  final VoidCallback onPressed;

  const MicButton({
    super.key,
    required this.isListening,
    required this.isSpeaking,
    required this.onPressed,
  });

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didUpdateWidget(MicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Pulse only while listening.
    if (widget.isListening && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isListening && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color color = widget.isListening
        ? Colors.redAccent
        : widget.isSpeaking
        ? Colors.greenAccent.shade400
        : Colors.indigoAccent;

    final IconData icon = widget.isListening
        ? Icons.stop_rounded
        : widget.isSpeaking
        ? Icons.volume_up_rounded
        : Icons.mic_rounded;

    return GestureDetector(
      onTap: widget.onPressed,
      child: SizedBox(
        width: 220,
        height: 220,
        child: AnimatedBuilder(
          animation: _controller,
          // The main button doesn't change every frame, so pass it as `child`.
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 30),
              ],
            ),
            child: Icon(icon, size: 64, color: Colors.white),
          ),
          builder: (context, child) {
            final pulse = _controller.value; // goes 0.0 -> 1.0 -> 0.0
            return Stack(
              alignment: Alignment.center,
              children: [
                // Pulsing ring behind the button
                Container(
                  width: 140 + pulse * 70,
                  height: 140 + pulse * 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.25 * (1 - pulse)),
                  ),
                ),
                child!,
              ],
            );
          },
        ),
      ),
    );
  }
}
