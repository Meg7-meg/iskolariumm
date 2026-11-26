import 'package:flutter/material.dart';

/// ============================================================
/// ISKOLARIUM — CENTRAL DESIGN COLOR SYSTEM
/// Swiss Design + Modern Minimalist palette.
/// ============================================================
///
/// COLOR PSYCHOLOGY:
/// Navy  = Authority, trust, primary brand identity
/// Blue  = Navigation, primary actions, academic
/// Red   = Urgency, overdue work, destructive actions
/// Amber = Caution, upcoming deadlines, pending actions
/// Green = Success, completion, good performance, present
///
/// Always use these shared tokens instead of hard-coded colors
/// inside individual screens.
/// ============================================================

class AppColors {
  AppColors._();

  // ----------------------------------------------------------
  // BRAND IDENTITY
  // ----------------------------------------------------------

  /// Deep blue — headings and branded moments
  static const Color navy = Color(0xFF173156);
  static const Color navyLight = Color(0xFF2C5388);

  /// Academic Blue — primary interactive color, links, CTAs
  static const Color primary = Color(0xFF2C5388);
  static const Color primaryDark = Color(0xFF173156);
  static const Color steelBlue = Color(0xFF7DAFC8);
  static const Color primaryLight = Color(0xFFF3F7FC);
  static const Color primarySoft = Color(0xFFF8FAFC);

  // ----------------------------------------------------------
  // BACKGROUNDS AND SURFACES
  // ----------------------------------------------------------

  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF4F6F9);
  static const Color surfaceBlue = Color(0xFFEEF4FB);
  static const Color softLavender = Color(0xFFE9E6FA);
  static const Color softPeach = Color(0xFFFCEBDD);
  static const Color softMint = Color(0xFFDFF3E9);

  static const Color border = Color(0xFFE5ECF6);
  static const Color divider = Color(0xFFE5ECF6);

  // ----------------------------------------------------------
  // TYPOGRAPHY
  // ----------------------------------------------------------

  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ----------------------------------------------------------
  // DANGER — OVERDUE / DELETE / ABSENT
  // ----------------------------------------------------------

  static const Color danger = Color(0xFFD9534F);
  static const Color dangerDark = Color(0xFFBF3B38);
  static const Color dangerLight = Color(0xFFFDF0EF);
  static const Color dangerBorder = Color(0xFFF5C0BF);

  // ----------------------------------------------------------
  // WARNING — UPCOMING DEADLINES / PENDING
  // ----------------------------------------------------------

  static const Color warning = Color(0xFFD99A35);
  static const Color warningDark = Color(0xFFB07A20);
  static const Color warningLight = Color(0xFFFDF5E6);
  static const Color warningBorder = Color(0xFFF5D99A);

  // ----------------------------------------------------------
  // SUCCESS — COMPLETED / PRESENT
  // ----------------------------------------------------------

  static const Color success = Color(0xFF269B75);
  static const Color successDark = Color(0xFF1E7D5E);
  static const Color successLight = Color(0xFFEDF7F4);
  static const Color successBorder = Color(0xFFB0E5D6);

  // ----------------------------------------------------------
  // INFORMATION — ANNOUNCEMENTS / UPDATES
  // ----------------------------------------------------------

  static const Color info = Color(0xFF2C5388);
  static const Color infoDark = Color(0xFF173156);
  static const Color infoLight = Color(0xFFF3F7FC);
  static const Color infoBorder = Color(0xFFC9DCF4);

  // ----------------------------------------------------------
  // STUDY — FOCUS / STUDY SESSIONS
  // ----------------------------------------------------------

  static const Color study = Color(0xFF2C5388);
  static const Color studyDark = Color(0xFF173156);
  static const Color studyLight = Color(0xFFF3F7FC);
  static const Color studyBorder = Color(0xFFC9DCF4);

  // ----------------------------------------------------------
  // SECONDARY ACCENT — TEAL
  // ----------------------------------------------------------

  static const Color teal = Color(0xFF269B75);
  static const Color tealDark = Color(0xFF1E7D5E);
  static const Color tealLight = Color(0xFFEDF7F4);
  static const Color tealBorder = Color(0xFFB0E5D6);

  // ----------------------------------------------------------
  // ATTENDANCE STATUS
  // ----------------------------------------------------------

  static const Color attendancePresent = success;
  static const Color attendancePresentLight = successLight;

  static const Color attendanceAbsent = danger;
  static const Color attendanceAbsentLight = dangerLight;

  static const Color attendanceLate = warning;
  static const Color attendanceLateLight = warningLight;

  static const Color attendanceExcused = Color(0xFF2C5388);
  static const Color attendanceExcusedLight = Color(0xFFF3F7FC);

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

  static const Color scoreExcellent = Color(0xFF269B75);
  static const Color scoreExcellentLight = Color(0xFFEDF7F4);

  static const Color scoreGood = Color(0xFF2C5388);
  static const Color scoreGoodLight = Color(0xFFF3F7FC);

  static const Color scoreAverage = Color(0xFFD99A35);
  static const Color scoreAverageLight = Color(0xFFFDF5E6);

  static const Color scoreNeedsImprovement = Color(0xFFD9534F);
  static const Color scoreNeedsImprovementLight = Color(0xFFFDF0EF);

  // ----------------------------------------------------------
  // NEUTRAL / DISABLED / OVERLAYS
  // ----------------------------------------------------------

  static const Color disabled = Color(0xFFCDD2DA);
  static const Color disabledText = Color(0xFF9BA5B7);

  static const Color overlay = Color(0x66172B4D);

  // ----------------------------------------------------------
  // GRADIENT PALETTES
  // Reserved for special branded moments only.
  // ----------------------------------------------------------

  static const List<Color> primaryGradient = [
    Color(0xFF173156),
    Color(0xFF2C5388),
  ];

  static const List<Color> studyGradient = [
    Color(0xFF173156),
    Color(0xFF2C5388),
  ];

  static const List<Color> successGradient = [
    Color(0xFF32B88A),
    Color(0xFF1E7D5E),
  ];
}
