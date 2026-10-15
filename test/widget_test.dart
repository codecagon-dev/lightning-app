import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lightning/app.dart';

void main() {
  testWidgets('App opens on login with password manager autofill', (
    tester,
  ) async {
    await tester.pumpWidget(const LightningApp());
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsNWidgets(2));
    expect(find.text('Register'), findsOneWidget);
    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields, hasLength(2));
    expect(fields[0].keyboardType, TextInputType.emailAddress);
    expect(fields[0].autofillHints, contains(AutofillHints.username));
    expect(fields[1].autofillHints, contains(AutofillHints.password));
    expect(fields[1].obscureText, isTrue);
    expect(fields[1].enableSuggestions, isFalse);
    expect(fields[1].autocorrect, isFalse);
    expect(find.byType(AutofillGroup), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
