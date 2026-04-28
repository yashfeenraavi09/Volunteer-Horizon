import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CustomPrimaryButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;
  final IconData? icon;
  final bool isLoading;
  final Color? colorOverride;

  const CustomPrimaryButton({
    Key? key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.isLoading = false,
    this.colorOverride,
  }) : super(key: key);

  @override
  State<CustomPrimaryButton> createState() => _CustomPrimaryButtonState();
}

class _CustomPrimaryButtonState extends State<CustomPrimaryButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHighPriority = theme.colorScheme.primary.value == const Color(0xFFD32F2F).value;
    
    final gradientColors = widget.colorOverride != null
        ? [widget.colorOverride!, widget.colorOverride!.withOpacity(0.8)]
        : isHighPriority
            ? [const Color(0xFFD32F2F), const Color(0xFFF57C00)] // Red to Orange
            : [const Color(0xFF2E7D32), const Color(0xFF66BB6A)]; // Green to Light Green

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.isLoading ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withOpacity(_isHovering ? 0.6 : 0.3),
                blurRadius: _isHovering ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: widget.isLoading ? null : widget.onPressed,
              child: Center(
                child: widget.isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, color: Colors.white),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ).animate().fade().slideY(begin: 0.2, end: 0),
              ),
            ),
          ),
        ),
      ).animate(target: _isHovering ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.02, 1.02), duration: 150.ms),
    );
  }
}
