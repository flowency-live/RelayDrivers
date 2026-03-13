import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_drivers/features/profile/presentation/widgets/editable_profile_field.dart';

void main() {
  group('EditableProfileField', () {
    testWidgets('displays label and value in view mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditableProfileField(
              label: 'Email',
              value: 'test@example.com',
              icon: Icons.email,
              onSave: (_) async => true,
            ),
          ),
        ),
      );

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.byIcon(Icons.email), findsOneWidget);
    });

    testWidgets('displays "Not set" for null value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditableProfileField(
              label: 'Phone',
              value: null,
              icon: Icons.phone,
              onSave: (_) async => true,
            ),
          ),
        ),
      );

      expect(find.text('Not set'), findsOneWidget);
    });

    testWidgets('shows edit icon when editable', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditableProfileField(
              label: 'Name',
              value: 'John',
              icon: Icons.person,
              onSave: (_) async => true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('hides edit icon when not editable', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditableProfileField(
              label: 'Email',
              value: 'test@example.com',
              icon: Icons.email,
              editable: false,
              onSave: (_) async => true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.edit), findsNothing);
    });

    testWidgets('enters edit mode on tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditableProfileField(
              label: 'Name',
              value: 'John',
              icon: Icons.person,
              onSave: (_) async => true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(EditableProfileField));
      await tester.pumpAndSettle();

      // Should show a TextField in edit mode
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows save and cancel buttons in edit mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditableProfileField(
              label: 'Name',
              value: 'John',
              icon: Icons.person,
              onSave: (_) async => true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(EditableProfileField));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('cancels edit on close button tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditableProfileField(
              label: 'Name',
              value: 'John',
              icon: Icons.person,
              onSave: (_) async => true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(EditableProfileField));
      await tester.pumpAndSettle();

      // Change the text
      await tester.enterText(find.byType(TextField), 'Jane');
      await tester.pumpAndSettle();

      // Cancel
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Should show original value
      expect(find.text('John'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('calls onSave with new value on save button tap', (tester) async {
      String? savedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditableProfileField(
              label: 'Name',
              value: 'John',
              icon: Icons.person,
              onSave: (value) async {
                savedValue = value;
                return true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(EditableProfileField));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Jane');
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(savedValue, equals('Jane'));
    });

    testWidgets('shows loading indicator while saving', (tester) async {
      final completer = Completer<bool>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditableProfileField(
              label: 'Name',
              value: 'John',
              icon: Icons.person,
              onSave: (_) => completer.future,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(EditableProfileField));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Jane');
      await tester.tap(find.byIcon(Icons.check));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete the future to clean up
      completer.complete(true);
      await tester.pumpAndSettle();
    });

    testWidgets('stays in edit mode if onSave returns false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditableProfileField(
              label: 'Name',
              value: 'John',
              icon: Icons.person,
              onSave: (_) async => false,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(EditableProfileField));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Jane');
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      // Should still be in edit mode
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('applies validator when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditableProfileField(
              label: 'Email',
              value: 'test@example.com',
              icon: Icons.email,
              onSave: (_) async => true,
              validator: (value) {
                if (value == null || !value.contains('@')) {
                  return 'Invalid email';
                }
                return null;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(EditableProfileField));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'invalid');
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(find.text('Invalid email'), findsOneWidget);
    });

    testWidgets('applies text capitalization', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditableProfileField(
              label: 'Postcode',
              value: 'bh1 1aa',
              icon: Icons.pin,
              textCapitalization: TextCapitalization.characters,
              onSave: (_) async => true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(EditableProfileField));
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.textCapitalization, TextCapitalization.characters);
    });

    testWidgets('uses custom keyboard type', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditableProfileField(
              label: 'Phone',
              value: '07123456789',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              onSave: (_) async => true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(EditableProfileField));
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.keyboardType, TextInputType.phone);
    });

    testWidgets('masks value when masked is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditableProfileField(
              label: 'National Insurance',
              value: 'AB123456C',
              icon: Icons.badge,
              masked: true,
              onSave: (_) async => true,
            ),
          ),
        ),
      );

      // Should show masked value (last 4 chars visible)
      expect(find.text('****456C'), findsOneWidget);
    });
  });
}
