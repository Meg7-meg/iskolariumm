part of '../main.dart';

// ============================================================
// ISKOLARIUM — REUSABLE UI COMPONENTS
// Shared visual components using the central AppColors palette.
// ============================================================

// ------------------------------------------------------------
// SCREEN HEADING
// ------------------------------------------------------------

class ScreenHeading extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onAction;
  final IconData actionIcon;

  const ScreenHeading({
    super.key,
    required this.title,
    required this.subtitle,
    this.onAction,
    this.actionIcon = LucideIcons.plus,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    letterSpacing: -0.55,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (onAction != null)
            Material(
              color: AppColors.primaryLight,
              shape: const CircleBorder(
                side: BorderSide(color: AppColors.border),
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onAction,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(actionIcon, color: AppColors.primary, size: 21),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// SECTION TITLE
// ------------------------------------------------------------

class SectionTitle extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback? onTap;

  const SectionTitle({
    super.key,
    required this.title,
    required this.action,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: -0.2,
              ),
            ),
          ),
          if (action.isNotEmpty)
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                child: Text(
                  action,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// OUTLINE CARD
// ------------------------------------------------------------

class OutlineCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color;

  const OutlineCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(13),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? Theme.of(context).colorScheme.surface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF414852) : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: isDark ? 0.08 : 0.035),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ------------------------------------------------------------
// SEMANTIC BADGE
// Reusable status badge for deadlines, attendance, and tasks.
// ------------------------------------------------------------

class SemanticBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? backgroundColor;
  final Color? borderColor;
  final IconData? icon;
  final double fontSize;

  const SemanticBadge({
    super.key,
    required this.label,
    required this.color,
    this.backgroundColor,
    this.borderColor,
    this.icon,
    this.fontSize = 11,
  });

  // Convenient presets.
  factory SemanticBadge.danger({
    Key? key,
    required String label,
    IconData? icon,
  }) {
    return SemanticBadge(
      key: key,
      label: label,
      color: AppColors.dangerDark,
      backgroundColor: AppColors.dangerLight,
      borderColor: AppColors.dangerBorder,
      icon: icon,
    );
  }

  factory SemanticBadge.warning({
    Key? key,
    required String label,
    IconData? icon,
  }) {
    return SemanticBadge(
      key: key,
      label: label,
      color: AppColors.warningDark,
      backgroundColor: AppColors.warningLight,
      borderColor: AppColors.warningBorder,
      icon: icon,
    );
  }

  factory SemanticBadge.success({
    Key? key,
    required String label,
    IconData? icon,
  }) {
    return SemanticBadge(
      key: key,
      label: label,
      color: AppColors.successDark,
      backgroundColor: AppColors.successLight,
      borderColor: AppColors.successBorder,
      icon: icon,
    );
  }

  factory SemanticBadge.info({
    Key? key,
    required String label,
    IconData? icon,
  }) {
    return SemanticBadge(
      key: key,
      label: label,
      color: AppColors.infoDark,
      backgroundColor: AppColors.infoLight,
      borderColor: AppColors.infoBorder,
      icon: icon,
    );
  }

  factory SemanticBadge.study({
    Key? key,
    required String label,
    IconData? icon,
  }) {
    return SemanticBadge(
      key: key,
      label: label,
      color: AppColors.studyDark,
      backgroundColor: AppColors.studyLight,
      borderColor: AppColors.studyBorder,
      icon: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// SEMANTIC ACTION BUTTON
// Reusable colored actions such as Delete, Save, and Complete.
// ------------------------------------------------------------

class SemanticActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final bool filled;
  final bool compact;

  const SemanticActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.color,
    this.icon,
    this.filled = true,
    this.compact = false,
  });

  factory SemanticActionButton.delete({
    Key? key,
    required VoidCallback? onPressed,
    String label = 'Delete',
    bool compact = false,
  }) {
    return SemanticActionButton(
      key: key,
      label: label,
      onPressed: onPressed,
      color: AppColors.danger,
      icon: LucideIcons.trash2,
      filled: false,
      compact: compact,
    );
  }

  factory SemanticActionButton.primary({
    Key? key,
    required VoidCallback? onPressed,
    String label = 'Save',
    IconData? icon,
    bool compact = false,
  }) {
    return SemanticActionButton(
      key: key,
      label: label,
      onPressed: onPressed,
      color: AppColors.primary,
      icon: icon,
      filled: true,
      compact: compact,
    );
  }

  factory SemanticActionButton.success({
    Key? key,
    required VoidCallback? onPressed,
    String label = 'Complete',
    IconData? icon,
    bool compact = false,
  }) {
    return SemanticActionButton(
      key: key,
      label: label,
      onPressed: onPressed,
      color: AppColors.success,
      icon: icon ?? LucideIcons.circleCheck,
      filled: false,
      compact: compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;

    return Material(
      color: filled
          ? (isDisabled ? AppColors.disabled : color)
          : (isDisabled
                ? AppColors.surfaceSoft
                : color.withValues(alpha: 0.08)),
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 15,
            vertical: compact ? 8 : 11,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: filled
                ? null
                : Border.all(
                    color: isDisabled
                        ? AppColors.border
                        : color.withValues(alpha: 0.25),
                  ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: compact ? 15 : 17,
                  color: filled
                      ? Colors.white
                      : (isDisabled ? AppColors.textMuted : color),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: filled
                      ? Colors.white
                      : (isDisabled ? AppColors.textMuted : color),
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// FILTER BAR
// ------------------------------------------------------------

class FilterBar extends StatelessWidget {
  final List<String> labels;
  final String selected;
  final ValueChanged<String> onSelected;

  const FilterBar({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (final label in labels)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelected(label),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected == label
                        ? AppColors.surface
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    border: selected == label
                        ? Border.all(
                            color: AppColors.primary.withValues(alpha: 0.16),
                          )
                        : null,
                    boxShadow: selected == label
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              blurRadius: 7,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected == label
                          ? AppColors.primaryDark
                          : AppColors.textSecondary,
                      fontWeight: selected == label
                          ? FontWeight.w800
                          : FontWeight.w500,
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

// ------------------------------------------------------------
// SUMMARY CARD
// ------------------------------------------------------------

class SummaryCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color accentColor;

  const SummaryCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.accentColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: accentColor.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 33,
            height: 33,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.10),
                  blurRadius: 7,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: accentColor,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// HOME SCHEDULE ROW
// ------------------------------------------------------------

class HomeScheduleRow extends StatelessWidget {
  final String time;
  final String period;
  final String title;
  final String details;
  final bool isNow;

  const HomeScheduleRow({
    super.key,
    required this.time,
    required this.period,
    required this.title,
    required this.details,
    required this.isNow,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 62,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                Text(
                  period,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  details,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isNow)
            SemanticBadge.success(label: 'Now', icon: LucideIcons.circleDot)
          else
            const Icon(
              LucideIcons.chevronRight,
              color: AppColors.textMuted,
              size: 20,
            ),
        ],
      ),
    );
  }
}
