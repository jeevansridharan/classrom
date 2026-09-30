// lib/screens/classroom/create_classroom_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/classroom_service.dart';
import '../../theme/app_theme.dart';

class CreateClassroomScreen extends ConsumerStatefulWidget {
  const CreateClassroomScreen({super.key});

  @override
  ConsumerState<CreateClassroomScreen> createState() => _CreateClassroomScreenState();
}

class _CreateClassroomScreenState extends ConsumerState<CreateClassroomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final classroom = await ref.read(classroomServiceProvider).createClassroom(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
          );

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Classroom "${classroom.name}" created! Code: ${classroom.code}'),
            backgroundColor: AppColors.accent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Classroom'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Classroom Details',
                style: AppTextStyles.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Create a space for your course, batch, or study group to ask doubts and build a knowledge base.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                style: AppTextStyles.bodyLarge,
                decoration: const InputDecoration(
                  labelText: 'Classroom Name',
                  hintText: 'e.g. CS201 - Data Structures & Algorithms',
                  prefixIcon: Icon(Icons.class_outlined, color: AppColors.primaryLight),
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 3) {
                    return 'Classroom name must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _descriptionController,
                style: AppTextStyles.bodyLarge,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'e.g. Official Q&A hub for Fall 2026 CS201 students',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.description_outlined, color: AppColors.primaryLight),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleCreate,
                icon: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.add_circle_outline_rounded),
                label: Text(_isLoading ? 'Creating...' : 'Create Classroom'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
