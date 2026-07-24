// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/question_provider.dart';
import '../../services/question_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_shimmer.dart';
import 'question_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sort = ref.watch(questionSortProvider);
    final selectedTag = ref.watch(selectedTagProvider);
    final questionsAsync = ref.watch(questionsStreamProvider);
    final tagsAsync = ref.watch(popularTagsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.school_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Doubt Exchange', style: AppTextStyles.titleLarge),
                Text('Your classroom Q&A',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Notifications',
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: _buildSortTabs(context, ref, sort),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryLight,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          ref.invalidate(questionsStreamProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: CustomScrollView(
          slivers: [
            // ── Tag filter chips ──────────────────────────────────────────────
            tagsAsync.when(
              data: (tags) => SliverToBoxAdapter(
                child: _buildTagFilter(ref, tags, selectedTag),
              ),
              loading: () => const SliverToBoxAdapter(child: SizedBox()),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
            ),

            // ── Questions list ────────────────────────────────────────────────
            questionsAsync.when(
              data: (questions) {
                if (questions.isEmpty) {
                  return SliverFillRemaining(
                    child: EmptyState(
                      icon: Icons.help_outline_rounded,
                      title: 'No doubts yet!',
                      subtitle: selectedTag != null
                          ? 'No questions tagged "$selectedTag" yet.'
                          : 'Be the first to post a doubt.',
                      actionLabel: 'Post a Doubt',
                      onAction: () {},
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      if (i == questions.length) {
                        return const SizedBox(height: 100);
                      }
                      return QuestionCard(question: questions[i]);
                    },
                    childCount: questions.length + 1,
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: QuestionListShimmer(count: 5),
              ),
              error: (e, _) => SliverFillRemaining(
                child: ErrorState(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(questionsStreamProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortTabs(
    BuildContext context,
    WidgetRef ref,
    QuestionSortOrder current,
  ) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          _SortTab(
            label: 'Recent',
            icon: Icons.access_time_rounded,
            selected: current == QuestionSortOrder.recent,
            onTap: () => ref.read(questionSortProvider.notifier).state =
                QuestionSortOrder.recent,
          ),
          _SortTab(
            label: 'Top Voted',
            icon: Icons.trending_up_rounded,
            selected: current == QuestionSortOrder.topVoted,
            onTap: () => ref.read(questionSortProvider.notifier).state =
                QuestionSortOrder.topVoted,
          ),
          _SortTab(
            label: 'Unanswered',
            icon: Icons.question_mark_rounded,
            selected: current == QuestionSortOrder.unanswered,
            onTap: () => ref.read(questionSortProvider.notifier).state =
                QuestionSortOrder.unanswered,
          ),
        ],
      ),
    );
  }

  Widget _buildTagFilter(
    WidgetRef ref,
    List<String> tags,
    String? selectedTag,
  ) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // "All" chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () =>
                  ref.read(selectedTagProvider.notifier).state = null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: selectedTag == null
                      ? AppColors.primary.withOpacity(0.25)
                      : AppColors.tagBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: selectedTag == null
                        ? AppColors.primaryLight
                        : Colors.transparent,
                  ),
                ),
                child: Text(
                  'All',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selectedTag == null
                        ? AppColors.primaryLight
                        : AppColors.tagText,
                  ),
                ),
              ),
            ),
          ),
          ...tags.map(
            (tag) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => ref.read(selectedTagProvider.notifier).state =
                    selectedTag == tag ? null : tag,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: selectedTag == tag
                        ? AppColors.primary.withOpacity(0.25)
                        : AppColors.tagBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: selectedTag == tag
                          ? AppColors.primaryLight
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: selectedTag == tag
                          ? AppColors.primaryLight
                          : AppColors.tagText,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SortTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SortTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? AppColors.primaryLight : AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected
                      ? AppColors.primaryLight
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
