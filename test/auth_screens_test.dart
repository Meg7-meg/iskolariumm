import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iskolarium/screens/auth/login_screen.dart';
import 'package:iskolarium/screens/auth/welcome_screen.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('portal selection opens the selected role sign-in screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: WelcomeScreen(
          studentDestinationBuilder: (_) =>
              const Scaffold(body: Text('Student home')),
          instructorDestinationBuilder: (_) =>
              const Scaffold(body: Text('Instructor home')),
        ),
      ),
    );

    expect(find.text('Plan smarter. Study better.'), findsOneWidget);
    await tester.tap(find.text('I’m a Student'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in to your Student workspace.'), findsOneWidget);
    expect(find.text('School email'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('sign-in validates inline and keeps the reset route available', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          role: 'Instructor',
          destinationBuilder: (_) => const Scaffold(),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Sign in'));
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your school email to continue.'), findsOneWidget);
    expect(find.text('Enter your password to continue.'), findsOneWidget);

    await tester.ensureVisible(find.text('Forgot password?'));
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(
      find.text('Enter your school email and we’ll send a reset link.'),
      findsOneWidget,
    );
    expect(find.text('Send reset link'), findsOneWidget);
    expect(find.text('Back to sign in'), findsOneWidget);
  });

  testWidgets('sign-up keeps password guidance and the sign-in switch', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          role: 'Student',
          destinationBuilder: (_) => const Scaffold(),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Create an account'));
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
    expect(
      find.text('Set up your Student workspace in seconds.'),
      findsOneWidget,
    );
    expect(find.textContaining('Already have an account?'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Alex Student');
    await tester.enterText(find.byType(TextFormField).at(1), 'alex@school.edu');
    await tester.enterText(find.byType(TextFormField).at(2), 'short');
    await tester.enterText(find.byType(TextFormField).at(3), 'short');
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(
      find.text('Use at least 8 characters for a stronger password.'),
      findsOneWidget,
    );
  });
}
