// lib/screens/classroom/classroom_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/classroom_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import 'join_classroom_screen.dart';

class ClassroomListScreen extends ConsumerWidget {
  const ClassroomListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userClassroomsAsync = ref.watch(userClassroomsProvider);
    final selectedClassroom = ref.watch(selectedClassroomProvider);
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Classrooms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_rounded),
            tooltip: 'Join via Code',
            onPressed: () => JoinClassroomDialog.show(context),
          ),
          currentUserAsync.maybeWhen(
            data: (user) => user?.isFaculty == true
                ? IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    tooltip: 'Create Classroom',
                    onPressed: () => context.push('/create-classroom'),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: userClassroomsAsync.when(
        data: (classrooms) {
          if (classrooms.isEmpty) {
            return EmptyState(
              icon: Icons.school_outlined,
              title: 'No Classrooms Joined',
              subtitle: 'Join a classroom using a 6-character code from your teacher, or create your own!',
              actionLabel: 'Join Classroom',
              onAction: () => JoinClassroomDialog.show(context),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Option: All Classrooms (Global View) ────────────────────────
              Card(
                color: selectedClassroom == null
                    ? AppColors.primary.withOpacity(0.2)
                    : AppColors.cardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: selectedClassroom == null
                        ? AppColors.primary
                        : AppColors.divider,
                    width: selectedClassroom == null ? 2 : 1,
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: selectedClassroom == null
                        ? AppColors.primary
                        : AppColors.surfaceVariant,
                    child: const Icon(Icons.all_inclusive_rounded, color: Colors.white),
                  ),
                  title: const Text('All Classrooms Feed', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('View doubts from all your joined communities'),
                  trailing: selectedClassroom == null
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryLight)
                      : null,
                  onTap: () {
                    ref.read(selectedClassroomProvider.notifier).state = null;
                    context.pop();
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'ENROLLED CLASSROOMS',
                style: AppTextStyles.labelSmall.copyWith(
                  letterSpacing: 1.2,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              ...classrooms.map((c) {
                final isSelected = selectedClassroom?.id == c.id;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.15)
                      : AppColors.cardBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected ? AppColors.primaryLight : AppColors.divider,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: isSelected ? AppColors.primary : AppColors.tagBg,
                      child: Text(
                        c.name.isNotEmpty ? c.name[0].toUpperCase() : 'C',
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.primaryLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(c.name, style: AppTextStyles.titleMedium),
                    subtitle: Text(
                      'Code: ${c.code} • ${c.memberCount} members • ${c.questionCount} doubts',
                      style: AppTextStyles.caption,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.space_dashboard_rounded, color: AppColors.primaryLight),
                          tooltip: 'Open Dashboard',
                          onPressed: () => context.push('/classroom/${c.id}'),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded, color: AppColors.primaryLight),
                      ],
                    ),
                    onTap: () {
                      ref.read(selectedClassroomProvider.notifier).state = c;
                      context.pop();
                    },
                  ),
                );
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(message: e.toString()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => JoinClassroomDialog.show(context),
        icon: const Icon(Icons.group_add_rounded),
        label: const Text('Join Code'),
      ),
    );
  }
}
