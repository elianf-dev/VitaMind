import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitamind/widgets/delete_account_dialog.dart';

/// Opens the dialog from a button and records what it returned.
Future<List<bool?>> _pumpDialog(
  WidgetTester tester,
  Future<String?> Function(String password) onDelete,
) async {
  final results = <bool?>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              results.add(
                await showDialog<bool>(
                  context: context,
                  builder: (context) => DeleteAccountDialog(
                    email: 'me@example.com',
                    onDelete: onDelete,
                  ),
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return results;
}

FilledButton _deleteButton(WidgetTester tester) => tester.widget<FilledButton>(
  find.widgetWithText(FilledButton, 'Delete Account'),
);

void main() {
  testWidgets('Delete stays disabled until a password is entered', (
    tester,
  ) async {
    await _pumpDialog(tester, (_) async => null);

    expect(find.text('Enter the password for me@example.com.'), findsOneWidget);
    expect(_deleteButton(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'secret');
    await tester.pump();
    expect(_deleteButton(tester).onPressed, isNotNull);
  });

  testWidgets('a wrong password shows inline and keeps the dialog open', (
    tester,
  ) async {
    final passwords = <String>[];
    final results = await _pumpDialog(tester, (password) async {
      passwords.add(password);
      return 'That password is incorrect.';
    });

    await tester.enterText(find.byType(TextField), 'wrong');
    await tester.pump();
    await tester.tap(find.text('Delete Account'));
    await tester.pumpAndSettle();

    expect(passwords, ['wrong']);
    expect(find.text('That password is incorrect.'), findsOneWidget);
    expect(find.byType(DeleteAccountDialog), findsOneWidget);
    expect(results, isEmpty);
  });

  testWidgets('a successful delete closes the dialog with true', (
    tester,
  ) async {
    final results = await _pumpDialog(tester, (_) async => null);

    await tester.enterText(find.byType(TextField), 'secret');
    // Submitting from the keyboard works the same as tapping Delete.
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.byType(DeleteAccountDialog), findsNothing);
    expect(results, [true]);
  });

  testWidgets('Cancel closes without deleting', (tester) async {
    var called = false;
    final results = await _pumpDialog(tester, (_) async {
      called = true;
      return null;
    });

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(called, isFalse);
    expect(results, [false]);
  });

  testWidgets('dialog meets tap target, label, and contrast guidelines', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pumpDialog(tester, (_) async => null);
    await tester.enterText(find.byType(TextField), 'secret');
    // Let the button finish fading from disabled to enabled colors.
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
