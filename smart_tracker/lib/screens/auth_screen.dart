import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../state/auth_store.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';

enum AuthMode { signIn, signUp }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  AuthMode _mode = AuthMode.signIn;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthStore auth) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showMessage('Enter a valid email.');
      return;
    }
    if (password.length < 8) {
      _showMessage('Password must be at least 8 characters.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_mode == AuthMode.signIn) {
        await auth.signIn(email, password);
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        await auth.signUp(email, password);
        _showMessage('Account created. Check your email to confirm if required.');
      }
    } on AuthException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Authentication failed.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.pageGradient),
        child: SafeArea(
          child: Consumer<AuthStore>(
            builder: (context, auth, _) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Tracker',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 34),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to sync your data securely.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                    ),
                    const SizedBox(height: 20),
                    SegmentedButton<AuthMode>(
                      segments: const [
                        ButtonSegment(value: AuthMode.signIn, label: Text('Sign in')),
                        ButtonSegment(value: AuthMode.signUp, label: Text('Create account')),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (value) {
                        setState(() => _mode = value.first);
                      },
                    ),
                    const SizedBox(height: 18),
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.muted)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(hintText: 'you@example.com'),
                          ),
                          const SizedBox(height: 16),
                          Text('Password', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.muted)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(hintText: 'At least 8 characters'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _isLoading ? null : () => _submit(auth),
                        child: _isLoading
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(_mode == AuthMode.signIn ? 'Sign in' : 'Create account'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
