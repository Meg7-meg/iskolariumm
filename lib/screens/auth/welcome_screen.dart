
import 'package:flutter/material.dart';
import 'login_screen.dart';

// ============================================================
// ISKOLARIUM BRAND COLORS
// ============================================================

class _WelcomeColors {
  static const navy = Color(0xFF08234A);
  static const deepNavy = Color(0xFF06172F);
  static const blue = Color(0xFF123D70);
  static const buttonBlue = Color(0xFF123D70);
  static const gold = Color(0xFFFFC95C);
  static const subtitle = Color(0xFFD5E4F8);
  static const heading = Color(0xFF102B50);
  static const body = Color(0xFF71839D);
  static const footer = Color(0xFF8799B2);
  static const white = Colors.white;
}

// ============================================================
// WELCOME SCREEN
// ============================================================

class WelcomeScreen extends StatefulWidget {
  final WidgetBuilder studentDestinationBuilder;
  final WidgetBuilder instructorDestinationBuilder;

  const WelcomeScreen({
    super.key,
    required this.studentDestinationBuilder,
    required this.instructorDestinationBuilder,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  // PREVIEW MODE
  // true  = Open dashboard directly
  // false = Open role-specific login screen

  static const bool usePreviewMode = true;

  // ==========================================================
  // NAVIGATION
  // ==========================================================

  void _openLogin(
    String role,
    WidgetBuilder destinationBuilder,
  ) {
    if (usePreviewMode) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: destinationBuilder,
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(
            role: role,
            destinationBuilder: destinationBuilder,
          ),
        ),
      );
    }
  }

  // ==========================================================
  // MAIN UI
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _WelcomeColors.deepNavy,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;

            // RESPONSIVE DIMENSIONS

            final cardOverlap =
                screenHeight < 700 ? 58.0 : 70.0;

            final cardTop =
                (screenHeight * 0.50) - cardOverlap;

            // OWL DIMENSIONS

            final owlWidth = (screenWidth * 0.85)
                .clamp(250.0, 310.0)
                .toDouble();

            final owlHeight = owlWidth * 0.78;

            final owlTop = cardTop - owlHeight + 38;

            // BUTTON WIDTH

            final buttonWidth = (screenWidth - 80)
                .clamp(180.0, 220.0)
                .toDouble();

            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // ==========================================
                // 1. NAVY GRADIENT BACKGROUND
                // ==========================================

                Positioned.fill(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF123968),
                          _WelcomeColors.navy,
                          _WelcomeColors.deepNavy,
                        ],
                        stops: [0.0, 0.48, 1.0],
                      ),
                    ),
                  ),
                ),

                // ==========================================
                // 2. SOFT BLUE GLOW
                // ==========================================

                Positioned(
                  top: 70,
                  left: -90,
                  child: _GlowCircle(
                    size: screenWidth * 0.72,
                    color: const Color(0xFF1C5CA0)
                        .withOpacity(0.20),
                  ),
                ),

                Positioned(
                  top: screenHeight * 0.25,
                  right: -115,
                  child: _GlowCircle(
                    size: screenWidth * 0.68,
                    color: const Color(0xFF2468B4)
                        .withOpacity(0.13),
                  ),
                ),

                // ==========================================
                // 3. ACADEMIC DECORATIONS
                // ==========================================

                Positioned(
                  top: screenHeight * 0.27,
                  left: 25,
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: 36,
                    color: const Color(0xFF4C8ACB)
                        .withOpacity(0.30),
                  ),
                ),

                Positioned(
                  top: screenHeight * 0.34,
                  right: 28,
                  child: Icon(
                    Icons.calendar_month_rounded,
                    size: 31,
                    color: const Color(0xFF4C8ACB)
                        .withOpacity(0.24),
                  ),
                ),

                Positioned(
                  top: screenHeight * 0.39,
                  left: screenWidth * 0.20,
                  child: const _GoldSparkle(size: 13),
                ),

                Positioned(
                  top: screenHeight * 0.30,
                  right: screenWidth * 0.19,
                  child: const _GoldSparkle(size: 17),
                ),

                // ==========================================
                // 4. WELCOME HEADER
                // ==========================================

                Positioned(
                  top: 28,
                  left: 22,
                  right: 22,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 27,
                              height: 1.16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                            ),
                            children: [
                              TextSpan(
                                text: 'Welcome to\n',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              TextSpan(
                                text: 'Iskolarium',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              TextSpan(
                                text: '!',
                                style: TextStyle(
                                  color: _WelcomeColors.gold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 11),

                      const SizedBox(
                        width: double.infinity,
                        child: Text(
                          'Your academic life, organized in one place.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            color: _WelcomeColors.subtitle,
                            fontSize: 13.5,
                            height: 1.45,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.15,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // GOLD ACCENT LINE

                      Container(
                        width: 82,
                        height: 3,
                        decoration: BoxDecoration(
                          color: _WelcomeColors.gold,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ],
                  ),
                ),

                // ==========================================
                // 5. WHITE GET STARTED CONTAINER + WAVES
                // ==========================================

                Positioned(
                  top: cardTop,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _WelcomeColors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.16),
                          blurRadius: 24,
                          offset: const Offset(0, -7),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      child: Stack(
                        children: [
                          // BLUE WAVES AT THE BOTTOM

                          Positioned.fill(
                            child: CustomPaint(
                              painter: _BottomWavePainter(),
                            ),
                          ),

                          // GET STARTED CONTENT

                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              26,
                              screenHeight < 700 ? 67 : 76,
                              26,
                              16,
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.center,
                              children: [
                                // GET STARTED TITLE

                                const SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    'Get Started!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Roboto',
                                      color: _WelcomeColors.heading,
                                      fontSize: 26,
                                      height: 1.2,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.65,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // SUPPORTING TEXT

                                const SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    'Choose how you want to continue.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Roboto',
                                      color: _WelcomeColors.body,
                                      fontSize: 14,
                                      height: 1.45,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),

                                // PUSH BUTTONS TOWARD THE BOTTOM

                                const Spacer(),

                                // STUDENT BUTTON

                                Center(
                                  child: _WelcomeButton(
                                    width: buttonWidth,
                                    title: 'Student',
                                    icon: Icons.school_rounded,
                                    onTap: () {
                                      _openLogin(
                                        'Student',
                                        widget.studentDestinationBuilder,
                                      );
                                    },
                                  ),
                                ),

                                const SizedBox(height: 14),

                                // INSTRUCTOR BUTTON

                                Center(
                                  child: _WelcomeButton(
                                    width: buttonWidth,
                                    title: 'Instructor',
                                    icon: Icons.co_present_rounded,
                                    onTap: () {
                                      _openLogin(
                                        'Instructor',
                                        widget.instructorDestinationBuilder,
                                      );
                                    },
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // FOOTER

                                const SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    'ORGANIZE   •   LEARN   •   ACHIEVE',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Roboto',
                                      color: _WelcomeColors.footer,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.35,
                                    ),
                                  ),
                                ),

                                // SPACE FOR WAVES

                                const SizedBox(height: 105),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ==========================================
                // 6. BIG STATIC OWL MASCOT
                // ==========================================

                Positioned(
                  top: owlTop,
                  left: (screenWidth - owlWidth) / 2,
                  width: owlWidth,
                  height: owlHeight,
                  child: Image.asset(
                    'assets/images/owl_peeking.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                    errorBuilder: (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return const Icon(
                        Icons.face_rounded,
                        size: 110,
                        color: _WelcomeColors.gold,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// STUDENT AND INSTRUCTOR BUTTON
// ============================================================

class _WelcomeButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final double width;

  const _WelcomeButton({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _WelcomeColors.buttonBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: _WelcomeColors.blue.withOpacity(0.20),
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // CENTERED BUTTON LABEL

            Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.15,
                ),
              ),
            ),

            // LEFT ICON

            Align(
              alignment: Alignment.centerLeft,
              child: Icon(
                icon,
                size: 21,
                color: Colors.white,
              ),
            ),

            // RIGHT ARROW

            const Align(
              alignment: Alignment.centerRight,
              child: Icon(
                Icons.chevron_right_rounded,
                size: 23,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// GLOW CIRCLE DECORATION
// ============================================================

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withOpacity(0),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// GOLD SPARKLE DECORATION
// ============================================================

class _GoldSparkle extends StatelessWidget {
  final double size;

  const _GoldSparkle({
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.auto_awesome_rounded,
      size: size,
      color: _WelcomeColors.gold.withOpacity(0.85),
    );
  }
}

// ============================================================
// BOTTOM BLUE WAVE DESIGN
// ============================================================

class _BottomWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // FIRST WAVE - VERY LIGHT BLUE

    final firstWave = Path()
      ..moveTo(0, height - 165)
      ..cubicTo(
        width * 0.22,
        height - 100,
        width * 0.36,
        height - 65,
        width * 0.56,
        height - 85,
      )
      ..cubicTo(
        width * 0.76,
        height - 105,
        width * 0.88,
        height - 150,
        width,
        height - 175,
      )
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();

    canvas.drawPath(
      firstWave,
      Paint()
        ..color = const Color(0xFFE4F0FF)
        ..style = PaintingStyle.fill,
    );

    // SECOND WAVE - MEDIUM BLUE

    final secondWave = Path()
      ..moveTo(0, height - 110)
      ..cubicTo(
        width * 0.24,
        height - 55,
        width * 0.42,
        height - 20,
        width * 0.60,
        height - 35,
      )
      ..cubicTo(
        width * 0.78,
        height - 50,
        width * 0.90,
        height - 100,
        width,
        height - 125,
      )
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();

    canvas.drawPath(
      secondWave,
      Paint()
        ..color = const Color(0xFFBFD9FF)
        ..style = PaintingStyle.fill,
    );

    // THIRD WAVE - DEEPER BLUE

    final thirdWave = Path()
      ..moveTo(0, height - 65)
      ..cubicTo(
        width * 0.23,
        height - 25,
        width * 0.43,
        height - 5,
        width * 0.60,
        height - 15,
      )
      ..cubicTo(
        width * 0.80,
        height - 25,
        width * 0.91,
        height - 60,
        width,
        height - 85,
      )
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();

    canvas.drawPath(
      thirdWave,
      Paint()
        ..color = const Color(0xFF91BCF5)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(
    covariant _BottomWavePainter oldDelegate,
  ) {
    return false;
  }
}
