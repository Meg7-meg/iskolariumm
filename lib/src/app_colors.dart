
import 'package:flutter/material.dart';

/// ============================================================
/// ISKOLARIUM — CENTRAL DESIGN COLOR SYSTEM
/// ============================================================
///
/// COLOR PSYCHOLOGY:
/// Blue   = Trust, learning, navigation, primary actions
/// Red    = Urgency, overdue work, destructive actions
/// Amber  = Caution, upcoming deadlines, pending actions
/// Green  = Success, completion, good performance, present
/// Cyan   = Information, announcements, class updates
/// Purple = Creativity, studying, focus and productivity
/// Teal   = Balance, secondary academic information
///
/// Always use these shared colors instead of hard-coded colors
/// inside individual screens whenever possible.
/// ============================================================

class AppColors {
  AppColors._();

  // ----------------------------------------------------------
  // BRAND IDENTITY
  // ----------------------------------------------------------

  static const Color primary = Color(0xFF1A56DB);
  static const Color primaryDark = Color(0xFF1646B5);
  static const Color primaryLight = Color(0xFFEBF2FE);
  static const Color primarySoft = Color(0xFFF3F7FF);

  static const Color navy = Color(0xFF0D1F3C);
  static const Color navyLight = Color(0xFF1E3A5F);

  // ----------------------------------------------------------
  // BACKGROUNDS AND SURFACES
  // ----------------------------------------------------------

  static const Color background = Color(0xFFF5F8FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF0F5FF);
  static const Color surfaceBlue = Color(0xFFEAF1FF);

  static const Color border = Color(0xFFDCE5F2);
  static const Color divider = Color(0xFFE2E8F0);

  // ----------------------------------------------------------
  // TYPOGRAPHY
  // ----------------------------------------------------------

  static const Color textPrimary = Color(0xFF172B4D);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ----------------------------------------------------------
  // DANGER — OVERDUE / DELETE / ABSENT
  // ----------------------------------------------------------

  static const Color danger = Color(0xFFDC2626);
  static const Color dangerDark = Color(0xFFB91C1C);
  static const Color dangerLight = Color(0xFFFEF2F2);
  static const Color dangerBorder = Color(0xFFFECACA);

  // ----------------------------------------------------------
  // WARNING — UPCOMING DEADLINES / PENDING
  // ----------------------------------------------------------

  static const Color warning = Color(0xFFD97706);
  static const Color warningDark = Color(0xFFB45309);
  static const Color warningLight = Color(0xFFFFF7ED);
  static const Color warningBorder = Color(0xFFFED7AA);

  // ----------------------------------------------------------
  // SUCCESS — COMPLETED / PRESENT
  // ----------------------------------------------------------

  static const Color success = Color(0xFF15803D);
  static const Color successDark = Color(0xFF166534);
  static const Color successLight = Color(0xFFF0FDF4);
  static const Color successBorder = Color(0xFFBBF7D0);

  // ----------------------------------------------------------
  // INFORMATION — ANNOUNCEMENTS / UPDATES
  // ----------------------------------------------------------

  static const Color info = Color(0xFF0891B2);
  static const Color infoDark = Color(0xFF0E7490);
  static const Color infoLight = Color(0xFFECFEFF);
  static const Color infoBorder = Color(0xFFA5F3FC);

  // ----------------------------------------------------------
  // STUDY — FOCUS / STUDY SESSIONS
  // ----------------------------------------------------------

  static const Color study = Color(0xFF7C3AED);
  static const Color studyDark = Color(0xFF6D28D9);
  static const Color studyLight = Color(0xFFF5F3FF);
  static const Color studyBorder = Color(0xFFDDD6FE);

  // ----------------------------------------------------------
  // SECONDARY ACCENT — TEAL
  // ----------------------------------------------------------

  static const Color teal = Color(0xFF0F766E);
  static const Color tealDark = Color(0xFF115E59);
  static const Color tealLight = Color(0xFFF0FDFA);
  static const Color tealBorder = Color(0xFF99F6E4);

  // ----------------------------------------------------------
  // ATTENDANCE STATUS
  // ----------------------------------------------------------

  static const Color attendancePresent = success;
  static const Color attendancePresentLight = successLight;

  static const Color attendanceAbsent = danger;
  static const Color attendanceAbsentLight = dangerLight;

  static const Color attendanceLate = warning;
  static const Color attendanceLateLight = warningLight;

  static const Color attendanceExcused = info;
  static const Color attendanceExcusedLight = infoLight;

  // ----------------------------------------------------------
  // TASK AND DEADLINE STATUS
  // ----------------------------------------------------------

  static const Color taskCompleted = success;
  static const Color taskCompletedLight = successLight;

  static const Color taskUpcoming = warning;
  static const Color taskUpcomingLight = warningLight;

  static const Color taskOverdue = danger;
  static const Color taskOverdueLight = dangerLight;

  // ----------------------------------------------------------
  // SCORE PERFORMANCE
  // ----------------------------------------------------------

  static const Color scoreExcellent = Color(0xFF15803D);
  static const Color scoreExcellentLight = Color(0xFFF0FDF4);

  static const Color scoreGood = Color(0xFF0891B2);
  static const Color scoreGoodLight = Color(0xFFECFEFF);

  static const Color scoreAverage = Color(0xFFD97706);
  static const Color scoreAverageLight = Color(0xFFFFF7ED);

  static const Color scoreNeedsImprovement = Color(0xFFDC2626);
  static const Color scoreNeedsImprovementLight = Color(0xFFFEF2F2);

  // ----------------------------------------------------------
  // NEUTRAL / DISABLED / OVERLAYS
  // ----------------------------------------------------------

  static const Color disabled = Color(0xFFCBD5E1);
  static const Color disabledText = Color(0xFF64748B);

  static const Color overlay = Color(0x660D1F3C);

  // ----------------------------------------------------------
  // GRADIENT PALETTES
  // Use these when a widget needs a decorative background.
  // ----------------------------------------------------------

  static const List<Color> primaryGradient = [
    Color(0xFF1A56DB),
    Color(0xFF1646B5),
  ];

  static const List<Color> studyGradient = [
    Color(0xFF8B5CF6),
    Color(0xFF6D28D9),
  ];

  static const List<Color> successGradient = [
    Color(0xFF22C55E),
    Color(0xFF15803D),
  ];
}
