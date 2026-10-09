import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_gio_app/models/event_model.dart';
import 'package:so_gio_app/screens/event_detail_screen.dart';
import 'package:so_gio_app/screens/home_screen.dart';
import 'package:so_gio_app/services/storage_service.dart';

void main() {
  final now = DateTime.now();

  final birthdayEvent = EventItem(
    id: 'ev_birthday',
    title: 'Sinh nhật Bố',
    type: EventType.birthday,
    calendar: CalendarType.solar,
    day: 15,
    month: 10,
    personName: 'Lê Văn Hùng',
    createdAt: now,
    updatedAt: now,
  );

  final deathEvent = EventItem(
    id: 'ev_death',
    title: 'Giỗ Cụ Ông',
    type: EventType.deathAnniversary,
    calendar: CalendarType.lunar,
    day: 15,
    month: 8,
    personName: 'Lê Văn Đô',
    createdAt: now,
    updatedAt: now,
  );

  testWidgets('EventDetailScreen: Sinh nhật không có Tạo Văn Khấn và không có Thu Chi Giỗ Họ', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: EventDetailScreen(
        event: birthdayEvent,
        profile: UserProfile(),
        onProfileUpdated: (_) {},
        onEventUpdated: (_) {},
        onEventDeleted: () {},
      ),
    ));

    // Không có nút văn khấn
    expect(find.textContaining('Văn Khấn'), findsNothing);
    // Không có mục Đóng góp / thu chi
    expect(find.textContaining('Đóng Góp / Thu Chi'), findsNothing);
  });

  testWidgets('EventDetailScreen: Ngày giỗ có nút Tạo Văn Khấn và không có Thu Chi Giỗ Họ', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: EventDetailScreen(
        event: deathEvent,
        profile: UserProfile(),
        onProfileUpdated: (_) {},
        onEventUpdated: (_) {},
        onEventDeleted: () {},
      ),
    ));

    // Có nút Tạo Văn Khấn
    expect(find.textContaining('Tạo Văn Khấn'), findsOneWidget);
    // Không có mục Đóng góp / thu chi
    expect(find.textContaining('Đóng Góp / Thu Chi'), findsNothing);
  });

  testWidgets('HomeScreen: Hiển thị tab Sự Kiện và nút Thêm sự kiện', (tester) async {
    tester.view.physicalSize = const Size(1280, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(MaterialApp(
      home: HomeScreen(
        events: [birthdayEvent, deathEvent],
        notes: const [],
        profile: UserProfile(),
        onProfileUpdated: (_) {},
        onNavigateTab: (_) {},
        onEventAdded: (_) {},
        onEventUpdated: (_) {},
        onEventDeleted: (_) {},
        onNoteAdded: (_) {},
        onNoteUpdated: (_) {},
        onNoteDeleted: (_) {},
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Sự Kiện (2)'), findsOneWidget);
    expect(find.text('Thêm sự kiện'), findsOneWidget);
  });
}
