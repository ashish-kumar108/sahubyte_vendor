import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahubyte_vendor/view/app_ui.dart';
import 'package:sahubyte_vendor/view/welcome_view.dart';

void main() {
  testWidgets('shared vendor information fits a narrow phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(12),
            child: AppCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppInfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Service address',
                    value:
                        'A long customer address that must wrap without overflow',
                  ),
                  StatusPill(
                    label: 'Waiting for customer approval',
                    color: AppColors.warning,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('vendor welcome screen fits a narrow phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(theme: ThemeData(useMaterial3: true), home: WelcomeView()),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('SAHUBYTE'), findsOneWidget);
    expect(find.text('Login to workspace'), findsOneWidget);
  });
}
