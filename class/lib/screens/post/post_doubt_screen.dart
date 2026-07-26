// lib/screens/post/post_doubt_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/question_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/question_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tag_chip.dart';
import '../../models/tag_model.dart';

class PostDoubtScreen extends ConsumerStatefulWidget {
  const PostDoubtScreen({super.key});

  @override
  ConsumerState<PostDoubtScreen> createState() => _PostDoubtScreenState();
}

class _PostDoubtScreenState extends ConsumerState<PostDoubtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final List<String> _selectedTags = [];
  File? _selectedImage;
  bool _loading = false;
  bool _checkingDuplicates = false;
  List<QuestionModel> _duplicateSuggestions = [];
  bool _showDuplicateWarning = false;
  bool _duplicatesChecked = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  // ── Duplicate Check ─────────────────────────────────────────────────────────
  Future<void> _checkDuplicates() async {
    if (_titleCtrl.text.trim().length < 10) return;
    setState(() => _checkingDuplicates = true);
    try {
      final svc = ref.read(duplicateDetectionProvider);
      final similar = await svc.findSimilar(
        title: _titleCtrl.text,
        body: _bodyCtrl.text,
      );
      setState(() {
        _duplicateSuggestions = similar;
        _showDuplicateWarning = similar.isNotEmpty;
        _duplicatesChecked = true;
      });
    } finally {
      if (mounted) setState(() => _checkingDuplicates = false);
    }
  }

  // ── Pick Image ──────────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final storage = ref.read(storageServiceProvider);
    final file = await storage.pickImage(source: ImageSource.gallery);
    if (file != null && mounted) {
      setState(() => _selectedImage = File(file.path));
    }
  }

  // ── Submit ──────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Run duplicate check first if not done
    if (!_duplicatesChecked) {
      await _checkDuplicates();
      if (_showDuplicateWarning) return; // Let user see warning first
    }

    setState(() => _loading = true);
    try {
      final profile = ref.read(currentUserProfileProvider).valueOrNull;
      final storage = ref.read(storageServiceProvider);
      final qSvc = ref.read(questionServiceProvider);

      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await storage.uploadQuestionImage(_selectedImage!);
      }

      final id = await qSvc.postQuestion(
        title: _titleCtrl.text,
        body: _bodyCtrl.text,
        tags: _selectedTags,
        imageUrl: imageUrl,
        authorHandle: profile?.handle ?? 'Anonymous',
      );

      if (mounted) {
        context.pushReplacement('/question/$id');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doubt posted! 🎉')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else if (_selectedTags.length < 5) {
        _selectedTags.add(tag);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a Doubt'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(80, 36),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Post'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Duplicate warning ──────────────────────────────────────────
              if (_showDuplicateWarning) ...[
                _buildDuplicateWarning(),
                const SizedBox(height: 16),
              ],

              // ── Title ──────────────────────────────────────────────────────
              _buildSectionLabel('Title', 'Be specific and descriptive'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                style: AppTextStyles.bodyLarge,
                maxLength: 150,
                decoration: const InputDecoration(
                  hintText:
                      'e.g. How to solve differential equations by substitution?',
                  counterStyle: TextStyle(color: AppColors.textMuted),
                ),
                onChanged: (v) {
                  if (_duplicatesChecked) {
                    setState(() {
                      _duplicatesChecked = false;
                      _showDuplicateWarning = false;
                    });
                  }
                },
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Title is required';
                  if (v.trim().length < 10) {
                    return 'Title too short (min 10 characters)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ── Check duplicates button ────────────────────────────────────
              if (!_duplicatesChecked && _titleCtrl.text.length >= 10)
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _checkingDuplicates ? null : _checkDuplicates,
                    icon: _checkingDuplicates
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search_rounded, size: 16),
                    label: Text(_checkingDuplicates
                        ? 'Checking...'
                        : 'Check for similar questions'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryLight,
                      side: const BorderSide(color: AppColors.divider),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // ── Body ───────────────────────────────────────────────────────
              _buildSectionLabel(
                  'Description', 'Include what you tried and where you\'re stuck'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bodyCtrl,
                style: AppTextStyles.bodyLarge,
                maxLines: 8,
                minLines: 5,
                decoration: const InputDecoration(
                  hintText:
                      'Describe your doubt in detail. What have you tried? What error are you getting?',
                  alignLabelWithHint: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please describe your doubt';
                  }
                  if (v.trim().length < 20) {
                    return 'Description too short (min 20 characters)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // ── Tags ───────────────────────────────────────────────────────
              _buildSectionLabel(
                  'Subject / Tags', 'Select up to 5 (${_selectedTags.length}/5)'),
              const SizedBox(height: 8),
              if (_selectedTags.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _selectedTags
                      .map((tag) => TagChip(
                            label: tag,
                            selected: true,
                            removable: true,
                            onRemove: () => _toggleTag(tag),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: kPresetTags
                    .where((t) => !_selectedTags.contains(t))
                    .map((tag) => TagChip(
                          label: tag,
                          onTap: () => _toggleTag(tag),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),

              // ── Image attachment ───────────────────────────────────────────
              _buildSectionLabel('Image (optional)', 'Attach a photo of your notes or problem'),
              const SizedBox(height: 10),
              _buildImagePicker(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.titleMedium),
        Text(subtitle, style: AppTextStyles.labelSmall),
      ],
    );
  }

  Widget _buildDuplicateWarning() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.secondary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Similar questions found!',
                style: AppTextStyles.titleMedium
                    .copyWith(color: AppColors.secondary),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _showDuplicateWarning = false),
                child: const Text('Dismiss',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Please check if your question is already answered:',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 10),
          ..._duplicateSuggestions.map((q) => GestureDetector(
                onTap: () => context.push('/question/${q.id}'),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.help_outline_rounded,
                            size: 14, color: AppColors.primaryLight),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            q.title,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primaryLight,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded,
                            size: 12, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
              )),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _showDuplicateWarning = false;
                  _duplicatesChecked = true;
                });
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.secondary),
                foregroundColor: AppColors.secondary,
              ),
              child: const Text('Post anyway — my question is different'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    if (_selectedImage != null) {
      return Stack(
        alignment: Alignment.topRight,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _selectedImage!,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => setState(() => _selectedImage = null),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.divider,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_photo_alternate_outlined,
                size: 32, color: AppColors.textMuted),
            const SizedBox(height: 8),
            Text('Tap to attach an image',
                style: AppTextStyles.bodyMedium),
          ],
        ),
      ),
    );
  }
}
