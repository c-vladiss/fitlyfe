import 'package:flutter/material.dart';
import 'package:fitlyfe_frontend/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isLoading = false;

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  static final _emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateName(String value) {
    if (value.trim().isEmpty) return 'Full name is required';
    return null;
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

  String? _validateConfirmPassword(String value) {
    if (value.isEmpty) return 'Please confirm your password';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  bool _validate() {
    final nameErr = _validateName(_nameController.text);
    final emailErr = _validateEmail(_emailController.text.trim());
    final passwordErr = _validatePassword(_passwordController.text);
    final confirmErr = _validateConfirmPassword(_confirmPasswordController.text);
    setState(() {
      _nameError = nameErr;
      _emailError = emailErr;
      _passwordError = passwordErr;
      _confirmPasswordError = confirmErr;
    });
    return nameErr == null && emailErr == null && passwordErr == null && confirmErr == null;
  }

  Future<void> _signUp() async {
    if (!_validate()) return;
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {'full_name': _nameController.text.trim()},
      );

      if (!mounted) return;

      if (response.session == null && response.user != null) {
        // Email confirmation required
        _showConfirmationDialog();
      }
      // If session != null, AppState.onAuthStateChange handles navigation
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

  void _showConfirmationDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('Confirm your email'),
        content: Text(
          'A confirmation link has been sent to ${_emailController.text.trim()}. '
          'Please check your inbox and click the link to activate your account.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // go back to login
            },
            child: const Text('Back to Sign In'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('Sign-Up Failed'),
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

                _buildTextField(
                  hint: 'Full Name',
                  icon: Icons.person_outline,
                  controller: _nameController,
                  error: _nameError,
                  onChanged: (_) => setState(() => _nameError = null),
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
                const SizedBox(height: 20),

                _buildTextField(
                  hint: 'Confirm Password',
                  icon: Icons.lock_outline,
                  controller: _confirmPasswordController,
                  error: _confirmPasswordError,
                  isPassword: true,
                  passwordVisible: _confirmPasswordVisible,
                  onTogglePasswordVisibility: () => setState(
                      () => _confirmPasswordVisible = !_confirmPasswordVisible),
                  onChanged: (_) => setState(() => _confirmPasswordError = null),
                ),

                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
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
                          'CREATE ACCOUNT',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),

                const SizedBox(height: 32),
                Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                        color: AppTheme.secondaryText,
                        fontSize: 13,
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(text: 'By signing up, you agree to our '),
                        TextSpan(
                          text: 'Terms of Service',
                          style: TextStyle(
                            color: AppTheme.accentGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            color: AppTheme.accentGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
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
