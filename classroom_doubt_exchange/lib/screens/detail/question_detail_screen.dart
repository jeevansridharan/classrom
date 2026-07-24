// lib/screens/detail/question_detail_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/auth_provider.dart';
import '../../providers/question_provider.dart';
import '../../services/answer_service.dart';
import '../../services/vote_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/tag_chip.dart';
import '../../widgets/vote_widget.dart';
import 'answer_tile.dart';
import 'answer_composer.dart';

class QuestionDetailScreen extends ConsumerStatefulWidget {
  final String questionId;

  const QuestionDetailScreen({super.key, required this.questionId});

  @override
  ConsumerState<QuestionDetailScreen> createState() =>
      _QuestionDetailScreenState();
}

class _QuestionDetailScreenState
    extends ConsumerState<QuestionDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Increment view count once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(questionServiceProvider)
          .incrementViewCount(widget.questionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final questionAsync =
        ref.watch(questionStreamProvider(widget.questionId));
    final answersAsync =
        ref.watch(answersStreamProvider(widget.questionId));
    final currentUser = ref.watch(currentUserProfileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Question'),
        actions: [
          questionAsync.when(
            data: (q) {
              if (q == null) return const SizedBox();
              return IconButton(
                icon: Icon(
                  q.isResolved
                      ? Icons.check_circle_rounded
                      : Icons.check_circle_outline_rounded,
                  color: q.isResolved ? AppColors.accent : AppColors.textMuted,
                ),
                tooltip:
                    q.isResolved ? 'Mark as unsolved' : 'Mark as solved',
                onPressed: () async {
                  try {
                    await ref
                        .read(questionServiceProvider)
                        .markResolved(widget.questionId, !q.isResolved);
                  } catch (_) {}
                },
              );
            },
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
      body: questionAsync.when(
        data: (question) {
          if (question == null) {
            return const ErrorState(message: 'Question not found');
          }
          return Column(
            children: [
              // ── Scrollable content ────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Tags ───────────────────────────────────────────────
                      if (question.tags.isNotEmpty) ...[
                        TagChipRow(tags: question.tags),
                        const SizedBox(height: 12),
                      ],

                      // ── Title ──────────────────────────────────────────────
                      Text(question.title, style: AppTextStyles.headlineMedium),
                      const SizedBox(height: 8),

                      // ── Meta row ───────────────────────────────────────────
                      Row(
                        children: [
                          _avatarCircle(question.authorHandle),
                          const SizedBox(width: 6),
                          Text(
                            question.authorHandle ?? 'Anonymous',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeago.format(question.createdAt),
                            style: AppTextStyles.labelSmall,
                          ),
                          const Spacer(),
                          Icon(Icons.remove_red_eye_outlined,
                              size: 13, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            '${question.viewCount}',
                            style: AppTextStyles.labelSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Question body ──────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          question.body,
                          style: AppTextStyles.bodyLarge.copyWith(height: 1.7),
                        ),
                      ),

                      // ── Image ──────────────────────────────────────────────
                      if (question.imageUrl != null) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: question.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              height: 200,
                              color: AppColors.surfaceVariant,
                              child: const Center(
                                  child: CircularProgressIndicator()),
                            ),
                          ),
                        ),
                      ],

                      // ── Vote row ───────────────────────────────────────────
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          VoteWidget(
                            targetId: question.id,
                            target: VoteTarget.question,
                            voteCount: question.voteCount,
                            compact: true,
                          ),
                          const Spacer(),
                          if (question.isResolved)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppColors.accent.withOpacity(0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle_rounded,
                                      size: 14, color: AppColors.accent),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Solved',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 28),
                      _buildAnswersHeader(answersAsync),

                      // ── Answers ────────────────────────────────────────────
                      answersAsync.when(
                        data: (answers) {
                          if (answers.isEmpty) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 24),
                              child: EmptyState(
                                icon: Icons.chat_bubble_outline_rounded,
                                title: 'No answers yet',
                                subtitle: 'Be the first to help!',
                              ),
                            );
                          }
                          return Column(
                            children: answers
                                .map((a) => AnswerTile(
                                      answer: a,
                                      questionId: widget.questionId,
                                      isQuestionAuthor: false,
                                      onAccept: () {
                                        ref
                                            .read(answerServiceProvider)
                                            .acceptAnswer(
                                              questionId: widget.questionId,
                                              answerId: a.id,
                                            );
                                      },
                                    ))
                                .toList(),
                          );
                        },
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (e, _) =>
                            ErrorState(message: e.toString()),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // ── Answer composer (sticky bottom) ───────────────────────────
              AnswerComposer(questionId: widget.questionId),
            ],
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(message: e.toString()),
      ),
    );
  }

  Widget _buildAnswersHeader(AsyncValue answersAsync) {
    final count = answersAsync.valueOrNull?.length ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Text(
            '$count ${count == 1 ? 'Answer' : 'Answers'}',
            style: AppTextStyles.headlineSmall,
          ),
          const Spacer(),
          if (count > 1)
            Row(
              children: [
                const Icon(Icons.sort_rounded,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text('By votes', style: AppTextStyles.labelSmall),
              ],
            ),
        ],
      ),
    );
  }

  Widget _avatarCircle(String? handle) {
    final initials =
        handle != null && handle.isNotEmpty ? handle[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 12,
      backgroundColor: AppColors.primary.withOpacity(0.25),
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryLight,
        ),
      ),
    );
  }
}
