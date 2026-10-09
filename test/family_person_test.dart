import 'package:flutter_test/flutter_test.dart';
import 'package:so_gio_app/models/family_person.dart';

void main() {
  test('family person survives backup JSON mapping', () {
    const person = FamilyPerson(
      id: 'p1', name: 'Bà An', gender: 'female', branch: 'ngoai',
      birthDate: '1942', deathDate: '12/08/2020', deathCalendar: 'lunar',
      spouseIds: ['p2'], hometown: 'Hà Tĩnh', notes: 'Ghi chép của gia đình',
    );
    final restored = FamilyPerson.fromMap(person.toMap());
    expect(restored.name, 'Bà An');
    expect(restored.branch, 'ngoai');
    expect(restored.deathCalendar, 'lunar');
    expect(restored.spouseIds, ['p2']);
    expect(restored.notes, 'Ghi chép của gia đình');
  });

  test('descendant cannot become parent', () {
    const grandparent = FamilyPerson(id: 'a', name: 'Ông A');
    const parent = FamilyPerson(id: 'b', name: 'Bố B', fatherId: 'a');
    const child = FamilyPerson(id: 'c', name: 'Con C', fatherId: 'b');
    const people = [grandparent, parent, child];
    expect(createsFamilyCycle('a', 'c', people), isTrue);
    expect(createsFamilyCycle('b', 'c', people), isTrue);
    expect(createsFamilyCycle('c', 'a', people), isFalse);
  });
}
