import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'app_colors.dart';

/// ============================================================
/// ISKOLARIUM — UNIFIED ACADEMIC DESIGN SYSTEM
/// Swiss Design + Modern Minimalist.
/// Single source of truth for spacing, radii, typography,
/// layout primitives, and reusable UI components.
/// ============================================================

// ------------------------------------------------------------
// SPACING — 8-point grid
// ------------------------------------------------------------

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double section = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

// ------------------------------------------------------------
// BORDER RADII
// ------------------------------------------------------------

class AppRadii {
  AppRadii._();

  static const double sm = 4;
  static const double md = 6;
  static const double lg = 8;
  static const double xl = 12;
  static const double full = 999;
}

// ------------------------------------------------------------
// BREAKPOINTS
// ------------------------------------------------------------

class AppBreakpoints {
  AppBreakpoints._();

  static const double tablet = 720;
  static const double desktop = 1024;
  static const double maxContentWidth = 1120;
}

// ------------------------------------------------------------
// TYPOGRAPHY — Named text styles (Swiss Design hierarchy)
// ------------------------------------------------------------

class AppTextStyles {
  AppTextStyles._();

  /// 22px / 700 — Page titles, dashboard headings
  static const TextStyle pageTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  /// 18px / 700 — Section titles, screen headings
  static const TextStyle screenTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  /// 15px / 600 — Section headings within a page
  static const TextStyle sectionHeading = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  /// 14px / 600 — Card headings, row titles
  static const TextStyle cardHeading = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    height: 1.35,
  );

  /// 13px / 400 — Primary body text
  static const TextStyle body = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  /// 13px / 500 — Slightly emphasized body text
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  /// 12px / 400 — Secondary / supporting descriptions
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  /// 11px / 600 / UPPERCASE — Labels, eyebrows, category tags
  static const TextStyle label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AppColors.textSecondary,
  );

  /// 11px / 500 — Timestamps, metadata, secondary context
  static const TextStyle meta = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    color: AppColors.textSecondary,
  );
}

// ------------------------------------------------------------
// RESPONSIVE CONTAINER
// Constrains page content on wide screens; full-width on mobile.
// ------------------------------------------------------------

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = AppBreakpoints.maxContentWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width >= AppBreakpoints.tablet ? 28.0 : 16.0;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? EdgeInsets.symmetric(horizontal: horizontal),
          child: child,
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// PAGE HEADER
// Optional eyebrow label, title, subtitle, and action row.
// ------------------------------------------------------------

class AcademicPageHeader extends StatelessWidget {
  final String? eyebrow;
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final VoidCallback? onBack;

  const AcademicPageHeader({
    super.key,
    this.eyebrow,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.section, bottom: AppSpacing.section),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onBack != null) ...[
            IconButton(
              onPressed: onBack,
              icon: const Icon(LucideIcons.arrowLeft, size: 18),
              tooltip: 'Back',
              style: IconButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null && eyebrow!.isNotEmpty) ...[
                  Text(
                    eyebrow!.toUpperCase(),
                    style: AppTextStyles.label,
                  ),
                  const SizedBox(height: 4),
                ],
                Text(title, style: AppTextStyles.pageTitle),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(width: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// SURFACE PANEL
// Flat 1px-bordered container. Zero elevation, zero shadow.
// Use for cards, sections, and content groupings.
// ------------------------------------------------------------

class SurfacePanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderRadius;

  const SurfacePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius ?? AppRadii.lg),
        border: Border.all(
          color: borderColor ?? AppColors.border,
        ),
      ),
      child: child,
    );
  }
}

// ------------------------------------------------------------
// STATUS BADGE
// Compact semantic status pill.
// ------------------------------------------------------------

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color backgroundColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    required this.backgroundColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ] else ...[
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// SECTION HEADER ROW
// Label + optional trailing action in a consistent row.
// ------------------------------------------------------------

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.only(bottom: AppSpacing.md),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: AppTextStyles.sectionHeading),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// DIVIDER
// Optional label variant for section separators.
// ------------------------------------------------------------

class IskDivider extends StatelessWidget {
  final String? label;
  final EdgeInsetsGeometry margin;

