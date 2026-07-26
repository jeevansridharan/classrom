// lib/screens/home/question_card.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/question_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tag_chip.dart';
import '../../widgets/vote_widget.dart';
import '../../services/vote_service.dart';

class QuestionCard extends StatelessWidget {
  final QuestionModel question;

  const QuestionCard({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/question/${question.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: question.isResolved
                ? AppColors.accent.withOpacity(0.4)
                : AppColors.divider,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top section ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Tags row ───────────────────────────────────────────────
                  if (question.tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TagChipRow(tags: question.tags.take(3).toList()),
                    ),

                  // ── Title ──────────────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          question.title,
                          style: AppTextStyles.titleLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (question.isResolved)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _resolvedBadge(),
                        ),
                    ],
                  ),

                  // ── Body preview ───────────────────────────────────────────
                  if (question.body.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        question.body,
                        style: AppTextStyles.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            const Divider(height: 1),

            // ── Footer ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Vote widget (compact)
                  VoteWidget(
                    targetId: question.id,
                    target: VoteTarget.question,
                    voteCount: question.voteCount,
                    compact: true,
                  ),
                  const SizedBox(width: 14),

                  // Answer count
                  _metaChip(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: '${question.answerCount}',
                    color: question.answerCount > 0
                        ? AppColors.primaryLight
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: 12),

                  // View count
                  _metaChip(
                    icon: Icons.remove_red_eye_outlined,
                    label: '${question.viewCount}',
                    color: AppColors.textMuted,
                  ),
                  const Spacer(),

                  // Author + time
                  Row(
                    children: [
                      _avatarCircle(question.authorHandle),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            question.authorHandle ?? 'Anonymous',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            timeago.format(question.createdAt),
                            style: AppTextStyles.labelSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resolvedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.accent.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              size: 12, color: AppColors.accent),
          const SizedBox(width: 4),
          Text(
            'Solved',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _avatarCircle(String? handle) {
    final initials = handle != null && handle.isNotEmpty
        ? handle[0].toUpperCase()
        : '?';
    return CircleAvatar(
      radius: 12,
      backgroundColor: AppColors.primary.withOpacity(0.3),
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
