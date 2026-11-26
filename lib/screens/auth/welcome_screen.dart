import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth_palette.dart';
import 'login_screen.dart';

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
  void _openLogin(String role, WidgetBuilder destinationBuilder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LoginScreen(role: role, destinationBuilder: destinationBuilder),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AuthPalette.heroStart,
        body: Column(
          children: [
            Expanded(
              flex: 42,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AuthPalette.heroGradient,
                ),
                child: SafeArea(
                  bottom: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: const BoxDecoration(
                              color: Color(0x1FFFFFFF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.school_rounded,
                              color: Colors.white,
                              size: 44,
                            ),
                          ),
                          const SizedBox(height: 16),
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                              ),
                              children: const [
                                TextSpan(
                                  text: 'Welcome to ',
                                  style: TextStyle(color: Colors.white),
                                ),
                                TextSpan(
                                  text: 'Iskolarium',
                                  style: TextStyle(color: AuthPalette.gold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 7),
                          const Text(
                            'Plan smarter. Study better.',
                            style: TextStyle(
                              color: AuthPalette.onBlue,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 58,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x140B1D36),
                      blurRadius: 20,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Who’s signing in?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AuthPalette.heading,
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Pick your role to continue.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AuthPalette.body,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _PortalButton(
                                  label: 'I’m a Student',
                                  onPressed: () => _openLogin(
                                    'Student',
                                    widget.studentDestinationBuilder,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _PortalButton(
                                  label: 'I’m an Instructor',
                                  secondary: true,
                                  onPressed: () => _openLogin(
                                    'Instructor',
                                    widget.instructorDestinationBuilder,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'CLASSES  •  TASKS  •  GRADES',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AuthPalette.muted,
                            fontSize: 10.5,
                            letterSpacing: 1.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PortalButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool secondary;

  const _PortalButton({
    required this.label,
    required this.onPressed,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: secondary
              ? AuthPalette.iceBlue
              : AuthPalette.actionBlue,
          foregroundColor: secondary
              ? AuthPalette.secondaryTextBlue
              : Colors.white,
          elevation: 0,
          overlayColor: AuthPalette.actionBlue.withValues(alpha: 0.12),
          side: BorderSide(
            color: secondary
                ? AuthPalette.actionBlue
                : Colors.transparent,
            width: secondary ? 1.5 : 0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }
}
