import 'package:flutter/material.dart';
import 'package:fitlyfe_frontend/theme/app_theme.dart';

class TopNotification extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;

  const TopNotification({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  @override
  State<TopNotification> createState() => _TopNotificationState();
}

class _TopNotificationState extends State<TopNotification> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();

    // Auto dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.accentGreen,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.stars, color: AppTheme.backgroundColor, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                widget.message,
                style: const TextStyle(
                  color: AppTheme.backgroundColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: AppTheme.backgroundColor, size: 20),
              onPressed: () => _controller.reverse().then((_) => widget.onDismiss()),
            ),
          ],
        ),
      ),
    );
  }
}
