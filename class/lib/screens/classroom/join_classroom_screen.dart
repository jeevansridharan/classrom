// lib/screens/classroom/join_classroom_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/classroom_service.dart';
import '../../theme/app_theme.dart';

class JoinClassroomDialog extends ConsumerStatefulWidget {
  const JoinClassroomDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const JoinClassroomDialog(),
    );
  }

  @override
  ConsumerState<JoinClassroomDialog> createState() => _JoinClassroomDialogState();
}

class _JoinClassroomDialogState extends ConsumerState<JoinClassroomDialog> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final classroom = await ref
          .read(classroomServiceProvider)
          .joinClassroomByCode(_codeController.text.trim());

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Joined "${classroom.name}" successfully!'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: AppColors.primaryLight,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Join Classroom',
                      style: AppTextStyles.headlineSmall,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Enter the 6-character code provided by your instructor to join the classroom community.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                style: AppTextStyles.titleLarge.copyWith(
                  letterSpacing: 4,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: 'e.g. CS101X',
                  counterText: '',
                  prefixIcon: Icon(Icons.key_rounded, color: AppColors.primaryLight),
                ),
                validator: (val) {
                  if (val == null || val.trim().length != 6) {
                    return 'Code must be exactly 6 characters';
                  }
                  return null;
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTextStyles.caption.copyWith(color: AppColors.errorLight),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleJoin,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Join Classroom'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
