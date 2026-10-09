/// Vietnamese Lunar Engine (Thuật toán Âm Lịch Việt Nam chuẩn GMT+7 của TS. Hồ Ngọc Đức)
/// Hỗ trợ chuyển đổi Âm - Dương, Can Chi, và xử lý ngày giỗ theo tháng thiếu & tháng nhuận.

import 'dart:math' as math;

class LunarDate {
  final int day;
  final int month;
  final int year;
  final bool isLeap;
  final int jd;

  const LunarDate({
    required this.day,
    required this.month,
    required this.year,
    required this.isLeap,
    required this.jd,
  });

  @override
  String toString() {
    return 'Ngày $day tháng $month năm $year ${isLeap ? "(Nhuận)" : ""}';
  }
}

class NextDeathAnniversaryResult {
  final DateTime chinhKySolar;
  final DateTime tiengThuongSolar;
  final int daysRemaining;
  final int adjustedLunarDay;
  final int originalLunarDay;
  final int lunarMonth;
  final int lunarYear;
  final String canChiYear;

  const NextDeathAnniversaryResult({
    required this.chinhKySolar,
    required this.tiengThuongSolar,
    required this.daysRemaining,
    required this.adjustedLunarDay,
    required this.originalLunarDay,
    required this.lunarMonth,
    required this.lunarYear,
    required this.canChiYear,
  });
}

class VietnameseLunarEngine {
  static const List<String> can = [
    'Giáp', 'Ất', 'Bính', 'Đinh', 'Mậu', 'Kỷ', 'Canh', 'Tân', 'Nhâm', 'Quý'
  ];

  static const List<String> chi = [
    'Tý', 'Sửu', 'Dần', 'Mão', 'Thìn', 'Tỵ', 'Ngọ', 'Mùi', 'Thân', 'Dậu', 'Tuất', 'Hợi'
  ];

  /// Tính số ngày Julius từ ngày Dương lịch
  static int jdFromDate(int day, int month, int year) {
    final a = (14 - month) ~/ 12;
    final y = year + 4800 - a;
    final m = month + 12 * a - 3;
    return day + ((153 * m + 2) ~/ 5) + 365 * y + (y ~/ 4) - (y ~/ 100) + (y ~/ 400) - 32045;
  }

  /// Chuyển số ngày Julius sang ngày Dương lịch [day, month, year]
  static List<int> jdToDate(int jd) {
    final a = jd + 32044;
    final b = (4 * a + 3) ~/ 146097;
    final c = a - (146097 * b) ~/ 4;
    final d = (4 * c + 3) ~/ 1461;
    final e = c - (1461 * d) ~/ 4;
    final m = (5 * e + 2) ~/ 153;
    final day = e - ((153 * m + 2) ~/ 5) + 1;
    final month = m + 3 - 12 * (m ~/ 10);
    final year = 100 * b + d - 4800 + (m ~/ 10);
    return [day, month, year];
  }

  /// Tính ngày Sóc (New Moon) theo múi giờ chỉ định
  static int getNewMoonDay(int k, [double timezone = 7.0]) {
    final t = k / 1236.85;
    final t2 = t * t;
    final t3 = t2 * t;
    final jd1 = 2415020.75933 + 29.53058868 * k + 0.0001178 * t2 - 0.000000155 * t3;

    final m = 359.2242 + 29.10535608 * k - 0.0000333 * t2 - 0.00000347 * t3;
    final mRad = m * math.pi / 180.0;

    final mprime = 306.0253 + 385.81691806 * k + 0.0107306 * t2 + 0.00001236 * t3;
    final mprimeRad = mprime * math.pi / 180.0;

    final f = 21.2964 + 390.67050646 * k - 0.0016528 * t2 - 0.00000239 * t3;
    final fRad = f * math.pi / 180.0;

    final deltaJd = (0.1734 - 0.000393 * t) * math.sin(mRad) +
        0.0021 * math.sin(2 * mRad) -
        0.4068 * math.sin(mprimeRad) +
        0.0161 * math.sin(2 * mprimeRad) -
        0.0004 * math.sin(3 * mprimeRad) +
        0.0104 * math.sin(2 * fRad) -
        0.0051 * math.sin(mRad + mprimeRad) -
        0.0074 * math.sin(mRad - mprimeRad) +
        0.0004 * math.sin(2 * fRad + mRad) -
        0.0004 * math.sin(2 * fRad - mRad) -
        0.0006 * math.sin(2 * fRad + mprimeRad) +
        0.0010 * math.sin(2 * fRad - mprimeRad) +
        0.0005 * math.sin(mRad + 2 * mprimeRad);

    final jd = jd1 + deltaJd;
    return (jd + 0.5 + timezone / 24.0).toInt();
  }