  const IskDivider({
    super.key,
    this.label,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    if (label == null) {
      return Padding(
        padding: margin,
        child: const Divider(height: 1, thickness: 1, color: AppColors.border),
      );
    }
    return Padding(
      padding: margin,
      child: Row(
        children: [
          const Expanded(
            child: Divider(height: 1, thickness: 1, color: AppColors.border),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label!.toUpperCase(),
              style: AppTextStyles.label,
            ),
          ),
          const Expanded(
            child: Divider(height: 1, thickness: 1, color: AppColors.border),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// EMPTY STATE
// Actionable empty state without oversized illustrations.
// ------------------------------------------------------------

class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return SurfacePanel(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, size: 20, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.cardHeading,
          ),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// INLINE ERROR PANEL
// ------------------------------------------------------------

class AsyncErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const AsyncErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return SurfacePanel(
      borderColor: AppColors.dangerBorder,
      backgroundColor: AppColors.dangerLight,
      child: Row(
        children: [
          const Icon(LucideIcons.alertCircle, size: 16, color: AppColors.danger),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.dangerDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// NAVIGATION DESTINATION MODEL
// ------------------------------------------------------------

class AcademicNavDestination {
  final IconData icon;
  final String label;

  const AcademicNavDestination({
    required this.icon,
    required this.label,
  });
}

// ------------------------------------------------------------
// NAVIGATION SHELL
// Responsive:
//   Desktop (>= 1024px) → 220px fixed left sidebar
//   Tablet  (>= 720px)  → compact NavigationRail
//   Mobile  (< 720px)   → bottom NavigationBar
// ------------------------------------------------------------

class AcademicNavigationShell extends StatelessWidget {
  final String roleLabel;
  final List<AcademicNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? sidebarAction;

  const AcademicNavigationShell({
    super.key,
    required this.roleLabel,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.body,
    this.floatingActionButton,
    this.sidebarAction,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width >= AppBreakpoints.desktop) {
      return _DesktopShell(
        roleLabel: roleLabel,
        destinations: destinations,
        selectedIndex: selectedIndex,
        onSelected: onSelected,
        body: body,
        floatingActionButton: floatingActionButton,
        sidebarAction: sidebarAction,
      );
    }

    if (width >= AppBreakpoints.tablet) {
      return _TabletShell(
        destinations: destinations,
        selectedIndex: selectedIndex,
        onSelected: onSelected,
        body: body,
        floatingActionButton: floatingActionButton,
      );
    }

    return _MobileShell(
      destinations: destinations,
      selectedIndex: selectedIndex,
      onSelected: onSelected,
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}

class _DesktopShell extends StatelessWidget {
  final String roleLabel;
  final List<AcademicNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? sidebarAction;

  const _DesktopShell({
    required this.roleLabel,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.body,
    this.floatingActionButton,
    this.sidebarAction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Row(
          children: [
            _Sidebar(
              roleLabel: roleLabel,
              destinations: destinations,
              selectedIndex: selectedIndex,
              onSelected: onSelected,
              sidebarAction: sidebarAction,
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final String roleLabel;
  final List<AcademicNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget? sidebarAction;

  const _Sidebar({
    required this.roleLabel,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    this.sidebarAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand mark
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: const Icon(
                    LucideIcons.graduationCap,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Iskolarium',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        roleLabel,
                        style: AppTextStyles.meta,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (sidebarAction != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: sidebarAction!,
            ),
          ],

          const Divider(height: 1, thickness: 1, color: AppColors.border),
          const SizedBox(height: 6),

          // Nav items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: destinations.length,
              itemBuilder: (context, index) {
                final item = destinations[index];
                final active = index == selectedIndex;
                return _SidebarItem(
                  icon: item.icon,
                  label: item.label,
                  active: active,
                  onTap: () => onSelected(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: active ? AppColors.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: active ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                      color: active ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabletShell extends StatelessWidget {
  final List<AcademicNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget body;
  final Widget? floatingActionButton;

  const _TabletShell({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.body,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              backgroundColor: AppColors.surface,
              selectedIndex: selectedIndex,
              onDestinationSelected: onSelected,
              labelType: NavigationRailLabelType.all,
              indicatorColor: AppColors.primaryLight,
              selectedIconTheme: const IconThemeData(
                color: AppColors.primary,
                size: 20,
              ),
              unselectedIconTheme: const IconThemeData(
                color: AppColors.textSecondary,
                size: 20,
              ),
              selectedLabelTextStyle: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelTextStyle: AppTextStyles.meta,
              destinations: destinations
                  .map(
                    (d) => NavigationRailDestination(
                      icon: Icon(d.icon),
                      label: Text(d.label),
                    ),
                  )
                  .toList(),
            ),
            const VerticalDivider(width: 1, thickness: 1, color: AppColors.border),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _MobileShell extends StatelessWidget {
  final List<AcademicNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget body;
  final Widget? floatingActionButton;

  const _MobileShell({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.body,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: floatingActionButton,
      body: SafeArea(child: body),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          height: 62,
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          indicatorColor: AppColors.primaryLight,
          selectedIndex: selectedIndex,
          onDestinationSelected: onSelected,
          destinations: destinations
              .map(
                (d) => NavigationDestination(
                  icon: Icon(d.icon, color: AppColors.textSecondary, size: 20),
                  selectedIcon: Icon(d.icon, color: AppColors.primary, size: 20),
                  label: d.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
