import 'package:flutter/material.dart';
import 'package:fitlyfe_frontend/theme/app_theme.dart';
import 'package:fitlyfe_frontend/screens/login_screen.dart';
import 'package:fitlyfe_frontend/providers/translation_provider.dart';
import 'package:fitlyfe_frontend/widgets/premium_route.dart';
import 'package:provider/provider.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<TranslationProvider>(context);
    return Scaffold(
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentGreen.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentBlue.withOpacity(0.03),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Spacer(),
                  TweenAnimationBuilder<double>(
                    duration: const Duration(seconds: 1),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 30 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        // Glowing Custom Logo
                        Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Glow Background
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.accentGreen.withOpacity(0.3),
                                      blurRadius: 40,
                                      spreadRadius: 10,
                                    ),
                                    BoxShadow(
                                      color: AppTheme.accentGreen.withOpacity(0.15),
                                      blurRadius: 80,
                                      spreadRadius: 20,
                                    ),
                                  ],
                                ),
                              ),
                              // The Logo
                              SizedBox(
                                width: 140,
                                height: 140,
                                child: CustomPaint(
                                  painter: FitLyfeLogoPainter(
                                    accentColor: AppTheme.accentGreen,
                                    baseColor: const Color(0xFF1E3A5F),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 60),
                        Text(
                          tp.translate('welcome_title'),
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -1.0,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          tp.translate('welcome_subtitle'),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppTheme.secondaryText,
                                fontSize: 18,
                                height: 1.5,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Bottom Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        PremiumPageRoute(page: const LoginScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 60),
                      backgroundColor: AppTheme.accentGreen,
                      foregroundColor: AppTheme.backgroundColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      tp.translate('get_started'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FitLyfeLogoPainter extends CustomPainter {
  final Color accentColor;
  final Color baseColor;

  FitLyfeLogoPainter({required this.accentColor, required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double w = size.width;
    final double h = size.height;
    final double centerX = w / 2;
    final double centerY = h / 2;
    
    const double thickness = 11.0;
    const double halfGap = 10.0; 
    const double letterHeight = 44.0;
    const double letterWidth = 26.0;

    // --- Draw the 'F' (Left weight) ---
    // Stem on the outside (left), bars pointing inner (right)
    Path pathF = Path();
    // Vertical stem of F
    pathF.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(centerX - halfGap - letterWidth, centerY - letterHeight / 2, thickness, letterHeight),
      const Radius.circular(5),
    ));
    // Top bar of F
    pathF.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(centerX - halfGap - letterWidth, centerY - letterHeight / 2, letterWidth, thickness),
      const Radius.circular(5),
    ));
    // Middle bar of F
    pathF.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(centerX - halfGap - letterWidth, centerY - thickness / 2, letterWidth * 0.7, thickness),
      const Radius.circular(5),
    ));
    
    // --- Draw the 'L' (Right weight) ---
    // Mirrored: Stem on the outside (right), bar pointing inner (left)
    Path pathL = Path();
    // Vertical stem of L
    pathL.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(centerX + halfGap + letterWidth - thickness, centerY - letterHeight / 2, thickness, letterHeight),
      const Radius.circular(5),
    ));
    // Bottom bar of L
    pathL.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(centerX + halfGap + letterWidth - letterWidth, centerY + letterHeight / 2 - thickness, letterWidth, thickness),
      const Radius.circular(5),
    ));

    // --- Draw Central Connecting Bar (Uniting them) ---
    Path connector = Path();
    connector.addRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: halfGap * 2 + 35, // Increased by 10px total to extend 5px more towards L (and F)
        height: thickness,
      ),
      const Radius.circular(3),
    ));

    // Draw everything with a slight tilt for dynamism
    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(-0.25); // Dynamic tilt
    canvas.translate(-centerX, -centerY);
    
    canvas.drawPath(pathF, paint);
    canvas.drawPath(pathL, paint);
    canvas.drawPath(connector, paint);
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
