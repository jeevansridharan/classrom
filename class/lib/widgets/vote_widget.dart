// lib/widgets/vote_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/question_provider.dart';
import '../services/vote_service.dart';
import '../theme/app_theme.dart';

class VoteWidget extends ConsumerStatefulWidget {
  final String targetId;
  final VoteTarget target;
  final int voteCount;
  final bool compact;

  const VoteWidget({
    super.key,
    required this.targetId,
    required this.target,
    required this.voteCount,
    this.compact = false,
  });

  @override
  ConsumerState<VoteWidget> createState() => _VoteWidgetState();
}

class _VoteWidgetState extends ConsumerState<VoteWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  bool _isVoting = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleVote(int value) async {
    if (_isVoting) return;
    setState(() => _isVoting = true);
    _animController.forward().then((_) => _animController.reverse());
    try {
      await ref.read(voteServiceProvider).vote(
            target: widget.target,
            targetId: widget.targetId,
            value: value,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to vote: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isVoting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final voteAsync = widget.target == VoteTarget.question
        ? ref.watch(questionVoteStreamProvider(widget.targetId))
        : ref.watch(answerVoteStreamProvider(widget.targetId));

    final currentVote = voteAsync.valueOrNull ?? 0;

    if (widget.compact) {
      return _buildCompact(currentVote);
    }
    return _buildFull(currentVote);
  }

  Widget _buildFull(int currentVote) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Upvote
        _VoteButton(
          icon: Icons.keyboard_arrow_up_rounded,
          isActive: currentVote == 1,
          activeColor: AppColors.upvote,
          onTap: () => _handleVote(1),
          size: 28,
        ),
        const SizedBox(height: 4),
        // Vote count
        ScaleTransition(
          scale: _scaleAnim,
          child: Text(
            '${widget.voteCount}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: currentVote == 1
                  ? AppColors.upvote
                  : currentVote == -1
                      ? AppColors.downvote
                      : AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Downvote
        _VoteButton(
          icon: Icons.keyboard_arrow_down_rounded,
          isActive: currentVote == -1,
          activeColor: AppColors.downvote,
          onTap: () => _handleVote(-1),
          size: 28,
        ),
      ],
    );
  }

  Widget _buildCompact(int currentVote) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _VoteButton(
          icon: Icons.keyboard_arrow_up_rounded,
          isActive: currentVote == 1,
          activeColor: AppColors.upvote,
          onTap: () => _handleVote(1),
          size: 20,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            '${widget.voteCount}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: currentVote == 1
                  ? AppColors.upvote
                  : currentVote == -1
                      ? AppColors.downvote
                      : AppColors.textSecondary,
            ),
          ),
        ),
        _VoteButton(
          icon: Icons.keyboard_arrow_down_rounded,
          isActive: currentVote == -1,
          activeColor: AppColors.downvote,
          onTap: () => _handleVote(-1),
          size: 20,
        ),
      ],
    );
  }
}

class _VoteButton extends StatefulWidget {
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;
  final double size;

  const _VoteButton({
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
    required this.size,
  });

  @override
  State<_VoteButton> createState() => _VoteButtonState();
}

class _VoteButtonState extends State<_VoteButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: widget.isActive
                ? widget.activeColor.withOpacity(0.15)
                : _hovered
                    ? AppColors.surfaceVariant
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            widget.icon,
            size: widget.size,
            color: widget.isActive
                ? widget.activeColor
                : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
