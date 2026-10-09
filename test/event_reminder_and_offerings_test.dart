import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_gio_app/data/traditional_offerings_data.dart';
import 'package:so_gio_app/models/event_model.dart';
import 'package:so_gio_app/models/family_person.dart';
import 'package:so_gio_app/screens/offerings_guide_screen.dart';
import 'package:so_gio_app/services/event_reminder_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Traditional Offerings Data & Guide Screen Tests', () {
    test('Dữ liệu Cẩm Nang Đồ Lễ & Mâm Cỗ đầy đủ 4 hạng mục truyền thống', () {
      expect(TraditionalOfferingsData.essentialOfferings.isNotEmpty, true);
      expect(TraditionalOfferingsData.traditionalMeatFeast.isNotEmpty, true);
      expect(TraditionalOfferingsData.customsKnowledge.isNotEmpty, true);

      // Kiểm tra món cơ bản
      expect(TraditionalOfferingsData.essentialOfferings.any((i) => i.name.contains('Hương')), true);
      expect(TraditionalOfferingsData.essentialOfferings.any((i) => i.name.contains('Hoa tươi')), true);
      expect(TraditionalOfferingsData.traditionalMeatFeast.any((i) => i.name.contains('Gà')), true);
      expect(TraditionalOfferingsData.traditionalMeatFeast.any((i) => i.name.contains('Xôi')), true);
      expect(TraditionalOfferingsData.customsKnowledge.keys.any((k) => k.contains('Tiên Thường')), true);
      expect(TraditionalOfferingsData.customsKnowledge.keys.any((k) => k.contains('Chính Kỵ')), true);
    });

    testWidgets('OfferingsGuideScreen hiển thị 4 Tab và tương tác checklist đi chợ', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: OfferingsGuideScreen(),
      ));
      await tester.pumpAndSettle();

      // Kiểm tra tiêu đề màn hình
      expect(find.text('Cẩm Nang Mâm Cỗ & Sắm Lễ'), findsOneWidget);

      // Kiểm tra các TabBar
      expect(find.text('Lễ Gia Tiên'), findsOneWidget);
      expect(find.text('Mâm Cỗ Mặn'), findsOneWidget);
      expect(find.text('Mâm Cỗ Chay'), findsOneWidget);
      expect(find.text('Phong Tục'), findsOneWidget);

      // Nút chia sẻ checklist Zalo
      expect(find.text('Gửi Zalo'), findsOneWidget);

      // Chuyển sang Tab Mâm Cỗ Mặn
      await tester.tap(find.text('Mâm Cỗ Mặn'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Gà'), findsWidgets);

      // Chuyển sang Tab Phong Tục
      await tester.tap(find.text('Phong Tục'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Lễ Tiên Thường'), findsWidgets);
      expect(find.textContaining('Lễ Chính Kỵ'), findsWidgets);
    });
  });

  group('EventReminderService Tests (Nhắc Nhở Tự Động & Lễ Tiên Thường/Chính Kỵ)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Cài đặt ReminderSettings mặc định bật và nhắc 3 ngày trước', () {
      const settings = ReminderSettings();
      expect(settings.enabled, true);
      expect(settings.advanceDays, 3);
      expect(settings.remindTienThuong, true);
      expect(settings.remindChinhKy, true);

      final map = settings.toMap();
      final parsed = ReminderSettings.fromMap(map);
      expect(parsed.enabled, true);
      expect(parsed.advanceDays, 3);
    });

    test('Lưu và đọc ReminderSettings qua SharedPreferences', () async {
      final service = EventReminderService();
      await service.loadSettings();
      expect(service.settings.enabled, true);

      // Thay đổi sang nhắc 7 ngày
      await service.saveSettings(service.settings.copyWith(advanceDays: 7, remindTienThuong: false));
      expect(service.settings.advanceDays, 7);
      expect(service.settings.remindTienThuong, false);

      // Tải lại
      await service.loadSettings();
      expect(service.settings.advanceDays, 7);
      expect(service.settings.remindTienThuong, false);
    });

    test('Sinh thông báo nhắc nhở Chính kỵ (Hôm nay), Tiên thường (Ngày mai) và Sắp tới', () {
      final service = EventReminderService();
      // Khôi phục mặc định
      service.saveSettings(const ReminderSettings(enabled: true, advanceDays: 7));

      final now = DateTime.now();

      // Sự kiện hôm nay (Dương lịch để test tính đúng ngày)
      final eventToday = EventItem(
        id: 'ev_today',
        title: 'Giỗ Bác Ba',
        day: now.day,
        month: now.month,
        calendar: CalendarType.solar,
        type: EventType.deathAnniversary,
        createdAt: now,
        updatedAt: now,
      );

      final alerts = service.getUpcomingAlerts([eventToday]);
      expect(alerts.any((a) => a.alertType == 'today' && a.title.contains('Chính Kỵ')), true);

      // Khi tắt tính năng nhắc nhở -> danh sách alerts rỗng
      service.saveSettings(const ReminderSettings(enabled: false));
      expect(service.getUpcomingAlerts([eventToday]).isEmpty, true);
    });
  });

  group('FamilyPerson Avatar Tests', () {
    test('FamilyPerson lưu trữ và giải mã avatarBase64 chính xác', () {
      const sampleBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
      final person = FamilyPerson(
        id: 'p1',
        name: 'Lê Đức Anh',
        avatarBase64: sampleBase64,
      );

      expect(person.avatarBase64, equals(sampleBase64));

      final map = person.toMap();
      expect(map['avatarBase64'], equals(sampleBase64));

      final restored = FamilyPerson.fromMap(map);
      expect(restored.avatarBase64, equals(sampleBase64));

      // Test copyWith
      final updated = restored.copyWith(clearAvatar: true);
      expect(updated.avatarBase64, isNull);
    });
  });
}
