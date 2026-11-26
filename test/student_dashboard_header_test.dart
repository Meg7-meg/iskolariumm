import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iskolarium/screens/student/student_dashboard.dart';
import 'package:iskolarium/src/design_system.dart';

void main() {
  testWidgets('Home add-task action calls its handler', (tester) async {
    var didOpenTaskForm = false;
    await tester.pumpWidget(
      MaterialApp(
        home: _buildDashboard(onAddTask: () => didOpenTaskForm = true),
      ),
    );
    await tester.pump();

    final addTaskButton = find.text('+ Add task');
    await tester.ensureVisible(addTaskButton);
    await tester.tap(addTaskButton);

    expect(didOpenTaskForm, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('student Home header fits and aligns at narrow and wide widths', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(home: _buildDashboard()));
    await tester.pump();

    final header = find.byKey(const ValueKey('student-dashboard-header'));
    final bell = find.byType(DashboardNotificationButton);
    expect(tester.takeException(), isNull);
    expect(find.text('Here’s your academic overview.'), findsOneWidget);
    expect(bell, findsOneWidget);

    var headerRect = tester.getRect(header);
    var bellRect = tester.getRect(bell);
    expect(bellRect.top, closeTo(headerRect.top, 0.1));
    expect(bellRect.right, closeTo(headerRect.right, 0.1));

    tester.view.physicalSize = const Size(1280, 900);
    await tester.pumpWidget(MaterialApp(home: _buildDashboard()));
    await tester.pump();

    final containerRect = tester.getRect(
      find.byKey(const ValueKey('student-dashboard-container')),
    );
    headerRect = tester.getRect(header);
    bellRect = tester.getRect(bell);
    expect(containerRect.width, greaterThan(1100));
    expect(bellRect.right, closeTo(headerRect.right, 0.1));
    expect(tester.takeException(), isNull);
  });
}

Widget _buildDashboard({VoidCallback? onAddTask}) {
  return AcademicNavigationShell(
    roleLabel: 'Student Portal',
    destinations: const [
      AcademicNavDestination(icon: Icons.home_outlined, label: 'Home'),
      AcademicNavDestination(icon: Icons.settings_outlined, label: 'Settings'),
    ],
    selectedIndex: 0,
    onSelected: (_) {},
    maxWidth: double.infinity,
    body: StudentDashboard(
      onOpenClasses: () {},
      onOpenTasks: () {},
      onOpenNotifications: () {},
      onOpenStudySessions: () {},
      onOpenAttendance: () {},
      onOpenScores: () {},
      onAddTask: onAddTask ?? () {},
      onRefresh: () {},
    ),
  );
}
