import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_gio_app/models/event_model.dart';
import 'package:so_gio_app/services/storage_service.dart';

void main() {
  final now = DateTime(2026, 10, 10);
  final event = EventItem(
    id: 'legacy-event',
    title: 'Giỗ ông',
    type: EventType.deathAnniversary,
    calendar: CalendarType.lunar,
    day: 15,
    month: 6,
    isLeapMonth: true,
    createdAt: now,
    updatedAt: now,
  );

  test('Di trú dữ liệu cũ một lần và không hồi sinh bản ghi đã xóa', () async {
    SharedPreferences.setMockInitialValues({
      'app_events_json': jsonEncode([event.toMap()]),
    });
    final factory = newDatabaseFactoryMemory();
    final storage = StorageService(databaseFactory: factory);
    final loaded = await storage.loadEvents();
    expect(loaded.single.id, event.id);
    expect(loaded.single.isLeapMonth, isTrue);

    await storage.saveEvents([]);
    expect(await storage.loadEvents(), isEmpty);
    final reopened = StorageService(databaseFactory: factory);
    expect(await reopened.loadEvents(), isEmpty);
  });

  test('Dữ liệu cũ hỏng không bị biến thành danh sách trống', () async {
    SharedPreferences.setMockInitialValues({'app_events_json': '{hỏng'});
    final storage = StorageService(databaseFactory: newDatabaseFactoryMemory());
    await expectLater(storage.loadEvents(), throwsFormatException);
  });

  test('Dữ liệu cũ trùng mã không bị âm thầm ghi đè', () async {
    SharedPreferences.setMockInitialValues({
      'app_events_json': jsonEncode([event.toMap(), event.toMap()]),
    });
    final storage = StorageService(databaseFactory: newDatabaseFactoryMemory());
    await expectLater(storage.loadEvents(), throwsFormatException);
  });

  test('Hai lần lưu nhanh giữ phiên bản mới nhất', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService(databaseFactory: newDatabaseFactoryMemory());
    final first = storage.saveEvents([event]);
    final second = storage.saveEvents([]);
    await Future.wait([first, second]);
    expect(await storage.loadEvents(), isEmpty);
  });

  test('Khôi phục nhiều danh sách là một giao dịch, lỗi không xóa bản cũ', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService(databaseFactory: newDatabaseFactoryMemory());
    await storage.saveEvents([event]);
    final invalidEvent = EventItem(
      id: '',
      title: 'Bản lỗi',
      type: EventType.custom,
      calendar: CalendarType.solar,
      day: 1,
      month: 1,
      createdAt: now,
      updatedAt: now,
    );
    await expectLater(
      storage.replaceAllData(
        events: [invalidEvent], notes: [], familyPeople: [],
      ),
      throwsFormatException,
    );
    expect((await storage.loadEvents()).single.id, event.id);
    await expectLater(
      storage.replaceAllData(
        events: [event, event], notes: [], familyPeople: [],
      ),
      throwsFormatException,
    );
    expect((await storage.loadEvents()).single.id, event.id);
  });
}
