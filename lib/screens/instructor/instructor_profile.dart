import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_client_provider.dart';
import '../../src/app_colors.dart';
import '../../src/design_system.dart';

/// Instructor profile screen for Iskolarium.
class InstructorProfile extends StatefulWidget {
  const InstructorProfile({super.key});

  @override
  State<InstructorProfile> createState() => _InstructorProfileState();
}

class _InstructorProfileState extends State<InstructorProfile> {
  static const Color _blue = AppColors.primary;
  static const Color _navy = AppColors.navy;
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
                  'Role: ${(_profile?.role ?? 'instructor').toUpperCase()}',
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
    bool classes = prefs['classes'] != false;
    bool tasks = prefs['tasks'] != false;

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
                    title: const Text('Class & enrollment alerts'),
                    value: classes,
                    onChanged: (v) => setDialogState(() => classes = v),
                  ),
                  SwitchListTile(
                    title: const Text('Activity reminders'),
                    value: tasks,
                    onChanged: (v) => setDialogState(() => tasks = v),
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
            ..._profile!.notificationPreferences,
            'classes': classes,
            'tasks': tasks,
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
            'Create official classes from the Classes tab, share the generated join code with students, and manage attendance, scores, and announcements.',
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 35),
        child: ResponsiveContainer(
          maxWidth: 760,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AcademicPageHeader(
                eyebrow: 'Instructor Account',
                title: 'Profile & Preferences',
                subtitle: 'Manage your account details and session.',
              ),
              SurfacePanel(
                padding: const EdgeInsets.all(20),
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
                        onTap: _editPersonalInfo,
                      ),

                      _ProfileOption(
                        icon: Icons.notifications_active_outlined,
                        title: 'Notification preferences',
                        subtitle: 'Manage your notification settings',
                        onTap: _editNotificationPreferences,
                      ),

                      _ProfileOption(
                        icon: Icons.shield_outlined,
                        title: 'Privacy and security',
                        subtitle: 'Review your account security',
                        onTap: _showSecurityDialog,
                      ),

                      _ProfileOption(
                        icon: Icons.support_agent_rounded,
                        title: 'Help and support',
                        subtitle: 'Get assistance using Iskolarium',
                        onTap: _showHelpDialog,
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
            ],
          ),
        ),
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

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _loading
                      ? 'Loading...'
                      : (_profile?.fullName.isNotEmpty == true
                          ? _profile!.fullName
                          : 'Instructor Account'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  _profile?.email.isNotEmpty == true
                      ? _profile!.email
                      : (AuthService.currentUser?.email ?? 'Instructor account'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 8),

                const _InstructorRoleBadge(),
              ],
            ),
          ),

          const SizedBox(width: 4),

          InkWell(
            onTap: _editPersonalInfo,
            borderRadius: BorderRadius.circular(11),
            child: Container(
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
        onTap: () async {
          await AuthService.signOut();
          if (context.mounted) {
            IskolariumApp.navigateToWelcome(context);
          }
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