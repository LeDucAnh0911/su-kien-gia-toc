import '../lunar_engine.dart';
import '../models/event_model.dart';

class EventOccurrence {
  final EventItem event;
  final DateTime nextSolarDate;       // Ngày Chính kỵ (Dương lịch)
  final DateTime? tienThuongSolarDate; // Ngày Tiên thường (Dương lịch)
  final int daysRemaining;            // Số ngày còn lại (0 = hôm nay, 1 = ngày mai)
  final int adjustedDay;              // Ngày cúng thực tế (xử lý tháng thiếu 29)
  final int? anniversaryCount;        // Giỗ lần thứ mấy (nếu có năm mất)
  final String? canChiYear;           // Năm Can Chi

  EventOccurrence({
    required this.event,
    required this.nextSolarDate,
    this.tienThuongSolarDate,
    required this.daysRemaining,
    required this.adjustedDay,
    this.anniversaryCount,
    this.canChiYear,
  });

  bool get isToday => daysRemaining == 0;
  bool get isTomorrow => daysRemaining == 1;
  bool get isTienThuongToday {
    if (tienThuongSolarDate == null) return false;
    final now = DateTime.now();
    return tienThuongSolarDate!.year == now.year &&
           tienThuongSolarDate!.month == now.month &&
           tienThuongSolarDate!.day == now.day;
  }
}

class EventCalculator {
  /// Tính toán lần xảy ra tiếp theo cho một sự kiện
  static EventOccurrence? calculateNextOccurrence(EventItem event, [DateTime? fromDate]) {
    final now = fromDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (event.calendar == CalendarType.lunar) {
      // Sự kiện ÂM LỊCH (Ngày Giỗ, Rằm, v.v...)
      final result = VietnameseLunarEngine.getNextDeathAnniversary(
        lunarDay: event.day,
        lunarMonth: event.month,
        isLeapMonth: event.isLeapMonth,
        fromSolarDate: today,
      );

      if (result == null) return null;

      int? anniversary;
      if (event.year != null && result.lunarYear >= event.year!) {
        anniversary = result.lunarYear - event.year!;
      }

      return EventOccurrence(
        event: event,
        nextSolarDate: result.chinhKySolar,
        tienThuongSolarDate: event.remindTienThuong ? result.tiengThuongSolar : null,
        daysRemaining: result.daysRemaining,
        adjustedDay: result.adjustedLunarDay,
        anniversaryCount: anniversary,
        canChiYear: result.canChiYear,
      );
    } else {
      // Sự kiện DƯƠNG LỊCH (Sinh nhật Dương, kỷ niệm ngày cưới...)
      final currentYear = today.year;
      DateTime candidate;

      // Xử lý 29/2 năm nhuận
      if (event.month == 2 && event.day == 29) {
        final isLeapYear = (currentYear % 4 == 0 && currentYear % 100 != 0) || (currentYear % 400 == 0);
        candidate = isLeapYear ? DateTime(currentYear, 2, 29) : DateTime(currentYear, 2, 28);
      } else {
        candidate = DateTime(currentYear, event.month, event.day);
      }

      if (candidate.isBefore(today)) {
        final nextYear = currentYear + 1;
        final isNextLeap = (nextYear % 4 == 0 && nextYear % 100 != 0) || (nextYear % 400 == 0);
        candidate = (event.month == 2 && event.day == 29 && !isNextLeap)
            ? DateTime(nextYear, 2, 28)
            : DateTime(nextYear, event.month, event.day);
      }

      final daysRemaining = VietnameseLunarEngine.jdFromDate(
            candidate.day, candidate.month, candidate.year,
          ) -
          VietnameseLunarEngine.jdFromDate(today.day, today.month, today.year);
      int? anniversary;
      if (event.year != null && candidate.year >= event.year!) {
        anniversary = candidate.year - event.year!;
      }

      return EventOccurrence(
        event: event,
        nextSolarDate: candidate,
        tienThuongSolarDate: event.remindTienThuong ? candidate.subtract(const Duration(days: 1)) : null,
        daysRemaining: daysRemaining,
        adjustedDay: event.day,
        anniversaryCount: anniversary,
      );
    }
  }

  /// Tính toán và sắp xếp danh sách sự kiện theo thứ tự gần nhất
  static List<EventOccurrence> getSortedOccurrences(List<EventItem> events, [DateTime? fromDate]) {
    final list = <EventOccurrence>[];
    for (final ev in events) {
      final occ = calculateNextOccurrence(ev, fromDate);
      if (occ != null) {
        list.add(occ);
      }
    }
    list.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
    return list;
  }
}
