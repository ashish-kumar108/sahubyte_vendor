import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahubyte_vendor/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows welcome actions and opens login', (tester) async {
    SharedPreferences.setMockInitialValues({'is_logged_in': false});
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Login to workspace'), findsOneWidget);
    expect(find.text('Create Vendor Account'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    await tester.ensureVisible(find.text('Login to workspace'));
    await tester.tap(find.text('Login to workspace'));
    await tester.pumpAndSettle();

    expect(find.text('Login to workspace'), findsWidgets);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
  });

  testWidgets('opens vendor registration in a bottom sheet', (tester) async {
    SharedPreferences.setMockInitialValues({'is_logged_in': false});
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Create Vendor Account'));
    await tester.tap(find.text('Create Vendor Account'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('Create vendor account'), findsWidgets);
    expect(find.text('Personal Information'), findsOneWidget);
  });
}
