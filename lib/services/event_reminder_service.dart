import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event_model.dart';
import '../services/event_calculator.dart';

class ReminderSettings {
  final bool enabled;
  final int advanceDays; // 1, 3, 7
  final bool remindTienThuong;
  final bool remindChinhKy;
  final String remindTime; // '07:00'

  const ReminderSettings({
    this.enabled = true,
    this.advanceDays = 3,
    this.remindTienThuong = true,
    this.remindChinhKy = true,
    this.remindTime = '07:00',
  });

  Map<String, dynamic> toMap() => {
    'enabled': enabled,
    'advanceDays': advanceDays,
    'remindTienThuong': remindTienThuong,
    'remindChinhKy': remindChinhKy,
    'remindTime': remindTime,
  };

  factory ReminderSettings.fromMap(Map<String, dynamic> map) => ReminderSettings(
    enabled: map['enabled'] as bool? ?? true,
    advanceDays: (map['advanceDays'] as num?)?.toInt() ?? 3,
    remindTienThuong: map['remindTienThuong'] as bool? ?? true,
    remindChinhKy: map['remindChinhKy'] as bool? ?? true,
    remindTime: map['remindTime']?.toString() ?? '07:00',
  );

  ReminderSettings copyWith({
    bool? enabled,
    int? advanceDays,
    bool? remindTienThuong,
    bool? remindChinhKy,
    String? remindTime,
  }) => ReminderSettings(
    enabled: enabled ?? this.enabled,
    advanceDays: advanceDays ?? this.advanceDays,
    remindTienThuong: remindTienThuong ?? this.remindTienThuong,
    remindChinhKy: remindChinhKy ?? this.remindChinhKy,
    remindTime: remindTime ?? this.remindTime,
  );
}

class ReminderAlert {
  final String id;
  final String title;
  final String message;
  final DateTime targetDate;
  final String alertType; // 'today', 'tomorrow', 'advance', 'tien_thuong'
  final EventItem event;

  const ReminderAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.targetDate,
    required this.alertType,
    required this.event,
  });
}

class EventReminderService {
  static const _prefKey = 'reminder_settings_v1';
  static final EventReminderService _instance = EventReminderService._internal();
  factory EventReminderService() => _instance;
  EventReminderService._internal();

  ReminderSettings _settings = const ReminderSettings();
  ReminderSettings get settings => _settings;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefKey);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        _settings = ReminderSettings.fromMap(map);
      } catch (_) {}
    }
  }

  Future<void> saveSettings(ReminderSettings next) async {
    _settings = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, jsonEncode(next.toMap()));
  }

  /// Quét toàn bộ sự kiện và tạo danh sách thông báo nhắc nhở sắp tới
  List<ReminderAlert> getUpcomingAlerts(List<EventItem> events) {
    if (!_settings.enabled) return [];

    final alerts = <ReminderAlert>[];
    final occurrences = EventCalculator.getSortedOccurrences(events);

    for (final occ in occurrences) {
      final ev = occ.event;
      final days = occ.daysRemaining;

      // 1. Nhắc đúng ngày (Hôm nay)
      if (days == 0 && _settings.remindChinhKy) {
        if (ev.type == EventType.birthday) {
          alerts.add(ReminderAlert(
            id: '${ev.id}_today',
            title: '🎂 Hôm nay là Sinh nhật: ${ev.title}',
            message: 'Chúc mừng sinh nhật ${ev.personName ?? ev.title}! Đừng quên gửi lời chúc mừng gia đình.',
            targetDate: occ.nextSolarDate,
            alertType: 'today',
            event: ev,
          ));
        } else {
          alerts.add(ReminderAlert(
            id: '${ev.id}_today',
            title: '🕯️ Hôm nay: Lễ Chính Kỵ ${ev.title}',
            message: 'Đúng ngày giỗ (Ngày ${occ.adjustedDay}/${ev.month} Âm). Gia đình dâng mâm cỗ dâng hương tưởng niệm.',
            targetDate: occ.nextSolarDate,
            alertType: 'today',
            event: ev,
          ));
        }
      }

      // 2. Nhắc ngày mai / Chiều Lễ Tiên Thường
      if (days == 1) {
        if (ev.type == EventType.deathAnniversary && _settings.remindTienThuong) {
          alerts.add(ReminderAlert(
            id: '${ev.id}_tien_thuong',
            title: '🌸 Chiều nay: Lễ Tiên Thường ${ev.title}',
            message: 'Chiều trước ngày giỗ chính. Gia đình sắm lễ thắp hương mời tiên tổ về dự giỗ.',
            targetDate: occ.tienThuongSolarDate ?? occ.nextSolarDate.subtract(const Duration(days: 1)),
            alertType: 'tien_thuong',
            event: ev,
          ));
        } else {
          alerts.add(ReminderAlert(
            id: '${ev.id}_tomorrow',
            title: '🔔 Ngày mai diễn ra: ${ev.title}',
            message: 'Sự kiện sẽ diễn ra vào ngày mai. Hãy kiểm tra các khâu chuẩn bị.',
            targetDate: occ.nextSolarDate,
            alertType: 'tomorrow',
            event: ev,
          ));
        }
      }

      // 3. Nhắc trước X ngày (mặc định 3 ngày hoặc theo cài đặt)
      if (days > 1 && days <= _settings.advanceDays) {
        alerts.add(ReminderAlert(
          id: '${ev.id}_advance_$days',
          title: '⏳ Còn $days ngày nữa: ${ev.title}',
          message: 'Sự kiện vào ngày ${occ.adjustedDay}/${ev.month} Âm (${occ.nextSolarDate.day}/${occ.nextSolarDate.month} Dương). Hãy chuẩn bị sắm lễ và cỗ bàn.',
          targetDate: occ.nextSolarDate,
          alertType: 'advance',
          event: ev,
        ));
      }
    }

    return alerts;
  }
}
