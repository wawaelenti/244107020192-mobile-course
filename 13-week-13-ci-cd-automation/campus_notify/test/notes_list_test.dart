import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/presentation/widgets/notes_list.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('daftar panjang dibuat lazy dan detail memuat isi lengkap', (
    tester,
  ) async {
    final notes = List.generate(
      500,
      (i) => Note(
        id: i,
        title: 'Catatan $i',
        body: 'Isi lengkap $i ' * 100,
        updatedAt: DateTime(2026),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: NotesList(notes))),
    );
    expect(find.byType(NoteTile).evaluate().length, lessThan(500));
    expect(find.text('Catatan 499'), findsNothing);
    final preview = tester.widget<Text>(find.text(notes.first.body));
    expect(preview.maxLines, 2);
    await tester.tap(find.text('Catatan 0'));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(SelectableText, notes.first.body),
      findsOneWidget,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Catatan 499'), 1000);
    expect(find.text('Catatan 499'), findsOneWidget);
  });
}
