import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/neon_button.dart';

/// Account screen. Players reach this only if they choose to upgrade from the
/// default anonymous session (to sync scores across devices).
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _nick = TextEditingController();
  bool _busy = false;
  String? _error;

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (!mounted) return;
      if (_nick.text.trim().isNotEmpty) {
        await context.read<AuthService>().setDisplayName(_nick.text);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _nick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final auth = context.read<AuthService>();

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 8),
            Center(
              child: Text(
                s.t('signIn'),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _nick,
              decoration: InputDecoration(labelText: s.t('nickname')),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: s.t('email')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: InputDecoration(labelText: s.t('password')),
            ),
            const SizedBox(height: 20),
            NeonButton(
              label: s.t('continueEmail'),
              color: RgbColors.green,
              icon: Icons.email_rounded,
              onTap: () => _run(() =>
                  auth.signInWithEmail(_email.text, _password.text)),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            NeonButton(
              label: s.t('continueGoogle'),
              color: RgbColors.blue,
              icon: Icons.login_rounded,
              onTap: () => _run(auth.signInWithGoogle),
            ),
            if (auth.appleAvailable) ...[
              const SizedBox(height: 14),
              NeonButton(
                label: s.t('continueApple'),
                color: RgbColors.text,
                icon: Icons.apple_rounded,
                onTap: () => _run(auth.signInWithApple),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 20),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: RgbColors.red, fontSize: 12),
              ),
            ],
            if (_busy) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}
