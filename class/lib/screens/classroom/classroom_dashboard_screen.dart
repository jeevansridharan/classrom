// lib/screens/classroom/classroom_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/classroom_model.dart';
import '../../models/question_model.dart';
import '../../providers/classroom_provider.dart';
import '../../providers/question_provider.dart';
import '../../theme/app_theme.dart';
import '../home/question_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_shimmer.dart';
import 'join_classroom_screen.dart';

class ClassroomDashboardScreen extends ConsumerStatefulWidget {
  final String classroomId;

  const ClassroomDashboardScreen({
    super.key,
    required this.classroomId,
  });

  @override
  ConsumerState<ClassroomDashboardScreen> createState() => _ClassroomDashboardScreenState();
}

class _ClassroomDashboardScreenState extends ConsumerState<ClassroomDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classroomAsync = ref.watch(classroomDetailsProvider(widget.classroomId));

    return classroomAsync.when(
      data: (classroom) {
        if (classroom == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Classroom')),
            body: const EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Classroom not found',
              subtitle: 'It may have been deleted or archived.',
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  classroom.name,
                  style: AppTextStyles.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Code: ${classroom.code} • ${classroom.memberCount} Members',
                  style: AppTextStyles.caption.copyWith(color: AppColors.primaryLight),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded),
                tooltip: 'Copy Join Code',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: classroom.code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Join Code "${classroom.code}" copied to clipboard!'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Q&A Doubts'),
                Tab(text: 'Knowledge Base'),
                Tab(text: 'Members'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildClassroomQuestionsTab(classroom),
              _buildKnowledgeBaseTab(classroom),
              _buildMembersTab(classroom),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              // Set selected classroom filter, then go to post doubt screen
              ref.read(selectedClassroomProvider.notifier).state = classroom;
              context.push('/post');
            },
            icon: const Icon(Icons.add_comment_rounded),
            label: const Text('Ask Doubt'),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: ErrorState(message: e.toString()),
      ),
    );
  }

  // ── Tab 1: Questions in Classroom ──────────────────────────────────────────
  Widget _buildClassroomQuestionsTab(ClassroomModel classroom) {
    final questionsAsync = ref.watch(questionServiceProvider).questionsStream(
          classroomId: classroom.id,
        );

    return StreamBuilder<List<QuestionModel>>(
      stream: questionsAsync,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingShimmer();
        }

        final questions = snapshot.data ?? [];
        if (questions.isEmpty) {
          return EmptyState(
            icon: Icons.question_answer_outlined,
            title: 'No questions posted yet',
            subtitle: 'Be the first student to ask an academic doubt in ${classroom.name}!',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: questions.length,
          itemBuilder: (context, index) {
            return QuestionCard(
              question: questions[index],
              onTap: () => context.push('/question/${questions[index].id}'),
            );
          },
        );
      },
    );
  }

  // ── Tab 2: Preserved Knowledge Base ─────────────────────────────────────────
  Widget _buildKnowledgeBaseTab(ClassroomModel classroom) {
    final knowledgeAsync = ref.watch(classroomKnowledgeProvider(classroom.id));

    return knowledgeAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return EmptyState(
            icon: Icons.verified_user_outlined,
            title: 'Knowledge Base Empty',
            subtitle: 'When an answer is accepted by the doubt author, it becomes a verified knowledge record.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_rounded, color: AppColors.accent, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            record.questionTitle,
                            style: AppTextStyles.titleMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      record.answerBody,
                      style: AppTextStyles.bodyMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Hash: ${record.contentHash.substring(0, 16)}...',
                            style: AppTextStyles.caption.copyWith(
                              fontFamily: 'monospace',
                              color: AppColors.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/question/${record.questionId}'),
                          child: const Text('View Full Q&A'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorState(message: e.toString()),
    );
  }

  // ── Tab 3: Members List ────────────────────────────────────────────────────
  Widget _buildMembersTab(ClassroomModel classroom) {
    final membersAsync = ref.watch(classroomMembersProvider(classroom.id));

    return membersAsync.when(
      data: (members) {
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: members.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final m = members[index];
            final isFaculty = m.role == 'FACULTY' || m.role == 'MODERATOR';

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isFaculty ? AppColors.secondary : AppColors.primary,
                child: Text(
                  m.userHandle.isNotEmpty ? m.userHandle[0].toUpperCase() : 'M',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(m.userHandle, style: AppTextStyles.titleMedium),
              subtitle: Text(
                'Joined ${_timeAgo(m.joinedAt)}',
                style: AppTextStyles.caption,
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isFaculty
                      ? AppColors.secondary.withOpacity(0.2)
                      : AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  m.role,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isFaculty ? AppColors.secondaryLight : AppColors.primaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorState(message: e.toString()),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'just now';
  }
}
