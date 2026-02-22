import 'package:flutter/material.dart';
import 'package:fitlyfe_frontend/theme/app_theme.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Account',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  'Join FitLyfe today and start tracking your fitness journey.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.secondaryText,
                  ),
                ),
                const SizedBox(height: 48),
                
                _buildTextField('Full Name', Icons.person_outline),
                const SizedBox(height: 20),
                _buildTextField('Email', Icons.email_outlined),
                const SizedBox(height: 20),
                _buildTextField('Password', Icons.lock_outline, isPassword: true),
                const SizedBox(height: 20),
                _buildTextField('Confirm Password', Icons.lock_outline, isPassword: true),
                
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    // TODO: wire up Supabase email/password sign-up.
                    // After signUp() succeeds, _onAppStateChanged in main.dart
                    // will navigate automatically based on requiresOnboarding.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Email sign-up coming soon')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('CREATE ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                
                const SizedBox(height: 32),
                Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(color: AppTheme.secondaryText, fontSize: 13, height: 1.5),
                      children: [
                        const TextSpan(text: 'By signing up, you agree to our '),
                        TextSpan(
                          text: 'Terms of Service',
                          style: TextStyle(color: AppTheme.accentGreen, fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(color: AppTheme.accentGreen, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, IconData icon, {bool isPassword = false}) {
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
}
