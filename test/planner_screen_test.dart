import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iskolarium/main.dart';

void main() {
  testWidgets('Planner fits a compact viewport without statistic cards', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TasksPage(onRefresh: () {})),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Planner'), findsOneWidget);
    expect(find.textContaining('remaining'), findsOneWidget);
    expect(find.text('Total'), findsNothing);
    expect(find.text('Pending'), findsNothing);
    expect(find.text('Completed'), findsNothing);
    expect(find.text('Create'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });
}
