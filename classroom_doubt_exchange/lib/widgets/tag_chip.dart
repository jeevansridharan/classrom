// lib/widgets/tag_chip.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TagChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final bool removable;
  final VoidCallback? onRemove;

  const TagChip({
    super.key,
    required this.label,
    this.onTap,
    this.selected = false,
    this.removable = false,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: removable ? 8 : 10,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.25)
              : AppColors.tagBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? AppColors.primaryLight : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primaryLight : AppColors.tagText,
                letterSpacing: 0.2,
              ),
            ),
            if (removable) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onRemove,
                child: Icon(
                  Icons.close,
                  size: 12,
                  color: selected
                      ? AppColors.primaryLight
                      : AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class TagChipRow extends StatelessWidget {
  final List<String> tags;
  final String? selectedTag;
  final void Function(String tag)? onTagTap;

  const TagChipRow({
    super.key,
    required this.tags,
    this.selectedTag,
    this.onTagTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: tags
          .map((tag) => TagChip(
                label: tag,
                selected: tag == selectedTag,
                onTap: onTagTap != null ? () => onTagTap!(tag) : null,
              ))
          .toList(),
    );
  }
}
