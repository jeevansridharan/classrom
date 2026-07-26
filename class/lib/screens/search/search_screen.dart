// lib/screens/search/search_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/question_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_shimmer.dart';
import '../home/question_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final selectedTag = ref.watch(selectedTagProvider);
    final resultsAsync = ref.watch(searchResultsProvider);
    final tagsAsync = ref.watch(popularTagsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _ctrl,
              focusNode: _focusNode,
              autofocus: false,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Search questions by keyword...',
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textMuted),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: AppColors.textMuted),
                        onPressed: () {
                          _ctrl.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
              onChanged: (v) {
                ref.read(searchQueryProvider.notifier).state = v;
              },
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // ── Tag filter ──────────────────────────────────────────────────
          tagsAsync.when(
            data: (tags) => SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Text('Browse by Subject',
                        style: AppTextStyles.titleMedium),
                  ),
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        // All
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _tagButton(
                            ref,
                            label: 'All',
                            selected: selectedTag == null,
                            onTap: () => ref
                                .read(selectedTagProvider.notifier)
                                .state = null,
                          ),
                        ),
                        ...tags.map(
                          (tag) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _tagButton(
                              ref,
                              label: tag,
                              selected: selectedTag == tag,
                              onTap: () => ref
                                  .read(selectedTagProvider.notifier)
                                  .state = selectedTag == tag ? null : tag,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                ],
              ),
            ),
            loading: () => const SliverToBoxAdapter(child: SizedBox()),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
          ),

          // ── Results count ────────────────────────────────────────────────
          if (query.isNotEmpty || selectedTag != null)
            resultsAsync.when(
              data: (results) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    '${results.length} result${results.length != 1 ? 's' : ''}${query.isNotEmpty ? ' for "$query"' : ''}',
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ),
              loading: () => const SliverToBoxAdapter(child: SizedBox()),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
            ),

          // ── Results list ─────────────────────────────────────────────────
          if (query.isEmpty && selectedTag == null)
            SliverFillRemaining(
              child: _buildStartSearchState(),
            )
          else
            resultsAsync.when(
              data: (results) {
                if (results.isEmpty) {
                  return SliverFillRemaining(
                    child: EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No results found',
                      subtitle:
                          'Try different keywords or browse by subject tag.',
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      if (i == results.length) {
                        return const SizedBox(height: 80);
                      }
                      return QuestionCard(question: results[i]);
                    },
                    childCount: results.length + 1,
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: QuestionListShimmer(count: 4),
              ),
              error: (e, _) => SliverFillRemaining(
                child: ErrorState(message: e.toString()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tagButton(
    WidgetRef ref, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.25)
              : AppColors.tagBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primaryLight : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.primaryLight : AppColors.tagText,
          ),
        ),
      ),
    );
  }

  Widget _buildStartSearchState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.2),
                    AppColors.primaryLight.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_rounded,
                size: 40,
                color: AppColors.primaryLight,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Find Answers',
              style: AppTextStyles.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Search by keywords, subject, or browse the tag list above to find what you need.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