  /// Tính kinh độ Mặt Trời (đơn vị cung hoàng đạo, 0..11)
  static int getSunLongitude(int jdn, [double timezone = 7.0]) {
    final t = (jdn - 0.5 - timezone / 24.0 - 2451545.0) / 36525.0;
    final t2 = t * t;
    final dr = math.pi / 180.0;

    final l0 = 280.46645 + 36000.76983 * t + 0.0003032 * t2;
    final m = 357.52910 + 35999.05030 * t - 0.0001559 * t2 - 0.00000048 * t * t2;

    final c = (1.914600 - 0.004817 * t - 0.000014 * t2) * math.sin(m * dr) +
        (0.019993 - 0.000101 * t) * math.sin(2 * m * dr) +
        0.000290 * math.sin(3 * m * dr);

    var theta = (l0 + c) % 360.0;
    if (theta < 0) theta += 360.0;
    return (theta / 30.0).toInt();
  }

  /// Tìm ngày Sóc của tháng 11 Âm lịch
  static int getLunarMonth11(int year, [double timezone = 7.0]) {
    final off = jdFromDate(31, 12, year) - 2415021;
    final k = (off / 29.530588853).toInt();
    var nm = getNewMoonDay(k, timezone);
    final sunLong = getSunLongitude(nm, timezone);
    if (sunLong >= 9) {
      nm = getNewMoonDay(k - 1, timezone);
    }
    return nm;
  }

  /// Xác định tháng nhuận
  static int getLeapMonthOffset(int a11, [double timezone = 7.0]) {
    final k = ((a11 - 2415021.076998695) / 29.530588853 + 0.5).toInt();
    var last = 0;
    var i = 1;
    var arc = getSunLongitude(getNewMoonDay(k + i, timezone), timezone);
    while (true) {
      last = arc;
      i += 1;
      arc = getSunLongitude(getNewMoonDay(k + i, timezone), timezone);
      if (arc == last || i >= 14) break;
    }
    return i - 1;
  }

  /// Chuyển đổi Dương lịch sang Âm lịch
  static LunarDate solarToLunar(int day, int month, int year, [double timezone = 7.0]) {
    final dayNumber = jdFromDate(day, month, year);
    final k = ((dayNumber - 2415021.076998695) / 29.530588853).toInt();
    var monthStart = getNewMoonDay(k + 1, timezone);
    if (monthStart > dayNumber) {
      monthStart = getNewMoonDay(k, timezone);
    }

    var a11 = getLunarMonth11(year, timezone);
    var b11 = a11;
    int lunarYear;
    if (a11 >= monthStart) {
      lunarYear = year;
      a11 = getLunarMonth11(year - 1, timezone);
    } else {
      lunarYear = year + 1;
      b11 = getLunarMonth11(year + 1, timezone);
    }

    final lunarDay = dayNumber - monthStart + 1;
    final diff = ((monthStart - a11) / 29.0).toInt();
    var lunarLeap = 0;
    var lunarMonth = diff + 11;

    if ((b11 - a11) > 365) {
      final leapOff = getLeapMonthOffset(a11, timezone);
      var leapMonth = leapOff - 2;
      if (leapMonth < 0) leapMonth += 12;
      if (diff >= leapOff) {
        lunarMonth = diff + 10;
        if (diff == leapOff) lunarLeap = 1;
      }
    }

    if (lunarMonth > 12) lunarMonth -= 12;
    if (lunarMonth >= 11 && diff < 4) lunarYear -= 1;

    return LunarDate(
      day: lunarDay,
      month: lunarMonth,
      year: lunarYear,
      isLeap: lunarLeap == 1,
      jd: dayNumber,
    );
  }

