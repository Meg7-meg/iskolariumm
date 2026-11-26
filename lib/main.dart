import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:iskolarium/screens/instructor/instructor_dashboard.dart';
import 'package:iskolarium/screens/student/student_dashboard.dart';

import 'screens/auth/welcome_screen.dart';
import 'screens/student/student_attendance_screen.dart';
import 'services/academic_service.dart';
import 'services/app_theme_service.dart';
import 'services/auth_service.dart';
import 'services/class_service.dart';
import 'services/organizer_service.dart';
import 'services/supabase_client_provider.dart';
import 'src/student_scores_display.dart';
import 'src/announcement_store.dart';
import 'src/app_colors.dart';
import 'src/design_system.dart';
import 'widgets/class_schedule_editor.dart';

part 'src/models_and_data.dart';
part 'src/navigation_shell.dart';
part 'src/common_widgets.dart';
part 'src/classes_screen.dart';
part 'src/calendar_screen.dart';
part 'src/tasks_screen.dart';
part 'src/notifications_screen.dart';
part 'src/profile_screen.dart';
part 'src/dialogs_navigation_widgets.dart';
part 'src/class_detail_screen.dart';
part 'src/study_sessions_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rinwanyymoylvoxqdhvu.supabase.co',
    publishableKey: 'sb_publishable_s0zqDYoqErLUEQVQFQvBVg_myhq7-Sn',
  );

  runApp(const IskolariumApp());
}

// ------------------------------------------------------------
// ISKOLARIUM DESIGN SYSTEM
// Legacy names are retained for compatibility with existing
// part files. They now point to the shared AppColors palette.
// ------------------------------------------------------------

// ------------------------------------------------------------
// LEGACY COLOR ALIASES
// These redirect to AppColors to avoid breaking existing
// part files that still reference old constant names.
// Migrate screens to use AppColors directly over time.
// ------------------------------------------------------------

const Color primaryBlue = AppColors.primary;
const Color deepNavy = AppColors.navy;
const Color iceBlue = AppColors.primaryLight;
const Color lightBg = AppColors.background;
const Color darkBg = Color(0xFF0A1628);
const Color lightText = AppColors.textPrimary;
const Color darkText = Colors.white;
const Color ink = AppColors.textPrimary;
const Color muted = AppColors.textSecondary;
const Color borderColor = AppColors.border;
const Color canvasColor = AppColors.surface;
const Color softGray = AppColors.surfaceSoft;
const Color darkPill = AppColors.primary;
const Color navy = AppColors.navy;

// Semantic color aliases.
const Color dangerColor = AppColors.danger;
const Color dangerLight = AppColors.dangerLight;

const Color warningColor = AppColors.warning;
const Color warningLight = AppColors.warningLight;

const Color successColor = AppColors.success;
const Color successLight = AppColors.successLight;

const Color infoColor = AppColors.info;
const Color infoLight = AppColors.infoLight;

const Color studyColor = AppColors.study;
const Color studyLight = AppColors.studyLight;

// ------------------------------------------------------------
// APPLICATION
// ------------------------------------------------------------

class IskolariumApp extends StatefulWidget {
  const IskolariumApp({super.key});

  static void navigateToWelcome(BuildContext context) {
    TaskStore.items.clear();
    NoticeStore.items.clear();
    AnnouncementStore.items.clear();
    StudentEnrollmentStore.items.clear();

    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => _AuthGate(
          isDarkMode: AppThemeService.isDarkMode,
          onToggleTheme: AppThemeService.toggleTheme,
        ),
      ),
      (route) => false,
    );
  }

  @override
  State<IskolariumApp> createState() => _IskolariumAppState();
}

