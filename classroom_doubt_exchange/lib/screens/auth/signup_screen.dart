// lib/screens/auth/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _handleCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _loading = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _handleCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authNotifierProvider.notifier).signUp(
            email: _emailCtrl.text,
            password: _passCtrl.text,
            handle: _handleCtrl.text,
          );
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_friendlyError(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String e) {
    if (e.contains('email-already-in-use')) {
      return 'This email is already registered. Try signing in.';
    }
    if (e.contains('taken')) return 'Handle already taken. Choose another.';
    if (e.contains('weak-password')) return 'Password too weak. Use 6+ chars.';
    return 'Sign up failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/login'),
        ),
        title: const Text('Create Account'),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────────
                Text('Join the community', style: AppTextStyles.displayLarge),
                const SizedBox(height: 8),
                Text(
                  'Pick a pseudonym — your posts are anonymous to classmates.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 32),

                // ── Anonymity note ───────────────────────────────────────────
                _buildAnonymityNote(),
                const SizedBox(height: 28),

                // ── Handle ───────────────────────────────────────────────────
                _buildLabel('Your Handle (Pseudonym)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _handleCtrl,
                  autocorrect: false,
                  style: AppTextStyles.bodyLarge,
                  decoration: const InputDecoration(
                    hintText: 'e.g. PhysicsNerd42',
                    prefixIcon: Icon(Icons.alternate_email_rounded,
                        color: AppColors.textMuted),
                    helperText: 'This is shown on leaderboards, not on posts.',
                    helperStyle: TextStyle(
                        color: AppColors.textMuted, fontSize: 11),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Handle is required';
                    }
                    if (v.trim().length < 3) {
                      return 'Minimum 3 characters';
                    }
                    if (v.trim().length > 20) return 'Maximum 20 characters';
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) {
                      return 'Only letters, numbers and underscores';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // ── Email ─────────────────────────────────────────────────────
                _buildLabel('Email'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  style: AppTextStyles.bodyLarge,
                  decoration: const InputDecoration(
                    hintText: 'your@email.com',
                    prefixIcon: Icon(Icons.mail_outline_rounded,
                        color: AppColors.textMuted),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // ── Password ──────────────────────────────────────────────────
                _buildLabel('Password'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Min. 6 characters',
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        color: AppColors.textMuted),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // ── Confirm password ──────────────────────────────────────────
                _buildLabel('Confirm Password'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscurePass,
                  style: AppTextStyles.bodyLarge,
                  decoration: const InputDecoration(
                    hintText: 'Re-enter your password',
                    prefixIcon: Icon(Icons.lock_outline_rounded,
                        color: AppColors.textMuted),
                  ),
                  validator: (v) {
                    if (v != _passCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 36),

                // ── Sign up button ────────────────────────────────────────────
                ElevatedButton(
                  onPressed: _loading ? null : _signUp,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Create Account'),
                ),
                const SizedBox(height: 20),

                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Already have an account? ',
                          style: AppTextStyles.bodyMedium),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Sign In'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnonymityNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined,
              color: AppColors.primaryLight, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your questions and answers are posted anonymously. '
              'Only your handle appears on leaderboards.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary),
    );
  }
}
