import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_gio_app/models/event_model.dart';
import 'package:so_gio_app/screens/calendar_screen.dart';
import 'package:so_gio_app/services/storage_service.dart';

void main() {
  EventItem nextMonthEvent() {
    final date = DateTime(DateTime.now().year, DateTime.now().month + 1, 15);
    final now = DateTime.now();
    return EventItem(
      id: 'calendar-label-test',
      title: 'Giỗ Bác Cả',
      type: EventType.deathAnniversary,
      calendar: CalendarType.solar,
      day: date.day,
      month: date.month,
      createdAt: now,
      updatedAt: now,
    );
  }

  Widget calendar(List<EventItem> events) => MaterialApp(
        home: CalendarScreen(
          events: events,
          notes: const [],
          profile: UserProfile(),
          onProfileUpdated: (_) {},
          onEventAdded: (_) {},
          onEventUpdated: (_) {},
          onEventDeleted: (_) {},
          onNoteAdded: (_) {},
          onNoteUpdated: (_) {},
          onNoteDeleted: (_) {},
        ),
      );

  testWidgets('ô rộng hiển thị tên giỗ ở tháng kế tiếp', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(calendar([nextMonthEvent()]));
    expect(find.text('Giỗ Bác Cả'), findsNothing);
    await tester.tap(find.byTooltip('Tháng sau'));
    await tester.pumpAndSettle();
    expect(find.text('Giỗ Bác Cả'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ô hẹp giữ ngày tháng rõ ràng và không tràn', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(calendar([nextMonthEvent()]));
    await tester.tap(find.byTooltip('Tháng sau'));
    await tester.pumpAndSettle();
    expect(find.text('Giỗ Bác Cả'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
