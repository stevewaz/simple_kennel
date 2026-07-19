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
  final _emailFocus = FocusNode();
  String? _error;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _invitedBusinessName;
  bool _checkingInvite = false;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() {
      if (!_emailFocus.hasFocus) _checkInvite();
    });
  }

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _checkInvite() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    setState(() => _checkingInvite = true);
    final businessName = await context.read<AuthService>().checkInvite(email);
    if (mounted) {
      setState(() {
        _invitedBusinessName = businessName;
        _checkingInvite = false;
      });
    }
  }

  Future<void> _signUp() async {
    final joining = _invitedBusinessName != null;
    if (!joining && _businessNameCtrl.text.trim().isEmpty) {
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
    final joining = _invitedBusinessName != null;

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
                  Text(
                      joining
                          ? 'Join $_invitedBusinessName'
                          : 'Create your business account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: theme.textColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                      joining
                          ? 'You were invited to this business — set a password to finish joining.'
                          : 'One login is shared across your business\'s devices.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: theme.subtextColor, fontSize: 13)),
                  const SizedBox(height: 24),
                  if (!joining) ...[
                    TextField(
                      controller: _businessNameCtrl,
                      style: TextStyle(color: theme.textColor),
                      decoration:
                          const InputDecoration(labelText: 'Business Name'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _emailCtrl,
                    focusNode: _emailFocus,
                    keyboardType: TextInputType.emailAddress,
                    inputFormatters: [LowercaseEmailFormatter()],
                    style: TextStyle(color: theme.textColor),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      suffixIcon: _checkingInvite
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)))
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    style: TextStyle(color: theme.textColor),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: theme.subtextColor,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmCtrl,
                    obscureText: _obscureConfirm,
                    style: TextStyle(color: theme.textColor),
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: theme.subtextColor,
                        ),
                        onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
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
                    child: Text(_loading
                        ? 'Creating account…'
                        : (joining ? 'Join Business' : 'Create Account')),
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
