import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_gio_app/models/family_person.dart';
import 'package:so_gio_app/screens/family_screen.dart';

void main() {
  testWidgets('thêm người thân trên màn hình điện thoại', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    FamilyPerson? saved;
    await tester.pumpWidget(MaterialApp(home: FamilyScreen(
      people: const [], onSaved: (person) => saved = person, onDeleted: (_) {},
    )));
    await tester.tap(find.byIcon(Icons.person_add_alt_1));
    await tester.pumpAndSettle();
    expect(find.text('Thêm người thân'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Nguyễn Văn An');
    await tester.tap(find.text('Lưu hồ sơ'));
    await tester.pumpAndSettle();
    expect(saved?.name, 'Nguyễn Văn An');
    expect(tester.takeException(), isNull);
  });
}
