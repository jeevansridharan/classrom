// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/question_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leaderboard_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/reputation_badge.dart';
import '../../widgets/tag_chip.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return profileAsync.when(
      data: (user) {
        if (user == null) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Sign In'),
              ),
            ),
          );
        }

        final questionsAsync = ref.watch(userQuestionsProvider(user.uid));
        final answerCountAsync =
            ref.watch(userAnswersCountProvider(user.uid));

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                tooltip: 'Sign Out',
                onPressed: () => _confirmSignOut(context),
              ),
            ],
          ),
          body: NestedScrollView(
            headerSliverBuilder: (ctx, _) => [
              SliverToBoxAdapter(
                child: _buildHeader(user, answerCountAsync),
              ),
              SliverToBoxAdapter(
                child: _buildTabBar(),
              ),
            ],
            body: TabBarView(
              controller: _tabCtrl,
              children: [
                // ── Questions tab ─────────────────────────────────────────
                questionsAsync.when(
                  data: (questions) => _buildQuestionsList(questions),
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (e, _) => ErrorState(message: e.toString()),
                ),

                // ── Stats tab ─────────────────────────────────────────────
                _buildStatsTab(user, answerCountAsync),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: ErrorState(message: e.toString()),
      ),
    );
  }

  Widget _buildHeader(user, AsyncValue<int> answerCountAsync) {
    final answerCount = answerCountAsync.valueOrNull ?? 0;

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
          // Avatar + handle
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primary.withOpacity(0.4),
                child: Text(
                  user.handle[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(user.handle,
                            style: AppTextStyles.headlineSmall),
                        const SizedBox(width: 8),
                        const Icon(Icons.shield_outlined,
                            size: 16, color: AppColors.primaryLight),
                      ],
                    ),
                    Text(
                      user.reputationTier,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Member since ${_formatDate(user.createdAt)}',
                      style: AppTextStyles.labelSmall,
                    ),
                  ],
                ),
              ),
              ReputationBadge(
                  points: user.reputationPoints,
                  showTier: true,
                  large: true),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statItem(
                  icon: Icons.help_outline_rounded,
                  label: 'Questions',
                  value: '—'),
              _verticalDivider(),
              _statItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Answers',
                  value: '$answerCount'),
              _verticalDivider(),
              _statItem(
                  icon: Icons.star_border_rounded,
                  label: 'Points',
                  value: '${user.reputationPoints}'),
            ],
          ),
          const SizedBox(height: 8),

          // Anonymity note
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  'Your posts are shown anonymously to classmates.',
                  style: AppTextStyles.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: TabBar(
        controller: _tabCtrl,
        tabs: const [
          Tab(text: 'My Questions'),
          Tab(text: 'Stats'),
        ],
      ),
    );
  }

  Widget _buildQuestionsList(List<QuestionModel> questions) {
    if (questions.isEmpty) {
      return const EmptyState(
        icon: Icons.help_outline_rounded,
        title: 'No questions yet',
        subtitle: 'Start asking doubts to build your profile.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: questions.length,
      itemBuilder: (ctx, i) {
        final q = questions[i];
        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: q.isResolved
                  ? AppColors.accent.withOpacity(0.15)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              q.isResolved
                  ? Icons.check_circle_outline_rounded
                  : Icons.help_outline_rounded,
              color: q.isResolved ? AppColors.accent : AppColors.textMuted,
              size: 20,
            ),
          ),
          title: Text(
            q.title,
            style: AppTextStyles.titleMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Icon(Icons.keyboard_arrow_up_rounded,
                    size: 14, color: AppColors.upvote),
                Text('${q.voteCount}',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.upvote)),
                const SizedBox(width: 8),
                Icon(Icons.chat_bubble_outline_rounded,
                    size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text('${q.answerCount} answers',
                    style: AppTextStyles.labelSmall),
                if (q.tags.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  TagChip(label: q.tags.first),
                ],
              ],
            ),
          ),
          onTap: () => context.push('/question/${q.id}'),
        );
      },
    );
  }

  Widget _buildStatsTab(user, AsyncValue<int> answerCountAsync) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reputation Breakdown',
              style: AppTextStyles.headlineSmall),
          const SizedBox(height: 16),
          _progressTier('Newcomer', 0, 10, user.reputationPoints),
          _progressTier('Learner', 10, 50, user.reputationPoints),
          _progressTier('Contributor', 50, 200, user.reputationPoints),
          _progressTier('Advanced', 200, 500, user.reputationPoints),
          _progressTier('Expert', 500, 1000, user.reputationPoints),
          const SizedBox(height: 24),
          Text('How to earn points', style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),
          ...[
            ('Upvote received on question', '+10'),
            ('Upvote received on answer', '+10'),
            ('Casting an upvote', '+5'),
            ('Answer accepted as best', '+25'),
            ('Downvote received', '-2'),
          ].map(
            (item) => _rewardRow(item.$1, item.$2),
          ),
        ],
      ),
    );
  }

  Widget _progressTier(
    String tier,
    int min,
    int max,
    int current,
  ) {
    final progress = ((current - min) / (max - min)).clamp(0.0, 1.0);
    final isComplete = current >= max;
    final isCurrent = current >= min && current < max;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              tier,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isCurrent
                    ? AppColors.primaryLight
                    : isComplete
                        ? AppColors.accent
                        : AppColors.textMuted,
                fontWeight:
                    isCurrent ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(
                  isComplete ? AppColors.accent : AppColors.primary,
                ),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('$min–$max', style: AppTextStyles.labelSmall),
        ],
      ),
    );
  }

  Widget _rewardRow(String label, String value) {
    final isPositive = value.startsWith('+');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 14,
            color: isPositive ? AppColors.upvote : AppColors.downvote,
          ),
          const SizedBox(width: 8),
          Expanded(
              child: Text(label, style: AppTextStyles.bodyMedium)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isPositive ? AppColors.upvote : AppColors.downvote,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(
      {required IconData icon,
      required String label,
      required String value}) {
    return Column(
      children: [
        Icon(icon, size: 22, color: AppColors.primaryLight),
        const SizedBox(height: 4),
        Text(value,
            style: AppTextStyles.headlineSmall
                .copyWith(color: AppColors.textPrimary)),
        Text(label, style: AppTextStyles.labelSmall),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(width: 1, height: 40, color: AppColors.divider);
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authNotifierProvider.notifier).signOut();
            },
            child: const Text('Sign Out',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
