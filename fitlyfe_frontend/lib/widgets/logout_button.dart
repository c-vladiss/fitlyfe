import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fitlyfe_frontend/theme/app_theme.dart';

class LogoutButton extends StatefulWidget {
  const LogoutButton({super.key});

  @override
  State<LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<LogoutButton> {
  bool _isLoading = false;

  Future<void> _confirmAndLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCEL',
                style: TextStyle(color: AppTheme.secondaryText)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('LOG OUT',
                style: TextStyle(color: AppTheme.accentRed)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      // Signing out from Supabase invalidates the JWT. The auth listener in
      // main.dart picks up the state change and routes back to WelcomeScreen.
      // No backend request is needed — the backend is stateless and validates
      // tokens on each request.
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $e'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
      setState(() => _isLoading = false);
    }
    // No need to reset _isLoading on success — widget is disposed as the app
    // navigates away when AppState.isAuthenticated becomes false.
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isLoading ? null : _confirmAndLogout,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.accentRed,
                    ),
                  )
                : const Icon(Icons.logout, color: AppTheme.accentRed, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Log Out',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.accentRed,
                    ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.secondaryText,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
