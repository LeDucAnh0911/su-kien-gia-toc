import 'package:flutter_test/flutter_test.dart';
import 'package:so_gio_app/lunar_engine.dart';
import 'package:so_gio_app/models/event_model.dart';
import 'package:so_gio_app/services/event_calculator.dart';

void main() {
  test('Test Lunar Engine conversion for Tet Nguyen Dan', () {
    // 01/01/2026 Âm lịch -> Dương lịch
    final solar = VietnameseLunarEngine.lunarToSolar(1, 1, 2026);
    expect(solar, isNotNull);
    expect(solar![0], 17);
    expect(solar[1], 2);
    expect(solar[2], 2026);
  });

  test('Tháng thường và tháng nhuận năm 2025 không trùng nhau', () {
    expect(VietnameseLunarEngine.lunarToSolar(15, 6, 2025), [9, 7, 2025]);
    expect(
      VietnameseLunarEngine.lunarToSolar(15, 6, 2025, isLeap: true),
      [8, 8, 2025],
    );
    expect(VietnameseLunarEngine.lunarToSolar(31, 6, 2025), isNull);
    expect(VietnameseLunarEngine.lunarToSolar(15, 5, 2025, isLeap: true), isNull);
  });

  test('Âm và dương lịch đổi qua lại nhất quán giai đoạn 2024–2030', () {
    for (var date = DateTime(2024, 1, 1);
        date.isBefore(DateTime(2031, 1, 1));
        date = date.add(const Duration(days: 1))) {
      final lunar = VietnameseLunarEngine.solarToLunar(
        date.day, date.month, date.year,
      );
      expect(
        VietnameseLunarEngine.lunarToSolar(
          lunar.day, lunar.month, lunar.year, isLeap: lunar.isLeap,
        ),
        [date.day, date.month, date.year],
        reason: '${date.day}/${date.month}/${date.year}',
      );
    }
  });

  test('Đầu năm dương vẫn tìm được ngày giỗ thuộc năm âm trước', () {
    final expected = VietnameseLunarEngine.lunarToSolar(15, 12, 2025)!;
    final result = VietnameseLunarEngine.getNextDeathAnniversary(
      lunarDay: 15,
      lunarMonth: 12,
      fromSolarDate: DateTime(2026, 1, 1),
    );
    expect(result, isNotNull);
    expect(result!.lunarYear, 2025);
    expect(
      [result.chinhKySolar.day, result.chinhKySolar.month, result.chinhKySolar.year],
      expected,
    );
  });

  test('Giỗ tháng nhuận theo tháng thường khi năm sau không có tháng nhuận', () {
    final event = EventItem(
      id: 'leap-anniversary',
      title: 'Giỗ tháng nhuận',
      type: EventType.deathAnniversary,
      calendar: CalendarType.lunar,
      day: 15,
      month: 6,
      year: 2025,
      isLeapMonth: true,
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
    );
    final occurrence = EventCalculator.calculateNextOccurrence(
      event, DateTime(2026, 1, 1),
    );
    final expected = VietnameseLunarEngine.lunarToSolar(15, 6, 2026)!;
    expect(occurrence, isNotNull);
    expect(
      [occurrence!.nextSolarDate.day, occurrence.nextSolarDate.month,
       occurrence.nextSolarDate.year],
      expected,
    );
  });
}
