import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../main.dart';
import '../../services/app_theme_service.dart';
import '../../services/auth_service.dart';
import '../../services/profile_image_service.dart';
import '../../services/supabase_client_provider.dart';
import '../../src/app_colors.dart';
import '../../src/design_system.dart';

class InstructorProfile extends StatefulWidget {
  const InstructorProfile({super.key});

  @override
  State<InstructorProfile> createState() => _InstructorProfileState();
}

class _InstructorProfileState extends State<InstructorProfile> {
  UserProfile? _profile;
  String? _profileImageUrl;
  String? _loadError;
  String? _photoError;
  bool _loading = true;
  bool _photoBusy = false;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _loadError = null;
      _photoError = null;
    });

    try {
      final profile = await AuthService.getCurrentProfile();
      if (profile == null) {
        throw Exception('Your instructor profile could not be found.');
      }

      String? imageUrl;
      String? photoError;
      if (profile.avatarPath != null) {
        try {
          imageUrl = await ProfileImageService.createSignedUrl(
            profile.avatarPath!,
          );
        } catch (error) {
          photoError = formatSupabaseError(error);
        }
      }

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _profileImageUrl = imageUrl;
        _photoError = photoError;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = formatSupabaseError(error);
        _loading = false;
      });
    }
  }

  Future<void> _editPersonalInfo() async {
    final profile = _profile;
    if (profile == null) return;

    final controller = TextEditingController(text: profile.fullName);
    final formKey = GlobalKey<FormState>();
    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Personal Information'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLength: 100,
            decoration: const InputDecoration(labelText: 'Full name'),
            validator: (value) {
              if (value == null || value.trim().length < 2) {
                return 'Enter your full name.';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(dialogContext, 'changePhoto'),
            icon: const Icon(LucideIcons.camera, size: 17),
            label: const Text('Change Photo'),
          ),
          if (profile.avatarPath != null)
            TextButton.icon(
              onPressed: () => Navigator.pop(dialogContext, 'removePhoto'),
              icon: const Icon(LucideIcons.trash2, size: 17),
              label: const Text('Remove Photo'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'cancel'),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, 'save');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    try {
      if (action == 'save') {
        try {
          final updated = await AuthService.updateProfile(
            fullName: controller.text,
          );
          if (!mounted) return;
          setState(() => _profile = updated);
          _showNotice('Profile updated.');
        } catch (error) {
          _showError(error);
        }
      } else if (action == 'changePhoto') {
        await _changePhoto();
      } else if (action == 'removePhoto') {
        await _removePhoto();
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _editNotificationPreferences() async {
    final profile = _profile;
    if (profile == null) return;

    final prefs = profile.notificationPreferences;
    var classes = prefs['classes'] != false;
    var tasks = prefs['tasks'] != false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Notification Preferences'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Class and enrollment alerts'),
                value: classes,
                onChanged: (value) => setDialogState(() => classes = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Task and quiz reminders'),
                value: tasks,
                onChanged: (value) => setDialogState(() => tasks = value),
              ),
              const SizedBox(height: 8),
              Text(
                'Preferences are saved to your profile. Automatic alerts depend on the app notification sources available to your account.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;
    try {
      final updated = await AuthService.updateProfile(
        fullName: profile.fullName,
        notificationPreferences: {
          ...profile.notificationPreferences,
          'classes': classes,
          'tasks': tasks,
        },
      );
      if (!mounted) return;
      setState(() => _profile = updated);
      _showNotice('Notification preferences saved.');
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _showSecurityOptions() async {
    final profile = _profile;
    if (profile == null) return;
    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Privacy and Security'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              profile.email.isEmpty
                  ? 'Manage password access for your account.'
                  : 'Signed in as ${profile.email}.',
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(LucideIcons.keyRound),
              title: const Text('Change password'),
              onTap: () => Navigator.pop(dialogContext, 'change'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(LucideIcons.mailCheck),
              title: const Text('Send password reset email'),
              onTap: () => Navigator.pop(dialogContext, 'reset'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );

    if (action == 'change') {
      await _changePassword();
    } else if (action == 'reset') {
      final email = profile.email.isNotEmpty
          ? profile.email
          : AuthService.currentUser?.email ?? '';
      if (email.isEmpty) {
        _showNotice('No account email is available for a password reset.');
        return;
      }
      try {
        await AuthService.sendPasswordReset(email);
        _showNotice('Password reset email sent.');
      } catch (error) {
        _showError(error);
      }
    }
  }

  Future<void> _changePassword() async {
    final passwordController = TextEditingController();
    final confirmationController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var saving = false;
    String? errorMessage;

    final updated = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New password'),
                  validator: (value) {
                    if (value == null || value.length < 8) {
                      return 'Use at least 8 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmationController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm new password',
                  ),
                  validator: (value) {
                    if (value != passwordController.text) {
                      return 'Passwords do not match.';
                    }
                    return null;
                  },
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving
                  ? null
                  : () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() {
                        saving = true;
                        errorMessage = null;
                      });
                      try {
                        await AuthService.updatePassword(
                          passwordController.text,
                        );
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext, true);
                        }
                      } catch (error) {
                        setDialogState(() {
                          saving = false;
                          errorMessage = formatSupabaseError(error);
                        });
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Update'),
            ),
          ],
        ),
      ),
    );

    passwordController.dispose();
    confirmationController.dispose();
    if (updated == true) _showNotice('Password updated.');
  }

  Future<void> _showHelp() async {
    final report = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Help and Support'),
        content: const Text(
          'Use Classes to manage teaching sections, and open a class to review students, attendance, tasks, and announcements. For account or access issues, contact your school through its existing support channel.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Close'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Report a problem'),
          ),
        ],
      ),
    );

    if (report == true) await _reportProblem();
  }

  Future<void> _reportProblem() async {
    final controller = TextEditingController();
    final copied = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Report a problem'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 3,
          maxLines: 6,
          maxLength: 1000,
          decoration: const InputDecoration(
            hintText: 'Describe what happened',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = _profile?.fullName ?? '';
              final email = _profile?.email.isNotEmpty == true
                  ? _profile!.email
                  : AuthService.currentUser?.email ?? '';
              final details = StringBuffer('Iskolarium problem report\n');
              if (name.isNotEmpty) details.writeln('Name: $name');
              if (email.isNotEmpty) details.writeln('Email: $email');
              details
                ..writeln()
                ..write(controller.text.trim());
              await Clipboard.setData(ClipboardData(text: details.toString()));
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Copy report'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (copied == true) {
      _showNotice(
        'Report copied. Send it through your school’s existing support channel.',
      );
    }
  }

  Future<void> _chooseAppearance() async {
    final profile = _profile;
    if (profile == null) return;
    var selected = AppThemeService.themeMode.value;

    final saved = await showDialog<ThemeMode>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Appearance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final option in ThemeMode.values)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_themeLabel(option)),
                  trailing: Icon(
                    selected == option
                        ? LucideIcons.circleDot
                        : LucideIcons.circle,
                    color: selected == option
                        ? AppColors.primary
                        : AppColors.textMuted,
                  ),
                  onTap: () => setDialogState(() => selected = option),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, selected),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );

    if (saved == null) return;
    try {
      final updated = await AuthService.updateProfile(
        fullName: profile.fullName,
        preferredTheme: AppThemeService.preferenceFor(saved),
      );
      if (!mounted) return;
      setState(() => _profile = updated);
      _showNotice('Appearance preference saved.');
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _showPhotoActions() async {
    if (_photoBusy || _profile == null) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(LucideIcons.images),
              title: const Text('Change Photo'),
              onTap: () => Navigator.pop(context, 'change'),
            ),
            if (_profile!.avatarPath != null)
              ListTile(
                leading: const Icon(
                  LucideIcons.trash2,
                  color: AppColors.danger,
                ),
                title: const Text('Remove Photo'),
                onTap: () => Navigator.pop(context, 'remove'),
              ),
          ],
        ),
      ),
    );

    if (action == 'change') {
      await _changePhoto();
    } else if (action == 'remove') {
      await _removePhoto();
    }
  }

  Future<void> _changePhoto() async {
    if (_profile == null || _photoBusy) return;
    setState(() => _photoBusy = true);
    String? uploadedPath;
    var profileUpdated = false;

    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 4096,
        maxHeight: 4096,
        imageQuality: 90,
        requestFullMetadata: false,
      );
      if (picked == null) return;

      final sourceSize = await picked.length();
      if (sourceSize > 10 * 1024 * 1024) {
        throw Exception(
          'Choose an image no larger than 10 MB before cropping.',
        );
      }
      final sourceBytes = await picked.readAsBytes();
      final sourceType = _detectImageType(sourceBytes);
      if (sourceType == null ||
          !_isSupportedSourceType(sourceType, picked.mimeType, picked.name)) {
        throw Exception('Choose a JPG, JPEG, or PNG image.');
      }

      final bytes = await _cropPhoto(picked);
      if (bytes == null) return;
      final contentType = _detectImageType(bytes);
      if (contentType == null) {
        throw Exception(
          'The selected photo could not be read as a JPG or PNG.',
        );
      }
      if (bytes.lengthInBytes > ProfileImageService.maxPhotoBytes) {
        throw Exception('The cropped image must be no larger than 5 MB.');
      }

      final confirmed = await _confirmPhotoPreview(bytes);
      if (!confirmed) return;

      final oldPath = _profile!.avatarPath;
      uploadedPath = await ProfileImageService.uploadAvatar(
        bytes: bytes,
        contentType: contentType,
      );
      final imageUrl = await ProfileImageService.createSignedUrl(uploadedPath);
      final updated = await AuthService.updateProfile(
        fullName: _profile!.fullName,
        avatarPath: uploadedPath,
      );
      profileUpdated = true;

      if (mounted) {
        setState(() {
          _profile = updated;
          _profileImageUrl = imageUrl;
          _photoError = null;
        });
      }

      String? cleanupWarning;
      if (oldPath != null && oldPath != uploadedPath) {
        try {
          await ProfileImageService.deleteAvatar(oldPath);
        } catch (error) {
          cleanupWarning =
              'Photo updated, but the previous file could not be removed: ${formatSupabaseError(error)}';
        }
      }
      _showNotice(cleanupWarning ?? 'Profile photo updated.');
    } catch (error) {
      if (uploadedPath != null && !profileUpdated) {
        try {
          await ProfileImageService.deleteAvatar(uploadedPath);
        } catch (cleanupError) {
          _showNotice(
            'Temporary photo cleanup failed: ${formatSupabaseError(cleanupError)}',
          );
        }
      }
      _showError(error);
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Future<Uint8List?> _cropPhoto(XFile picked) async {
    final cropSupported =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (!cropSupported) return picked.readAsBytes();

    final uiSettings = <PlatformUiSettings>[
      if (defaultTargetPlatform == TargetPlatform.android)
        AndroidUiSettings(
          toolbarTitle: 'Crop profile photo',
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
      if (defaultTargetPlatform == TargetPlatform.iOS)
        IOSUiSettings(
          title: 'Crop profile photo',
          aspectRatioLockEnabled: true,
        ),
      if (kIsWeb)
        WebUiSettings(
          context: context,
          presentStyle: WebPresentStyle.dialog,
          size: const CropperSize(width: 520, height: 520),
        ),
    ];

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      maxWidth: 2048,
      maxHeight: 2048,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 85,
      uiSettings: uiSettings,
    );
    if (cropped == null) return null;
    return cropped.readAsBytes();
  }

  bool _isSupportedSourceType(
    String detectedType,
    String? mimeType,
    String name,
  ) {
    if (mimeType != null && mimeType.isNotEmpty) {
      if (mimeType == 'image/jpg') return detectedType == 'image/jpeg';
      return mimeType == detectedType;
    }
    final extension = name.split('.').last.toLowerCase();
    return detectedType == 'image/png'
        ? extension == 'png'
        : extension == 'jpg' || extension == 'jpeg';
  }

  String? _detectImageType(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return 'image/jpeg';
    }
    const pngSignature = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
    if (bytes.length >= pngSignature.length) {
      var isPng = true;
      for (var index = 0; index < pngSignature.length; index++) {
        if (bytes[index] != pngSignature[index]) {
          isPng = false;
          break;
        }
      }
      if (isPng) return 'image/png';
    }
    return null;
  }

  Future<bool> _confirmPhotoPreview(Uint8List bytes) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Preview profile photo'),
            content: SizedBox(
              width: 260,
              height: 260,
              child: Center(
                child: ClipOval(
                  child: Image.memory(
                    bytes,
                    width: 220,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(LucideIcons.imageOff, size: 48),
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Use Photo'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _removePhoto() async {
    final profile = _profile;
    final oldPath = profile?.avatarPath;
    if (profile == null || oldPath == null || _photoBusy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove profile photo?'),
        content: const Text(
          'Your default avatar will be shown instead. This does not affect your account or other profile information.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _photoBusy = true);
    try {
      final updated = await AuthService.updateProfile(
        fullName: profile.fullName,
        clearAvatar: true,
      );
      if (mounted) {
        setState(() {
          _profile = updated;
          _profileImageUrl = null;
          _photoError = null;
        });
      }

      try {
        await ProfileImageService.deleteAvatar(oldPath);
        _showNotice('Profile photo removed.');
      } catch (error) {
        _showNotice(
          'Photo removed from your profile, but its storage file could not be deleted: ${formatSupabaseError(error)}',
        );
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You can sign back in to access your account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true || _signingOut) return;

    setState(() => _signingOut = true);
    try {
      await AuthService.signOut();
      if (mounted) IskolariumApp.navigateToWelcome(context);
    } catch (error) {
      if (mounted) {
        setState(() => _signingOut = false);
        _showError(error);
      }
    }
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light Mode';
      case ThemeMode.dark:
        return 'Dark Mode';
      case ThemeMode.system:
        return 'System Default';
    }
  }

  void _showNotice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(Object error) {
    _showNotice(formatSupabaseError(error));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
        child: ResponsiveContainer(
          maxWidth: 760,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 18),
              _buildProfileHeader(context),
              const SizedBox(height: 28),
              _buildSettingsSection(context, 'Account', [
                _SettingRow(
                  icon: LucideIcons.badge,
                  title: 'Personal Information',
                  subtitle: 'Update your name and profile photo',
                  onTap: _editPersonalInfo,
                ),
                _SettingRow(
                  icon: LucideIcons.bell,
                  title: 'Notification Preferences',
                  subtitle: 'Manage saved academic alert preferences',
                  onTap: _editNotificationPreferences,
                ),
                _SettingRow(
                  icon: LucideIcons.shield,
                  title: 'Privacy and Security',
                  subtitle: 'Change your password or request a reset',
                  onTap: _showSecurityOptions,
                ),
                _SettingRow(
                  icon: LucideIcons.circleHelp,
                  title: 'Help and Support',
                  subtitle: 'App guidance and problem reports',
                  onTap: _showHelp,
                  showDivider: false,
                ),
              ]),
              const SizedBox(height: 24),
              _buildSettingsSection(context, 'App', [
                _SettingRow(
                  icon: LucideIcons.palette,
                  title: 'Appearance',
                  subtitle: _themeLabel(AppThemeService.themeMode.value),
                  onTap: _chooseAppearance,
                  showDivider: false,
                ),
              ]),
              const SizedBox(height: 24),
              _buildLogout(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final profile = _profile;
    final email = profile?.email.isNotEmpty == true
        ? profile!.email
        : AuthService.currentUser?.email ?? '';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: _loading
          ? const SizedBox(
              height: 76,
              child: Center(child: CircularProgressIndicator()),
            )
          : _loadError != null
          ? Row(
              children: [
                const Icon(LucideIcons.circleAlert, color: AppColors.danger),
                const SizedBox(width: 12),
                Expanded(child: Text(_loadError!)),
                TextButton(onPressed: _loadProfile, child: const Text('Retry')),
              ],
            )
          : Row(
              children: [
                InkWell(
                  onTap: _showPhotoActions,
                  customBorder: const CircleBorder(),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: AppColors.primaryLight,
                        backgroundImage: _profileImageUrl == null
                            ? null
                            : NetworkImage(_profileImageUrl!),
                        onBackgroundImageError: _profileImageUrl == null
                            ? null
                            : (error, stackTrace) {
                                if (mounted) {
                                  setState(() {
                                    _profileImageUrl = null;
                                    _photoError = formatSupabaseError(error);
                                  });
                                }
                              },
                        child: _profileImageUrl == null
                            ? const Icon(
                                LucideIcons.userRound,
                                size: 34,
                                color: AppColors.primary,
                              )
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.surface,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            LucideIcons.camera,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                      if (_photoBusy)
                        const Positioned.fill(
                          child: CircleAvatar(
                            backgroundColor: Color(0x99000000),
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.fullName ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                      if (profile != null) ...[
                        const SizedBox(height: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _capitalize(profile.role),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      if (_photoError != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          'Photo could not be loaded. Tap to change it.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.danger),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _editPersonalInfo,
                  icon: const Icon(LucideIcons.pencil, size: 16),
                  label: const Text('Edit Profile'),
                ),
              ],
            ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    String title,
    List<_SettingRow> rows,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }

  Widget _buildLogout(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _signingOut ? null : _logout,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              const Icon(LucideIcons.logOut, color: AppColors.danger),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Log out',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_signingOut)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(
                  LucideIcons.chevronRight,
                  color: AppColors.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  LucideIcons.chevronRight,
                  color: AppColors.textMuted,
                  size: 21,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 32, color: AppColors.border),
      ],
    );
  }
}