  /// Chuyển đổi Âm lịch sang Dương lịch [day, month, year]
  static List<int>? lunarToSolar(int lunarDay, int lunarMonth, int lunarYear, {bool isLeap = false, double timezone = 7.0}) {
    int a11, b11;
    if (lunarMonth < 11) {
      a11 = getLunarMonth11(lunarYear - 1, timezone);
      b11 = getLunarMonth11(lunarYear, timezone);
    } else {
      a11 = getLunarMonth11(lunarYear, timezone);
      b11 = getLunarMonth11(lunarYear + 1, timezone);
    }

    final k = ((a11 - 2415021.076998695) / 29.530588853 + 0.5).toInt();
    var off = lunarMonth - 11;
    if (off < 0) off += 12;

    if ((b11 - a11) > 365) {
      final leapOff = getLeapMonthOffset(a11, timezone);
      var leapMonth = leapOff - 2;
      if (leapMonth < 0) leapMonth += 12;
      if (isLeap && (lunarMonth != leapMonth)) return null;
      if ((off >= leapOff - 1) || isLeap) off += 1;
    }

    final monthStart = getNewMoonDay(k + off, timezone);
    return jdToDate(monthStart + lunarDay - 1);
  }

  /// Lấy số ngày của tháng âm lịch (29 hay 30 ngày)
  static int getLunarMonthDays(int lunarMonth, int lunarYear) {
    final res30 = lunarToSolar(30, lunarMonth, lunarYear, isLeap: false);
    if (res30 != null) {
      final back = solarToLunar(res30[0], res30[1], res30[2]);
      if (back.month == lunarMonth && back.day == 30) {
        return 30;
      }
    }
    return 29;
  }

  /// Tính Can Chi của năm
  static String getCanChiYear(int lunarYear) {
    final c = can[(lunarYear + 6) % 10];
    final ch = chi[(lunarYear + 8) % 12];
    return '$c $ch';
  }

  /// Tính Can Chi của ngày
  static String getCanChiDay(int jd) {
    final c = can[(jd + 9) % 10];
    final ch = chi[(jd + 1) % 12];
    return '$c $ch';
  }

  /// Tính ngày giỗ tiếp theo theo Dương lịch
  static NextDeathAnniversaryResult? getNextDeathAnniversary({
    required int lunarDay,
    required int lunarMonth,
    DateTime? fromSolarDate,
  }) {
    final fromDate = fromSolarDate ?? DateTime.now();
    final currentYear = fromDate.year;

    for (final yearCand in [currentYear, currentYear + 1]) {
      final maxDays = getLunarMonthDays(lunarMonth, yearCand);
      final targetDay = math.min(lunarDay, maxDays);

      final res = lunarToSolar(targetDay, lunarMonth, yearCand, isLeap: false);
      if (res != null) {
        final solarDate = DateTime(res[2], res[1], res[0]);
        // So sánh tính cả ngày hôm nay
        final checkFrom = DateTime(fromDate.year, fromDate.month, fromDate.day);
        if (!solarDate.isBefore(checkFrom)) {
          final daysRemaining = solarDate.difference(checkFrom).inDays;
          final tiengThuongDate = solarDate.subtract(const Duration(days: 1));

          return NextDeathAnniversaryResult(
            chinhKySolar: solarDate,
            tiengThuongSolar: tiengThuongDate,
            daysRemaining: daysRemaining,
            adjustedLunarDay: targetDay,
            originalLunarDay: lunarDay,
            lunarMonth: lunarMonth,
            lunarYear: yearCand,
            canChiYear: getCanChiYear(yearCand),
          );
        }
      }
    }
    return null;
  }