class _IskolariumAppState extends State<IskolariumApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppThemeService.themeMode.addListener(_handleThemeModeChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppThemeService.themeMode.removeListener(_handleThemeModeChanged);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    if (AppThemeService.themeMode.value == ThemeMode.system) {
      _handleThemeModeChanged();
    }
  }

  void _handleThemeModeChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = AppThemeService.themeMode.value;
    final isDarkMode = AppThemeService.isDarkMode;
    return MaterialApp(
      title: 'Iskolarium',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: themeMode,
      home: _AuthGate(
        isDarkMode: isDarkMode,
        onToggleTheme: AppThemeService.toggleTheme,
      ),
    );
  }

  // ----------------------------------------------------------
  // LIGHT THEME
  // ----------------------------------------------------------

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      fontFamily: 'Roboto',
      iconTheme: const IconThemeData(size: 20),

      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        secondary: AppColors.study,
        onSecondary: Colors.white,
        error: AppColors.danger,
        onError: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.primaryLight,
        outline: AppColors.border,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        iconTheme: IconThemeData(color: AppColors.textPrimary, size: 20),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        displayMedium: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        displaySmall: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        headlineLarge: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          fontSize: 22,
        ),
        headlineSmall: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontSize: 18,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontSize: 15,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        titleSmall: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontSize: 13,
        ),
        bodyLarge: TextStyle(
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          fontSize: 15,
        ),
        bodyMedium: TextStyle(
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          fontSize: 13,
        ),
        bodySmall: TextStyle(
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
        labelLarge: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontSize: 13,
        ),
        labelMedium: TextStyle(
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
          fontSize: 11,
        ),
        labelSmall: TextStyle(
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
          fontSize: 11,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.3),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.disabled,
          disabledForegroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: CircleBorder(),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.navy,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          height: 1.5,
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.primaryLight,
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return Colors.transparent;
        }),
        side: const BorderSide(color: AppColors.textSecondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.border;
        }),
      ),
    );
  }

  // ----------------------------------------------------------
  // DARK THEME
  // ----------------------------------------------------------

  ThemeData _buildDarkTheme() {
    const darkSurface = Color(0xFF13233D);
    const darkBackground = Color(0xFF0A1628);
    const darkBorder = Color(0xFF263B58);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: AppColors.primary,
      fontFamily: 'Roboto',
      iconTheme: const IconThemeData(size: 20),

      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Color(0xFF0A1628),
        secondary: AppColors.primaryLight,
        onSecondary: Color(0xFF0A1628),
        error: Color(0xFFF87171),
        onError: Color(0xFF450A0A),
        surface: darkSurface,
        onSurface: Colors.white,
        surfaceContainerHighest: Color(0xFF1E3A5F),
        outline: darkBorder,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: const BorderSide(color: darkBorder),
        ),
        margin: EdgeInsets.zero,
      ),

      dividerTheme: const DividerThemeData(color: darkBorder, thickness: 1),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const _AuthGate({required this.isDarkMode, required this.onToggleTheme});

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _checkingSession = true;
  UserProfile? _restoredProfile;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      if (AuthService.currentSession != null) {
        final profile = await AuthService.getCurrentProfile();
        if (profile == null) {
          await AuthService.signOut();
        } else if (mounted) {
          setState(() {
            _restoredProfile = profile;
            _checkingSession = false;
          });
          return;
        }
      }
    } catch (_) {
      // Fall back to WelcomeScreen if session restoration fails.
    }

    if (mounted) {
      setState(() {
        _restoredProfile = null;
        _checkingSession = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSession) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_restoredProfile != null) {
      if (_restoredProfile!.isInstructor) {
        return const InstructorDashboard();
      }
      return IskolariumShell(
        isDarkMode: widget.isDarkMode,
        onToggleTheme: widget.onToggleTheme,
      );
    }

    return WelcomeScreen(
      studentDestinationBuilder: (context) => IskolariumShell(
        isDarkMode: widget.isDarkMode,
        onToggleTheme: widget.onToggleTheme,
      ),
      instructorDestinationBuilder: (context) => const InstructorDashboard(),
    );
  }
}
