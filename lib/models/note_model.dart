/// Model cho Ghi Chú & Việc Cần Làm Theo Ngày (Calendar Day Note)
import 'dart:convert';

enum NoteCategory {
  todo,       // Việc cần làm / chuẩn bị
  family,     // Việc gia đình / dòng họ
  offering,   // Chuẩn bị đồ lễ / mâm cỗ
  general,    // Ghi chú chung
}

class DailyNoteItem {
  final String id;
  String title;               // Nội dung / tiêu đề ghi chú
  String? content;            // Chi tiết ghi chú
  DateTime date;              // Ngày Dương lịch (chỉ lấy year, month, day)
  int lunarDay;               // Ngày Âm lịch tương ứng
  int lunarMonth;             // Tháng Âm lịch tương ứng
  int lunarYear;              // Năm Âm lịch tương ứng
  NoteCategory category;      // Phân loại
  bool isCompleted;           // Trạng thái đã hoàn thành hay chưa
  String? time;               // Giờ hẹn (VD: "08:30")
  DateTime createdAt;

  DailyNoteItem({
    required this.id,
    required this.title,
    this.content,
    required this.date,
    required this.lunarDay,
    required this.lunarMonth,
    required this.lunarYear,
    this.category = NoteCategory.todo,
    this.isCompleted = false,
    this.time,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'content': content,
    'date': date.toIso8601String(),
    'lunarDay': lunarDay,
    'lunarMonth': lunarMonth,
    'lunarYear': lunarYear,
    'category': category.name,
    'isCompleted': isCompleted,
    'time': time,
    'createdAt': createdAt.toIso8601String(),
  };

  factory DailyNoteItem.fromMap(Map<String, dynamic> map) => DailyNoteItem(
    id: map['id'] ?? '',
    title: map['title'] ?? '',
    content: map['content'],
    date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
    lunarDay: map['lunarDay'] ?? 1,
    lunarMonth: map['lunarMonth'] ?? 1,
    lunarYear: map['lunarYear'] ?? 2026,
    category: NoteCategory.values.firstWhere(
      (c) => c.name == map['category'],
      orElse: () => NoteCategory.todo,
    ),
    isCompleted: map['isCompleted'] ?? false,
    time: map['time'],
    createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
  );

  String toJson() => jsonEncode(toMap());
  factory DailyNoteItem.fromJson(String source) => DailyNoteItem.fromMap(jsonDecode(source));
}
