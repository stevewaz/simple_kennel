import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../utils/input_formatters.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _businessNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_businessNameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Enter your business name.');
      return;
    }
    if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _error = 'Enter an email and password.');
      return;
    }
    if (_passwordCtrl.text.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (_passwordCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Passwords don\'t match.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthService>().signUp(
          _emailCtrl.text, _passwordCtrl.text, _businessNameCtrl.text);
      // Navigation happens automatically via the auth-state listener.
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _messageFor(e.code));
    } catch (e) {
      setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _messageFor(String code) => switch (code) {
        'email-already-in-use' => 'An account with this email already exists.',
        'invalid-email' => 'That email address looks invalid.',
        'weak-password' => 'Choose a stronger password.',
        'network-request-failed' =>
          'No connection — check your internet and try again.',
        _ => 'Something went wrong. Try again.',
      };

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeService>();

    return Scaffold(
      backgroundColor: theme.scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.textColor),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Create your business account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: theme.textColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                      'One login is shared across your business\'s devices.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: theme.subtextColor, fontSize: 13)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _businessNameCtrl,
                    style: TextStyle(color: theme.textColor),
                    decoration:
                        const InputDecoration(labelText: 'Business Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    inputFormatters: [LowercaseEmailFormatter()],
                    style: TextStyle(color: theme.textColor),
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    style: TextStyle(color: theme.textColor),
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmCtrl,
                    obscureText: true,
                    style: TextStyle(color: theme.textColor),
                    decoration: const InputDecoration(
                        labelText: 'Confirm Password'),
                    onSubmitted: (_) => _signUp(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: const TextStyle(
                            color: Color(0xFFD4714D), fontSize: 13)),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: _loading ? null : _signUp,
                    child: Text(
                        _loading ? 'Creating account…' : 'Create Account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
