import 'package:flutter/material.dart';
import '../../src/app_colors.dart';

/// Instructor profile screen for Iskolarium.
class InstructorProfile extends StatelessWidget {
  const InstructorProfile({super.key});

  static const Color _blue = AppColors.primary;
  static const Color _navy = AppColors.navy;
  static const Color _muted = AppColors.textSecondary;
  static const Color _background = AppColors.background;
  static const Color _border = AppColors.border;
  static const Color _ice = AppColors.primaryLight;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _background,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 35),
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // BLUE HEADER
              Container(
                height: 220,
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.primaryGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INSTRUCTOR ACCOUNT',
                      style: TextStyle(
                        color: Color(0xFFDCE8FF),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 13),
                    Text(
                      'Your Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.7,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Manage your instructor account',
                      style: TextStyle(
                        color: Color(0xFFDCE8FF),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // WHITE PROFILE PANEL
              Padding(
                padding: const EdgeInsets.only(top: 166),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15),
                  padding: const EdgeInsets.fromLTRB(17, 20, 17, 22),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: _border),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navy.withValues(alpha: 0.07),
                        blurRadius: 22,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileCard(),

                      const SizedBox(height: 26),

                      _buildSectionHeader(),

                      const SizedBox(height: 13),

                      _ProfileOption(
                        icon: Icons.badge_outlined,
                        title: 'Personal information',
                        subtitle: 'Manage your instructor details',
                        onTap: () => _showNotAvailable(context),
                      ),

                      _ProfileOption(
                        icon: Icons.notifications_active_outlined,
                        title: 'Notification preferences',
                        subtitle: 'Manage your notification settings',
                        onTap: () => _showNotAvailable(context),
                      ),

                      _ProfileOption(
                        icon: Icons.shield_outlined,
                        title: 'Privacy and security',
                        subtitle: 'Review your account security',
                        onTap: () => _showNotAvailable(context),
                      ),

                      _ProfileOption(
                        icon: Icons.support_agent_rounded,
                        title: 'Help and support',
                        subtitle: 'Get assistance using Iskolarium',
                        onTap: () => _showNotAvailable(context),
                      ),

                      const SizedBox(height: 8),

                      _buildLogout(context),

                      const SizedBox(height: 22),

                      const Center(
                        child: Text(
                          'ISKOLARIUM  ·  YOUR ACADEMIC COMPANION',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.05,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROFILE CARD
  // ============================================================

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: _ice,
              borderRadius: BorderRadius.circular(19),
            ),
            child: const Icon(
              Icons.account_circle_rounded,
              color: _blue,
              size: 39,
            ),
          ),

          const SizedBox(width: 13),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dr. Maya Anderson',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'Instructor account',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _muted,
                    fontSize: 11,
                  ),
                ),

                SizedBox(height: 8),

                _InstructorRoleBadge(),
              ],
            ),
          ),

          const SizedBox(width: 4),

          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _ice,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.edit_rounded,
              color: _blue,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _buildSectionHeader() {
    return const Row(
      children: [
        SizedBox(
          width: 4,
          height: 19,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _blue,
              borderRadius: BorderRadius.all(
                Radius.circular(5),
              ),
            ),
          ),
        ),

        SizedBox(width: 10),

        Text(
          'Account settings',
          style: TextStyle(
            color: _navy,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Widget _buildLogout(BuildContext context) {
    return Material(
      color: AppColors.dangerLight,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: () {
          Navigator.popUntil(
            context,
            (route) => route.isFirst,
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: AppColors.dangerBorder,
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: AppColors.danger,
                size: 20,
              ),

              SizedBox(width: 12),

              Expanded(
                child: Text(
                  'Log out',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.danger,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PLACEHOLDER ACTION
  // ============================================================

  void _showNotAvailable(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'This option is not connected yet.',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(15),
      ),
    );
  }
}

// ============================================================
// INSTRUCTOR ROLE BADGE
// ============================================================

class _InstructorRoleBadge extends StatelessWidget {
  const _InstructorRoleBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Instructor',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ============================================================
// PROFILE OPTION
// ============================================================

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: 19,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                  size: 21,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}