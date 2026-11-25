part of '../main.dart';

// ------------------------------------------------------------
// ISKOLARIUM - PROFILE SCREEN
// ------------------------------------------------------------

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color _blue = AppColors.primary;
  static const Color _navy = AppColors.textPrimary;
  static const Color _muted = AppColors.textSecondary;
  static const Color _background = AppColors.background;
  static const Color _border = AppColors.border;
  static const Color _ice = AppColors.primaryLight;

  UserProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await AuthService.getCurrentProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _editPersonalInfo() async {
    final controller = TextEditingController(text: _profile?.fullName ?? '');
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Personal information',
            style: TextStyle(
              color: _navy,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 2) {
                      return 'Please enter your full name.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  'Email: ${_profile?.email ?? AuthService.currentUser?.email ?? ''}',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'Role: ${(_profile?.role ?? 'student').toUpperCase()}',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel', style: TextStyle(color: _muted)),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text(
                'Save',
                style: TextStyle(color: _blue, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    if (saved == true) {
      try {
        final updated = await AuthService.updateProfile(
          fullName: controller.text,
        );
        if (!mounted) return;
        setState(() => _profile = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated.')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(formatSupabaseError(e))),
        );
      }
    }
    controller.dispose();
  }

  Future<void> _editNotificationPreferences() async {
    final prefs = Map<String, dynamic>.from(
      _profile?.notificationPreferences ??
          {'tasks': true, 'events': true, 'classes': true},
    );
    bool tasks = prefs['tasks'] != false;
    bool events = prefs['events'] != false;
    bool classes = prefs['classes'] != false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Notification preferences',
                style: TextStyle(
                  color: _navy,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('Class updates'),
                    value: classes,
                    onChanged: (v) => setDialogState(() => classes = v),
                  ),
                  SwitchListTile(
                    title: const Text('Task deadlines'),
                    value: tasks,
                    onChanged: (v) => setDialogState(() => tasks = v),
                  ),
                  SwitchListTile(
                    title: const Text('Calendar events'),
                    value: events,
                    onChanged: (v) => setDialogState(() => events = v),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel', style: TextStyle(color: _muted)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text(
                    'Save',
                    style: TextStyle(color: _blue, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true && _profile != null) {
      try {
        final updated = await AuthService.updateProfile(
          fullName: _profile!.fullName,
          notificationPreferences: {
            'tasks': tasks,
            'events': events,
            'classes': classes,
          },
        );
        if (!mounted) return;
        setState(() => _profile = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification preferences saved.')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(formatSupabaseError(e))),
        );
      }
    }
  }

  Future<void> _showSecurityDialog() async {
    final email = _profile?.email.isNotEmpty == true
        ? _profile!.email
        : (AuthService.currentUser?.email ?? '');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Privacy and security',
            style: TextStyle(
              color: _navy,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Signed in as $email.\nYou can request a password reset email anytime.',
            style: const TextStyle(color: _muted, fontSize: 13, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close', style: TextStyle(color: _muted)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                if (email.isEmpty) return;
                try {
                  await AuthService.sendPasswordReset(email);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Password reset sent to $email.')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(formatSupabaseError(e))),
                  );
                }
              },
              child: const Text(
                'Send Password Reset',
                style: TextStyle(color: _blue, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showHelpDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Help and support',
            style: TextStyle(
              color: _navy,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Use your class enrollment code on the Classes tab to join an official class. Contact your instructor for class codes or attendance questions.',
            style: TextStyle(color: _muted, fontSize: 13, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Got it',
                style: TextStyle(color: _blue, fontWeight: FontWeight.w700),
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

    if (shouldLogout == true) {
      await AuthService.signOut();
      if (context.mounted) {
        IskolariumApp.navigateToWelcome(context);
      }
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
                        onTap: _editPersonalInfo,
                      ),

                      ProfileOption(
                        icon: Icons.notifications_active_outlined,
                        title: 'Notification preferences',
                        subtitle: 'Manage your notification settings',
                        onTap: _editNotificationPreferences,
                      ),

                      ProfileOption(
                        icon: Icons.shield_outlined,
                        title: 'Privacy and security',
                        subtitle: 'Manage your account security',
                        onTap: _showSecurityDialog,
                      ),

                      ProfileOption(
                        icon: Icons.support_agent_rounded,
                        title: 'Help and support',
                        subtitle: 'Get assistance with Iskolarium',
                        onTap: _showHelpDialog,
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

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _loading
                      ? 'Loading...'
                      : (_profile?.fullName.isNotEmpty == true
                          ? _profile!.fullName
                          : 'Student Account'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _profile?.email.isNotEmpty == true
                      ? _profile!.email
                      : (AuthService.currentUser?.email ?? 'Account details'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 9),
                const _StudentRoleBadge(),
              ],
            ),
          ),

          const SizedBox(width: 4),

          IconButton(
            tooltip: 'Edit profile',
            onPressed: _editPersonalInfo,
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