  /// Danh sách Giờ Hoàng Đạo trong ngày dựa vào Chi của ngày
  static List<String> getHoangDaoHours(int jd) {
    final dayChiIndex = (jd + 1) % 12;
    // Nhóm cặp chi
    // 0: Tý, 1: Sửu, 2: Dần, 3: Mão, 4: Thìn, 5: Tỵ, 6: Ngọ, 7: Mùi, 8: Thân, 9: Dậu, 10: Tuất, 11: Hợi
    List<int> hoangDaoChiIndices;
    if (dayChiIndex == 2 || dayChiIndex == 8) {
      // Dần, Thân: Tý, Sửu, Thìn, Tỵ, Mùi, Tuất
      hoangDaoChiIndices = [0, 1, 4, 5, 7, 10];
    } else if (dayChiIndex == 3 || dayChiIndex == 9) {
      // Mão, Dậu: Tý, Dần, Mão, Ngọ, Mùi, Dậu
      hoangDaoChiIndices = [0, 2, 3, 6, 7, 9];
    } else if (dayChiIndex == 4 || dayChiIndex == 10) {
      // Thìn, Tuất: Dần, Thìn, Tỵ, Thân, Dậu, Hợi
      hoangDaoChiIndices = [2, 4, 5, 8, 9, 11];
    } else if (dayChiIndex == 5 || dayChiIndex == 11) {
      // Tỵ, Hợi: Sửu, Thìn, Ngọ, Mùi, Tuất, Hợi
      hoangDaoChiIndices = [1, 4, 6, 7, 10, 11];
    } else if (dayChiIndex == 0 || dayChiIndex == 6) {
      // Tý, Ngọ: Tý, Sửu, Mão, Ngọ, Thân, Dậu
      hoangDaoChiIndices = [0, 1, 3, 6, 8, 9];
    } else {
      // Sửu, Mùi: Dần, Mão, Tỵ, Thân, Tuất, Hợi
      hoangDaoChiIndices = [2, 3, 5, 8, 10, 11];
    }

    const chiTimes = [
      'Tý (23h-01h)', 'Sửu (01h-03h)', 'Dần (03h-05h)', 'Mão (05h-07h)',
      'Thìn (07h-09h)', 'Tỵ (09h-11h)', 'Ngọ (11h-13h)', 'Mùi (13h-15h)',
      'Thân (15h-17h)', 'Dậu (17h-19h)', 'Tuất (19h-21h)', 'Hợi (21h-23h)'
    ];

    return hoangDaoChiIndices.map((i) => chiTimes[i]).toList();
  }

  /// Can Chi của Tháng
  static String getCanChiMonth(int lunarMonth, int lunarYear) {
    final yearCanIndex = (lunarYear + 6) % 10;
    // Bính Dần (2), Mậu Dần (4), Canh Dần (6), Nhâm Dần (8), Giáp Dần (0)
    final startCan = (yearCanIndex * 2 + 2) % 10;
    final monthCan = can[(startCan + (lunarMonth - 1)) % 10];
    final monthChi = chi[(lunarMonth + 1) % 12];
    return '$monthCan $monthChi';
  }

  /// Lấy Tiết Khí dựa vào ngày Dương lịch
  static String getSolarTerm(int day, int month, int year, [double timezone = 7.0]) {
    final jd = jdFromDate(day, month, year);
    final t = (jd - 0.5 - timezone / 24.0 - 2451545.0) / 36525.0;
    final dr = math.pi / 180.0;
    final l0 = 280.46645 + 36000.76983 * t;
    final m = 357.52910 + 35999.05030 * t;
    final c = 1.914600 * math.sin(m * dr);
    var theta = (l0 + c) % 360.0;
    if (theta < 0) theta += 360.0;

    const terms = [
      'Xuân Phân', 'Thanh Minh', 'Cốc Vũ', 'Lập Hạ', 'Tiểu Mãn', 'Mang Chủng',
      'Hạ Chí', 'Tiểu Thử', 'Đại Thử', 'Lập Thu', 'Xử Thử', 'Bạch Lộ',
      'Thu Phân', 'Hàn Lộ', 'Sương Giáng', 'Lập Đông', 'Tiểu Tuyết', 'Đại Tuyết',
      'Đông Chí', 'Tiểu Hàn', 'Đại Hàn', 'Lập Xuân', 'Vũ Thủy', 'Kinh Trập'
    ];

    final index = (theta / 15.0).floor() % 24;
    return terms[index];
  }

  /// Kiểm tra ngày là Ngày Hoàng Đạo (true) hay Hắc Đạo (false)
  static bool isHoangDaoDay(int jd, int lunarMonth) {
    final monthChi = (lunarMonth + 1) % 12; // Tháng 1 là Dần (2), v.v.
    final dayChi = (jd + 1) % 12;
    final offset = (dayChi - monthChi + 12) % 12;
    // Các vị trí Hoàng Đạo theo Thần Sát (Thanh Long, Minh Đường, Kim Quỹ, Thiên Đức, Ngọc Đường, Tư Mệnh)
    return [0, 1, 4, 6, 8, 10].contains(offset);
  }
}
