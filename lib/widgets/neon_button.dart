import 'package:flutter/material.dart';
import '../theme.dart';

/// Pill-shaped neon button used across menus.
class NeonButton extends StatefulWidget {
  const NeonButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = RgbColors.blue,
    this.icon,
    this.filled = true,
    this.width,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;
  final IconData? icon;
  final bool filled;
  final double? width;

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Container(
          width: widget.width,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: BoxDecoration(
            color: widget.filled ? widget.color.withOpacity(0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: widget.color, width: 2),
            boxShadow: neonGlow(widget.color, blur: _down ? 10 : 22),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: widget.color, size: 22),
                const SizedBox(width: 10),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: RgbColors.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
