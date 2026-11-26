import 'package:flutter/material.dart';

class AuthPalette {
  AuthPalette._();

  static const heroStart = Color(0xFF173156);
  static const heroEnd = Color(0xFF2C5388);
  static const actionBlue = Color(0xFF325A8E);
  static const secondaryTextBlue = Color(0xFF264875);
  static const iceBlue = Color(0xFFF3F7FC);
  static const inputBorder = Color(0xFFDCE6F2);
  static const heading = Color(0xFF111827);
  static const body = Color(0xFF6B7280);
  static const muted = Color(0xFF9CA3AF);
  static const onBlue = Color(0xFFDCE7F5);
  static const gold = Color(0xFFF7B948);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [heroStart, heroEnd],
  );
}
