// lib/screens/detail/answer_tile.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/answer_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/question_provider.dart';
import '../../services/vote_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/vote_widget.dart';
import 'answer_composer.dart';

class AnswerTile extends ConsumerStatefulWidget {
  final AnswerModel answer;
  final String questionId;
  final bool isQuestionAuthor;
  final VoidCallback? onAccept;

  const AnswerTile({
    super.key,
    required this.answer,
    required this.questionId,
    this.isQuestionAuthor = false,
    this.onAccept,
  });

  @override
  ConsumerState<AnswerTile> createState() => _AnswerTileState();
}

class _AnswerTileState extends ConsumerState<AnswerTile> {
  bool _showReplyBox = false;
  bool _showReplies = false;

  @override
  Widget build(BuildContext context) {
    final repliesAsync = ref.watch(repliesStreamProvider(widget.answer.id));
    final currentUser = ref.watch(currentUserProfileProvider).valueOrNull;
    final isAccepted = widget.answer.isAccepted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isAccepted
            ? AppColors.accent.withOpacity(0.08)
            : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAccepted
              ? AppColors.accent.withOpacity(0.5)
              : AppColors.divider,
          width: isAccepted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Main answer body ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Vote column ───────────────────────────────────────────
                Column(
                  children: [
                    VoteWidget(
                      targetId: widget.answer.id,
                      target: VoteTarget.answer,
                      voteCount: widget.answer.voteCount,
                    ),
                    if (widget.isQuestionAuthor && !isAccepted) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: widget.onAccept,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                    if (isAccepted)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.accent,
                          size: 20,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),

                // ── Answer text ───────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isAccepted)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_outline_rounded,
                                    size: 12, color: AppColors.accent),
                                const SizedBox(width: 4),
                                Text(
                                  'Accepted Answer',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      Text(
                        widget.answer.body,
                        style: AppTextStyles.bodyLarge,
                      ),

                      const SizedBox(height: 12),

                      // ── Footer ───────────────────────────────────────────
                      Row(
                        children: [
                          _avatarCircle(widget.answer.authorHandle),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.answer.authorHandle ?? 'Anonymous',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  timeago.format(widget.answer.createdAt),
                                  style: AppTextStyles.labelSmall,
                                ),
                              ],
                            ),
                          ),
                          // Reply button
                          TextButton.icon(
                            onPressed: () => setState(
                                () => _showReplyBox = !_showReplyBox),
                            icon: const Icon(Icons.reply_rounded, size: 15),
                            label: const Text('Reply'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.textMuted,
                              textStyle: const TextStyle(fontSize: 12),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Replies ─────────────────────────────────────────────────────
          repliesAsync.when(
            data: (replies) {
              if (replies.isEmpty && !_showReplyBox) return const SizedBox();
              return Column(
                children: [
                  const Divider(height: 1, indent: 14, endIndent: 14),
                  // Show/hide replies toggle
                  if (replies.isNotEmpty)
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _showReplies = !_showReplies),
                      icon: Icon(
                        _showReplies
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 16,
                      ),
                      label: Text(
                        _showReplies
                            ? 'Hide ${replies.length} replies'
                            : 'Show ${replies.length} ${replies.length == 1 ? 'reply' : 'replies'}',
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryLight,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  if (_showReplies)
                    ...replies.map((reply) => _buildReplyTile(reply)),
                  if (_showReplyBox) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: AnswerComposer(
                        questionId: widget.questionId,
                        parentAnswerId: widget.answer.id,
                        replyingToHandle: widget.answer.authorHandle,
                        onSubmitted: () {
                          setState(() {
                            _showReplyBox = false;
                            _showReplies = true;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyTile(AnswerModel reply) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 4, 12, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: AppColors.primary.withOpacity(0.4), width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(reply.body, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              _avatarCircle(reply.authorHandle, small: true),
              const SizedBox(width: 6),
              Text(
                reply.authorHandle ?? 'Anonymous',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                timeago.format(reply.createdAt),
                style: AppTextStyles.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatarCircle(String? handle, {bool small = false}) {
    final initials =
        handle != null && handle.isNotEmpty ? handle[0].toUpperCase() : '?';
    final radius = small ? 10.0 : 12.0;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withOpacity(0.25),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: small ? 9 : 10,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryLight,
        ),
      ),
    );
  }
}
