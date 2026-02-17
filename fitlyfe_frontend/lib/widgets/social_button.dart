import 'dart:async';

import 'package:fitlyfe_frontend/auth/auth_stategy.dart';
import 'package:fitlyfe_frontend/main.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SocialButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final AuthStategy authStrategy;

  const SocialButton({
    super.key,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.authStrategy,
  });

  @override
  State<SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<SocialButton> {
  String? _userId;
  late final StreamSubscription<AuthState> _authSub;

  @override
  void initState() {
    super.initState();

    _authSub = supabase.auth.onAuthStateChange.listen((data) {
      setState(() {
        _userId = data.session?.user.id;
      });
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await widget.authStrategy.signIn();
      },
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, color: widget.textColor, size: 28),
            const SizedBox(width: 12),
            Text(
              widget.label,
              style: TextStyle(
                color: widget.textColor,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
