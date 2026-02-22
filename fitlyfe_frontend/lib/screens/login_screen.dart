import 'package:fitlyfe_frontend/auth/apple_auth_strategy.dart';
import 'package:fitlyfe_frontend/auth/google_auth_strategy.dart';
import 'package:fitlyfe_frontend/widgets/social_button.dart';
import 'package:flutter/material.dart';
import 'package:fitlyfe_frontend/theme/app_theme.dart';
import 'package:fitlyfe_frontend/screens/signup_screen.dart';
import 'package:fitlyfe_frontend/widgets/premium_route.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: TweenAnimationBuilder<double>(
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sign In',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 20),

                // Email Field
                _buildTextField('Email', Icons.email_outlined),
                const SizedBox(height: 20),
                _buildTextField(
                  'Password',
                  Icons.lock_outline,
                  isPassword: true,
                ),

                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: AppTheme.accentGreen),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // TODO: wire up Supabase email/password sign-in.
                    // After signIn() succeeds, _onAppStateChanged in main.dart
                    // will navigate automatically based on requiresOnboarding.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Email sign-in coming soon')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'SIGN IN',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(
                      child: Divider(color: AppTheme.cardBackground),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: AppTheme.secondaryText.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Divider(color: AppTheme.cardBackground),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                SocialButton(
                  label: "Continue with Google",
                  icon: Icons.g_mobiledata,
                  backgroundColor: Colors.black,
                  textColor: Colors.white,
                  authStrategy: GoogleAuthStrategy(),
                ),

                const SizedBox(height: 24),

                SocialButton(
                  label: "Continue with Apple",
                  icon: Icons.apple,
                  backgroundColor: Colors.black,
                  textColor: Colors.white,
                  authStrategy: AppleAuthStrategy(),
                ),

                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Don\'t have an account?',
                      style: TextStyle(color: AppTheme.secondaryText),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          PremiumPageRoute(page: const SignupScreen()),
                        );
                      },
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: AppTheme.accentGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String hint,
    IconData icon, {
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: AppTheme.accentGreen),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}
