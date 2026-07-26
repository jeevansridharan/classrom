// lib/screens/leaderboard/leaderboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leaderboard_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/reputation_badge.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final currentUser = ref.watch(currentUserProfileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Leaderboard'),
            Text(
              'Top contributors this week',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
      body: leaderboardAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return const EmptyState(
              icon: Icons.leaderboard_outlined,
              title: 'No contributors yet',
              subtitle: 'Post answers and earn reputation to appear here!',
            );
          }

          // Find current user's rank
          final myRank = currentUser != null
              ? users.indexWhere((u) => u.uid == currentUser.uid) + 1
              : -1;

          return CustomScrollView(
            slivers: [
              // ── Podium (top 3) ─────────────────────────────────────────────
              if (users.length >= 3)
                SliverToBoxAdapter(
                  child: _buildPodium(users.take(3).toList(), currentUser),
                ),

              // ── My rank banner ─────────────────────────────────────────────
              if (myRank > 3 && currentUser != null)
                SliverToBoxAdapter(
                  child: _buildMyRankBanner(
                      currentUser, myRank),
                ),

              // ── Full list ─────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final user = users[i];
                      final rank = i + 1;
                      final isMe = user.uid == currentUser?.uid;
                      return _buildRankRow(
                          context, user, rank, isMe);
                    },
                    childCount: users.length,
                  ),
                ),
              ),
            ],
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(message: e.toString()),
      ),
    );
  }

  Widget _buildPodium(List<UserModel> top3, UserModel? currentUser) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.15),
            AppColors.primaryDark.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Text('🏆  Hall of Fame',
              style: AppTextStyles.headlineSmall
                  .copyWith(color: AppColors.secondary)),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd place
              Expanded(child: _podiumItem(top3[1], 2, 100, currentUser)),
              const SizedBox(width: 8),
              // 1st place
              Expanded(child: _podiumItem(top3[0], 1, 130, currentUser)),
              const SizedBox(width: 8),
              // 3rd place
              Expanded(child: _podiumItem(top3[2], 3, 80, currentUser)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _podiumItem(
    UserModel user,
    int rank,
    double height,
    UserModel? currentUser,
  ) {
    final isMe = user.uid == currentUser?.uid;
    final medalColors = {
      1: const Color(0xFFF59E0B),
      2: const Color(0xFF9CA3AF),
      3: const Color(0xFFB45309),
    };
    final medalEmoji = {1: '🥇', 2: '🥈', 3: '🥉'};
    final color = medalColors[rank]!;

    return Column(
      children: [
        Text(medalEmoji[rank]!, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 6),
        CircleAvatar(
          radius: 24,
          backgroundColor: color.withOpacity(0.3),
          child: Text(
            user.handle[0].toUpperCase(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          user.handle,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isMe ? AppColors.primaryLight : AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${user.reputationPoints}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text('pts',
                    style: TextStyle(fontSize: 10, color: color.withOpacity(0.7))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMyRankBanner(UserModel user, int rank) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Text(
            '#$rank',
            style: AppTextStyles.headlineSmall
                .copyWith(color: AppColors.primaryLight),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your Rank', style: AppTextStyles.labelSmall),
                Text(user.handle,
                    style: AppTextStyles.titleMedium
                        .copyWith(color: AppColors.primaryLight)),
              ],
            ),
          ),
          ReputationBadge(points: user.reputationPoints),
        ],
      ),
    );
  }

  Widget _buildRankRow(
    BuildContext context,
    UserModel user,
    int rank,
    bool isMe,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.primary.withOpacity(0.12)
            : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe
              ? AppColors.primary.withOpacity(0.35)
              : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 32,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: rank <= 3
                    ? _podiumColor(rank)
                    : AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor:
                AppColors.primary.withOpacity(isMe ? 0.4 : 0.2),
            child: Text(
              user.handle[0].toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isMe
                    ? AppColors.primaryLight
                    : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Handle + tier
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.handle,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: isMe
                            ? AppColors.primaryLight
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'You',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  user.reputationTier,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Points
          ReputationBadge(points: user.reputationPoints),
        ],
      ),
    );
  }

  Color _podiumColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFF59E0B);
      case 2:
        return const Color(0xFF9CA3AF);
      case 3:
        return const Color(0xFFB45309);
      default:
        return AppColors.textMuted;
    }
  }
}
