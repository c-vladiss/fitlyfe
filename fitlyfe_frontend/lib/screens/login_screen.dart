import 'package:fitlyfe_frontend/auth/apple_auth_strategy.dart';
import 'package:fitlyfe_frontend/auth/google_auth_strategy.dart';
import 'package:fitlyfe_frontend/widgets/social_button.dart';
import 'package:flutter/material.dart';
import 'package:fitlyfe_frontend/theme/app_theme.dart';
import 'package:fitlyfe_frontend/screens/signup_screen.dart';
import 'package:fitlyfe_frontend/widgets/premium_route.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _passwordVisible = false;
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;

  static final _emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String value) {
    if (value.isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(value)) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) return 'Password is required';
    if (value.length < 10) return 'Must be at least 10 characters';
    if (!value.contains(RegExp(r'[A-Z]'))) return 'Must contain an uppercase letter';
    if (!value.contains(RegExp(r'[a-z]'))) return 'Must contain a lowercase letter';
    if (!value.contains(RegExp(r'[0-9]'))) return 'Must contain a number';
    if (!value.contains(RegExp(r'[^a-zA-Z0-9]'))) return 'Must contain a special character';
    return null;
  }

  bool _validate() {
    final emailErr = _validateEmail(_emailController.text.trim());
    final passwordErr = _validatePassword(_passwordController.text);
    setState(() {
      _emailError = emailErr;
      _passwordError = passwordErr;
    });
    return emailErr == null && passwordErr == null;
  }

  Future<void> _signIn() async {
    if (!_validate()) return;
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // Navigation is handled automatically by AppState.onAuthStateChange
    } on AuthException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      _showError('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('Sign-In Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

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
                  'Sign In',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  hint: 'Email',
                  icon: Icons.email_outlined,
                  controller: _emailController,
                  error: _emailError,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => setState(() => _emailError = null),
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  hint: 'Password',
                  icon: Icons.lock_outline,
                  controller: _passwordController,
                  error: _passwordError,
                  isPassword: true,
                  passwordVisible: _passwordVisible,
                  onTogglePasswordVisibility: () =>
                      setState(() => _passwordVisible = !_passwordVisible),
                  onChanged: (_) => setState(() => _passwordError = null),
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
                  onPressed: _isLoading ? null : _signIn,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'SIGN IN',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),

                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppTheme.cardBackground)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: AppTheme.secondaryText.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppTheme.cardBackground)),
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

                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account?",
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

  Widget _buildTextField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    String? error,
    bool isPassword = false,
    bool passwordVisible = false,
    VoidCallback? onTogglePasswordVisibility,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: error != null
                ? Border.all(color: AppTheme.accentRed, width: 1.5)
                : null,
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && !passwordVisible,
            keyboardType: keyboardType,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, color: AppTheme.accentGreen),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        passwordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppTheme.secondaryText,
                        size: 20,
                      ),
                      onPressed: onTogglePasswordVisibility,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 6),
            child: Text(
              error,
              style: const TextStyle(color: AppTheme.accentRed, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
