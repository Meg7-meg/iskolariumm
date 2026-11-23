part of '../main.dart';

// ------------------------------------------------------------
// ISKOLARIUM - PROFILE SCREEN
// ------------------------------------------------------------

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const Color _blue = AppColors.primary;
  static const Color _navy = AppColors.textPrimary;
  static const Color _muted = AppColors.textSecondary;
  static const Color _background = AppColors.background;
  static const Color _border = AppColors.border;
  static const Color _ice = AppColors.primaryLight;

  // ------------------------------------------------------------
  // OPTION MESSAGE
  // ------------------------------------------------------------

  void _showOptionMessage(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: _navy,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'This feature is not connected yet.',
            style: TextStyle(
              color: _muted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Got it',
                style: TextStyle(
                  color: _blue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // LOGOUT CONFIRMATION
  // ------------------------------------------------------------

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Log out?',
            style: TextStyle(
              color: _navy,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Are you sure you want to leave your account?',
            style: TextStyle(
              color: _muted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: _muted),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Log out',
                style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true && context.mounted) {
      // This returns to the first screen.
      // Connect this action to Supabase signOut when authentication
      // is integrated into this screen.
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _background,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // BLUE HEADER
              Container(
                height: 220,
                padding: const EdgeInsets.fromLTRB(24, 25, 24, 0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.primaryGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 35,
                          height: 35,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(
                            Icons.person_outline_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'MY ACCOUNT',
                          style: TextStyle(
                            color: Color(0xFFDCE8FF),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 17),
                    const Text(
                      'Your Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.7,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Manage your personal account',
                      style: TextStyle(
                        color: Color(0xFFDCE8FF),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // WHITE CONTENT PANEL
              Padding(
                padding: const EdgeInsets.only(top: 166),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15),
                  padding: const EdgeInsets.fromLTRB(17, 20, 17, 24),
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
                      _buildProfileCard(context),

                      const SizedBox(height: 27),

                      _buildSectionHeader(),

                      const SizedBox(height: 14),

                      ProfileOption(
                        icon: Icons.badge_outlined,
                        title: 'Personal information',
                        subtitle: 'View and update your account details',
                        onTap: () => _showOptionMessage(
                          context,
                          'Personal information',
                        ),
                      ),

                      ProfileOption(
                        icon: Icons.notifications_active_outlined,
                        title: 'Notification preferences',
                        subtitle: 'Manage your notification settings',
                        onTap: () => _showOptionMessage(
                          context,
                          'Notification preferences',
                        ),
                      ),

                      ProfileOption(
                        icon: Icons.shield_outlined,
                        title: 'Privacy and security',
                        subtitle: 'Manage your account security',
                        onTap: () => _showOptionMessage(
                          context,
                          'Privacy and security',
                        ),
                      ),

                      ProfileOption(
                        icon: Icons.support_agent_rounded,
                        title: 'Help and support',
                        subtitle: 'Get assistance with Iskolarium',
                        onTap: () => _showOptionMessage(
                          context,
                          'Help and support',
                        ),
                      ),

                      const SizedBox(height: 12),

                      _buildLogout(context),

                      const SizedBox(height: 24),

                      const Center(
                        child: Column(
                          children: [
                            Text(
                              'ISKOLARIUM',
                              style: TextStyle(
                                color: _navy,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'YOUR ACADEMIC COMPANION',
                              style: TextStyle(
                                color: _muted,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
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

  // ------------------------------------------------------------
  // PROFILE CARD
  // ------------------------------------------------------------

  Widget _buildProfileCard(BuildContext context) {
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
              Icons.person_rounded,
              color: _blue,
              size: 37,
            ),
          ),

          const SizedBox(width: 13),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student Account',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Account details',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _muted,
                    fontSize: 11,
                  ),
                ),
                SizedBox(height: 9),
                _StudentRoleBadge(),
              ],
            ),
          ),

          const SizedBox(width: 4),

          IconButton(
            tooltip: 'Edit profile',
            onPressed: () => _showOptionMessage(
              context,
              'Edit profile',
            ),
            icon: const Icon(
              Icons.edit_rounded,
              color: _blue,
              size: 18,
            ),
            style: IconButton.styleFrom(
              backgroundColor: _ice,
              fixedSize: const Size(38, 38),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SECTION HEADER
  // ------------------------------------------------------------

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Container(
          width: 4,
          height: 19,
          decoration: BoxDecoration(
            color: _blue,
            borderRadius: const BorderRadius.all(
              Radius.circular(5),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
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

  // ------------------------------------------------------------
  // LOGOUT BUTTON
  // ------------------------------------------------------------

  Widget _buildLogout(BuildContext context) {
    return Material(
      color: AppColors.dangerLight,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: () => _confirmLogout(context),
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
}

// ------------------------------------------------------------
// STUDENT ROLE BADGE
// ------------------------------------------------------------

class _StudentRoleBadge extends StatelessWidget {
  const _StudentRoleBadge();

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
        'Student',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// PROFILE OPTION
// ------------------------------------------------------------

class ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? color;

  const ProfileOption({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.color,
  });

  static const Color _blue = AppColors.primary;
  static const Color _navy = AppColors.textPrimary;
  static const Color _border = AppColors.border;
  static const Color _ice = AppColors.primaryLight;
  static const Color _muted = AppColors.textSecondary;

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? _navy;
    final iconColor = color ?? _blue;

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
              vertical: 12,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _ice,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
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
                        style: TextStyle(
                          color: foreground,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 10,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const Icon(
                  Icons.chevron_right_rounded,
                  color: _muted,
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