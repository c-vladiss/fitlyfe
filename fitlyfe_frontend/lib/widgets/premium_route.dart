import 'package:flutter/material.dart';

class PremiumPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  PremiumPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curve = Curves.easeInOutCubic;
            
            var slideTween = Tween<Offset>(
              begin: const Offset(0.0, 0.05),
              end: Offset.zero,
            ).chain(CurveTween(curve: curve));

            var fadeTween = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).chain(CurveTween(curve: curve));

            return FadeTransition(
              opacity: animation.drive(fadeTween),
              child: SlideTransition(
                position: animation.drive(slideTween),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
        );
}
