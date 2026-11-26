import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iskolarium/services/app_theme_service.dart';

void main() {
  test('theme preferences map to app-wide theme modes', () {
    expect(AppThemeService.parsePreference('light'), ThemeMode.light);
    expect(AppThemeService.parsePreference('dark'), ThemeMode.dark);
    expect(AppThemeService.parsePreference('system'), ThemeMode.system);
    expect(AppThemeService.parsePreference('unknown'), ThemeMode.system);

    expect(AppThemeService.preferenceFor(ThemeMode.light), 'light');
    expect(AppThemeService.preferenceFor(ThemeMode.dark), 'dark');
    expect(AppThemeService.preferenceFor(ThemeMode.system), 'system');
  });
}
