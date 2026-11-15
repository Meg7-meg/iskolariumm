part of '../main.dart';

// 10. PROFILE SCREEN
// ------------------------------------------------------------

class ProfilePage extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const ProfilePage({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  // Keep your existing build method below.

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            tooltip: isDarkMode ? 'Switch to day mode' : 'Switch to night mode',
            
            onPressed: () {
             onToggleTheme();
},
            icon: Icon(
              isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
            style: IconButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              backgroundColor: Theme.of(context).colorScheme.surface,
            ),
          ),
        ),

        Text(
          'Profile',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Your account information',
          style: TextStyle(color: muted, fontSize: 12),
        ),
        const SizedBox(height: 24),
        const OutlineCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: softGray,
                child: Icon(Icons.person_outline, color: ink, size: 32),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alex Morgan',
                      style: TextStyle(
                        color: ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'alex@example.com',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Student',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.edit_outlined, color: muted),
            ],
          ),
        ),
        const SectionTitle(title: 'Account', action: ''),
        const ProfileOption(
          icon: Icons.person_outline,
          title: 'Personal information',
        ),
        const ProfileOption(
          icon: Icons.notifications_none,
          title: 'Notification preferences',
        ),
        const ProfileOption(
          icon: Icons.lock_outline,
          title: 'Privacy and security',
        ),
        const ProfileOption(
          icon: Icons.help_outline,
          title: 'Help and support',
        ),
        const SizedBox(height: 8),
        ProfileOption(
          icon: Icons.logout,
          title: 'Log out',
          color: Colors.redAccent,
          onTap: () {
            Navigator.popUntil(
              context,
              (route) => route.isFirst,
            );
          },
        ),
        const SizedBox(height: 24),
        const Center(
          child: Text(
            'Iskolarium · Academic companion',
            style: TextStyle(color: muted, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Color? color;

  const ProfileOption({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: OutlineCard(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
          child: Row(
            children: [
              Icon(icon, color: color ?? muted, size: 21),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color ?? ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: color ?? muted),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
