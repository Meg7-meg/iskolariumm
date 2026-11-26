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
  static const Color _border = AppColors.border;
  static const Color _ice = AppColors.primaryLight;
  static const Color _logoutFill = Color(0xFFFEF2F2);
  static const Color _logoutBorder = Color(0xFFFECACA);
  static const Color _logoutText = Color(0xFFDC2626);

  UserProfile? _profile;
  bool _loading = true;
  String? _profileError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _profileError = null;
      });
    }

    try {
      final profile = await AuthService.getCurrentProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _profileError = formatSupabaseError(error);
        });
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
            'Personal Information',
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
                      return 'Enter your full name.';
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
          const SnackBar(content: Text('Account settings updated.')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(formatSupabaseError(e))));
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
                    title: const Text('Course Updates'),
                    value: classes,
                    onChanged: (v) => setDialogState(() => classes = v),
                  ),
                  SwitchListTile(
                    title: const Text('Submission and Personal Task Reminders'),
                    value: tasks,
                    onChanged: (v) => setDialogState(() => tasks = v),
                  ),
                  SwitchListTile(
                    title: const Text('Calendar Events'),
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
                    'Save Changes',
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(formatSupabaseError(e))));
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
            style: TextStyle(color: _muted, fontSize: 13, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel', style: TextStyle(color: _muted)),
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
    return ResponsiveContainer(
      maxWidth: 920,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.xxxl + 62),
        children: [
          const AcademicPageHeader(
            eyebrow: 'ACCOUNT',
            title: 'Profile',
            subtitle: 'Manage your personal account and preferences',
          ),
          if (_profileError != null)
            AsyncErrorView(message: _profileError!, onRetry: _loadProfile)
          else
            _buildProfileCard(context),
          const SizedBox(height: AppSpacing.xl),
          _buildSectionHeader(),
          const SizedBox(height: AppSpacing.md),
          ProfileOption(
            icon: LucideIcons.badge,
            title: 'Personal Information',
            subtitle: 'View and update details',
            onTap: _editPersonalInfo,
          ),
          ProfileOption(
            icon: LucideIcons.bellRing,
            title: 'Notification preferences',
            subtitle: 'Manage your notification settings',
            onTap: _editNotificationPreferences,
          ),
          ProfileOption(
            icon: LucideIcons.shield,
            title: 'Privacy and security',
            subtitle: 'Manage your account security',
            onTap: _showSecurityDialog,
          ),
          ProfileOption(
            icon: LucideIcons.headset,
            title: 'Help and support',
            subtitle: 'Get assistance with Iskolarium',
            onTap: _showHelpDialog,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildLogout(context),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: _ice,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.user, color: _blue, size: 28),
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
                  style: const TextStyle(color: _muted, fontSize: 11),
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
            icon: const Icon(LucideIcons.pencil, color: _blue, size: 18),
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
            borderRadius: const BorderRadius.all(Radius.circular(5)),
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
      color: _logoutFill,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: () => _confirmLogout(context),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: _logoutBorder),
          ),
          child: const Row(
            children: [
              Icon(LucideIcons.logOut, color: _logoutText, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Log out',
                  style: TextStyle(
                    color: _logoutText,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(LucideIcons.chevronRight, color: _logoutText, size: 14),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                  child: Icon(icon, color: iconColor, size: 19),
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

                const Icon(LucideIcons.chevronRight, color: _muted, size: 21),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
