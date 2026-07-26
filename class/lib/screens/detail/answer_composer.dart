// lib/screens/detail/answer_composer.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/question_provider.dart';
import '../../theme/app_theme.dart';

class AnswerComposer extends ConsumerStatefulWidget {
  final String questionId;
  final String? parentAnswerId;
  final String? replyingToHandle;
  final VoidCallback? onSubmitted;

  const AnswerComposer({
    super.key,
    required this.questionId,
    this.parentAnswerId,
    this.replyingToHandle,
    this.onSubmitted,
  });

  @override
  ConsumerState<AnswerComposer> createState() => _AnswerComposerState();
}

class _AnswerComposerState extends ConsumerState<AnswerComposer> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.parentAnswerId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_ctrl.text.trim().isEmpty) return;
    if (_ctrl.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Answer too short. Please write at least 10 characters.'),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final profile = ref.read(currentUserProfileProvider).valueOrNull;
      final svc = ref.read(answerServiceProvider);

      await svc.postAnswer(
        questionId: widget.questionId,
        body: _ctrl.text,
        authorHandle: profile?.handle ?? 'Anonymous',
        parentAnswerId: widget.parentAnswerId,
      );

      _ctrl.clear();
      FocusScope.of(context).unfocus();
      widget.onSubmitted?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.parentAnswerId != null
                  ? 'Reply posted!'
                  : 'Answer posted! 🎉',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReply = widget.parentAnswerId != null;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        isReply ? 0 : 12,
        16,
        MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: isReply
            ? null
            : Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isReply && widget.replyingToHandle != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 12),
              child: Text(
                'Replying to @${widget.replyingToHandle}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primaryLight,
                ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focusNode,
                  style: AppTextStyles.bodyLarge,
                  maxLines: isReply ? 4 : 6,
                  minLines: isReply ? 2 : 3,
                  decoration: InputDecoration(
                    hintText: isReply
                        ? 'Write a reply...'
                        : 'Write your answer here. Be clear and helpful!',
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              AnimatedOpacity(
                opacity: _loading ? 0.5 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: _loading ? null : _submit,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
          if (!isReply)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '🔒 Your answer is posted anonymously to other students.',
                style: AppTextStyles.labelSmall,
              ),
            ),
        ],
      ),
    );
  }
}
