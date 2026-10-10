import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_gio_app/models/event_model.dart';
import 'package:so_gio_app/models/note_model.dart';
import 'package:so_gio_app/models/family_person.dart';
import 'package:so_gio_app/services/storage_service.dart';

void main() {
  group('Backup & Restore Data Flow Tests', () {
    late StorageService storageService;

    setUp(() {
      storageService = StorageService();
    });

    test('Xuất dữ liệu sao lưu chứa đầy đủ thông tin gia phả, sự kiện, ghi chú và gia chủ', () async {
      final now = DateTime(2026, 10, 9);
      final events = [
        EventItem(
          id: 'ev_1',
          title: 'Ngày giỗ Ông Nội',
          type: EventType.deathAnniversary,
          calendar: CalendarType.lunar,
          day: 15,
          month: 8,
          personName: 'Ông Nội Mẫu',
          relation: 'Ông nội',
          year: 1985,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final notes = [
        DailyNoteItem(
          id: 'note_1',
          title: 'Chuẩn bị mâm cỗ cúng',
          date: now,
          lunarDay: 15,
          lunarMonth: 8,
          lunarYear: 2026,
          createdAt: now,
        ),
      ];

      final profile = UserProfile(
        giaChu: 'Người Mẫu',
        diaChi: 'Hà Tĩnh',
      );

      final family = [
        const FamilyPerson(
          id: 'fp_1',
          name: 'Người Mẫu',
          gender: 'male',
          branch: 'noi',
        ),
        const FamilyPerson(
          id: 'fp_2',
          name: 'Vợ Mẫu',
          gender: 'female',
          spouseIds: ['fp_1'],
          branch: 'vo_ck',
        ),
      ];

      final jsonString = await storageService.exportBackupData(
        events,
        notes,
        profile,
        family,
      );

      expect(jsonString, isNotEmpty);

      // Giải mã JSON kiểm tra tính toàn vẹn
      final dynamic decoded = jsonDecode(jsonString);
      expect(decoded['version'], equals('1.5.0'));
      expect(decoded['events'], isA<List>());
      expect((decoded['events'] as List).length, equals(1));
      expect(decoded['notes'], isA<List>());
      expect((decoded['notes'] as List).length, equals(1));
      expect(decoded['familyPeople'], isA<List>());
      expect((decoded['familyPeople'] as List).length, equals(2));
      expect(decoded['profile']['giaChu'], equals('Người Mẫu'));
    });

    test('Phục hồi dữ liệu từ JSON parse đúng tiếng Việt có dấu và cấu trúc gia phả', () {
      const backupJson = '''
{
  "version": 1,
  "exportDate": "2026-10-09T10:00:00.000",
  "profile": {
    "giaChu": "Người Mẫu",
    "diaChi": "TP Hà Tĩnh",
    "prayerFontSize": 16.0,
    "isDarkMode": false
  },
  "events": [
    {
      "id": "ev_1",
      "title": "Giỗ Cụ",
      "type": "deathAnniversary",
      "calendar": "lunar",
      "day": 10,
      "month": 3,
      "personName": "Cụ Tổ Họ Lê",
      "createdAt": "2026-10-09T10:00:00.000",
      "updatedAt": "2026-10-09T10:00:00.000"
    }
  ],
  "notes": [
    {
      "id": "n_1",
      "title": "Nhắc việc họ",
      "date": "2026-04-16T00:00:00.000",
      "lunarDay": 10,
      "lunarMonth": 3,
      "lunarYear": 2026,
      "createdAt": "2026-10-09T10:00:00.000"
    }
  ],
  "familyPeople": [
    {
      "id": "p_1",
      "name": "Ông Nội Mẫu",
      "gender": "male",
      "branch": "noi"
    },
    {
      "id": "p_2",
      "name": "Bà Nội Mẫu",
      "gender": "female",
      "spouseIds": ["p_1"],
      "branch": "noi"
    }
  ]
}
''';

      final parsed = storageService.parseBackupData(backupJson);

      final List<EventItem> events = parsed['events'];
      final List<DailyNoteItem> notes = parsed['notes'];
      final List<FamilyPerson> family = parsed['familyPeople'];
      final UserProfile? profile = parsed['profile'];

      expect(events.length, equals(1));
      expect(events.first.title, equals('Giỗ Cụ'));
      expect(events.first.personName, equals('Cụ Tổ Họ Lê'));

      expect(notes.length, equals(1));
      expect(notes.first.title, equals('Nhắc việc họ'));

      expect(family.length, equals(2));
      expect(family[0].name, equals('Ông Nội Mẫu'));
      expect(family[1].name, equals('Bà Nội Mẫu'));
      expect(family[1].spouseIds.contains('p_1'), isTrue);

      expect(profile, isNotNull);
      expect(profile!.giaChu, equals('Người Mẫu'));
      expect(profile.diaChi, equals('TP Hà Tĩnh'));
    });

    test('Từ chối tệp thiếu danh sách để tránh xóa sổ hiện có', () {
      expect(
        () => storageService.parseBackupData('{"profile":{"giaChu":"Mẫu"}}'),
        throwsFormatException,
      );
      expect(
        () => storageService.parseBackupData('{"events":[],"notes":{},"familyPeople":[]}'),
        throwsFormatException,
      );
    });
  });
}
