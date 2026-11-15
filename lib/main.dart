import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:iskolarium/screens/instructor/instructor_dashboard.dart';
import 'package:iskolarium/screens/student/student_dashboard.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/auth/welcome_screen.dart';



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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rinwanymoylvoxqdhvu.supabase.co',
    publishableKey: 'sb_publishable_s0zqDYoqErLUEQVQFQvBVg_myhq7-Sn',
  );

  runApp(const IskolariumApp());
}

// ------------------------------------------------------------
// 1. APP THEME (White and Blue Palette)
// ------------------------------------------------------------
const Color primaryBlue = Color(0xFF1E60D5);
const Color deepNavy = Color(0xFF0F2042);
const Color iceBlue = Color(0xFFEBF2FD);
const Color lightBg = Color(0xFFF8FAFD);
const Color darkBg = Color(0xFF0A1628);

const Color lightText = Color(0xFF0F2042);
const Color darkText = Colors.white;
const Color ink = Color(0xFF0F2042);
const Color muted = Color(0xFF64748B);
const Color borderColor = Color(0xFFD8E5F8);
const Color canvasColor = Colors.white;
const Color softGray = Color(0xFFEBF2FD);
const Color darkPill = Color(0xFF1E60D5);

class IskolariumApp extends StatefulWidget {
  const IskolariumApp({super.key});

  @override
  State<IskolariumApp> createState() => _IskolariumAppState();
}

class _IskolariumAppState extends State<IskolariumApp> {
  bool isDarkMode = false;

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Iskolarium',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: lightBg,
        primaryColor: primaryBlue,
        colorScheme: const ColorScheme.light(
          primary: primaryBlue,
          surface: Colors.white,
          onSurface: deepNavy,
          onPrimary: Colors.white,
          secondary: Color(0xFF4A90FF),
          surfaceContainerHighest: iceBlue,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: deepNavy,
          elevation: 0,
          iconTheme: IconThemeData(color: deepNavy),
          titleTextStyle: TextStyle(
            color: deepNavy,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkBg,
        primaryColor: const Color(0xFF3B82F6),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3B82F6),
          surface: Color(0xFF13233D),
          onSurface: Colors.white,
          onPrimary: Colors.white,
          secondary: Color(0xFF60A5FA),
          surfaceContainerHighest: Color(0xFF1E3A5F),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF13233D),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF2563EB),
          foregroundColor: Colors.white,
        ),
      ),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: WelcomeScreen(
  studentDestinationBuilder: (context) => IskolariumShell(
    isDarkMode: false,
    onToggleTheme: () {},
  ),
  instructorDestinationBuilder: (context) =>
      const InstructorDashboard(),
),
    );
  }
}

// ------------------------------------------------------------
