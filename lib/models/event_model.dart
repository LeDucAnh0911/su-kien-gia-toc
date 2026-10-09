/// Model cho Sự Kiện (Ngày Giỗ, Sinh Nhật, Ngày Kỷ Niệm...)
import 'dart:convert';

enum EventType {
  deathAnniversary, // Ngày giỗ
  birthday,         // Sinh nhật
  memorial,         // Ngày kỷ niệm
  custom,           // Khác
}

enum CalendarType {
  lunar, // Âm lịch
  solar, // Dương lịch
}

class ContributionItem {
  final String id;
  final String memberName; // Tên người đóng góp
  final double amount;     // Số tiền (VNĐ)
  final String? note;      // Ghi chú (VD: Tiền mua vàng mã, mua hoa quả...)

  ContributionItem({
    required this.id,
    required this.memberName,
    required this.amount,
    this.note,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'memberName': memberName,
    'amount': amount,
    'note': note,
  };

  factory ContributionItem.fromMap(Map<String, dynamic> map) => ContributionItem(
    id: map['id'] ?? '',
    memberName: map['memberName'] ?? '',
    amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
    note: map['note'],
  );
}

class EventItem {
  final String id;
  final String title;               // Tiêu đề (VD: Giỗ Cụ Ông, Giỗ Bác Cả)
  final EventType type;             // Loại sự kiện
  final CalendarType calendar;      // Âm hay Dương
  
  // Ngày tháng gốc
  final int day;                    // 1 - 31
  final int month;                  // 1 - 12
  final int? year;                  // Năm mất / sinh (null nếu không nhớ)
  final bool isLeapMonth;           // Có phải tháng nhuận hay không
  
  // Thông tin người được tưởng nhớ
  final String? personName;         // Họ và tên (VD: Nguyễn Văn A)
  final String? relation;           // Quan hệ (Cụ nội, Ông ngoại, Bác cả, Cô...)
  final String? restingPlace;       // Vị trí mộ phần / nơi an nghỉ
  final int? ageAtDeath;            // Hưởng thọ / hưởng dương
  
  // Cấu hình thông báo
  final bool remindTienThuong;      // Nhắc chiều hôm trước (Lễ Tiên thường)
  final bool remindChinhKy;         // Nhắc sáng đúng ngày (Lễ Chính kỵ)
  final int advanceDays;            // Nhắc trước X ngày (mặc định 3 ngày)
  
  // Ghi chú, mâm cỗ & thu chi
  final String? notes;              // Ghi chú kiêng kỵ, tục lệ
  final List<String> dishes;        // Danh sách món mâm cỗ / đồ cần sắm
  final List<ContributionItem> contributions; // Đóng góp của con cháu
  
  final DateTime createdAt;
  final DateTime updatedAt;

  EventItem({
    required this.id,
    required this.title,
    required this.type,
    required this.calendar,
    required this.day,
    required this.month,
    this.year,
    this.isLeapMonth = false,
    this.personName,
    this.relation,
    this.restingPlace,
    this.ageAtDeath,
    this.remindTienThuong = true,
    this.remindChinhKy = true,
    this.advanceDays = 3,
    this.notes,
    this.dishes = const [],
    this.contributions = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'type': type.name,
    'calendar': calendar.name,
    'day': day,
    'month': month,
    'year': year,
    'isLeapMonth': isLeapMonth,
    'personName': personName,
    'relation': relation,
    'restingPlace': restingPlace,
    'ageAtDeath': ageAtDeath,
    'remindTienThuong': remindTienThuong,
    'remindChinhKy': remindChinhKy,
    'advanceDays': advanceDays,
    'notes': notes,
    'dishes': dishes,
    'contributions': contributions.map((c) => c.toMap()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory EventItem.fromMap(Map<String, dynamic> map) => EventItem(
    id: map['id'] ?? '',
    title: map['title'] ?? '',
    type: EventType.values.firstWhere(
      (e) => e.name == map['type'],
      orElse: () => EventType.deathAnniversary,
    ),
    calendar: CalendarType.values.firstWhere(
      (e) => e.name == map['calendar'],
      orElse: () => CalendarType.lunar,
    ),
    day: map['day'] ?? 1,
    month: map['month'] ?? 1,
    year: map['year'],
    isLeapMonth: map['isLeapMonth'] ?? false,
    personName: map['personName'],
    relation: map['relation'],
    restingPlace: map['restingPlace'],
    ageAtDeath: map['ageAtDeath'],
    remindTienThuong: map['remindTienThuong'] ?? true,
    remindChinhKy: map['remindChinhKy'] ?? true,
    advanceDays: map['advanceDays'] ?? 3,
    notes: map['notes'],
    dishes: List<String>.from(map['dishes'] ?? []),
    contributions: (map['contributions'] as List<dynamic>? ?? [])
        .map((c) => ContributionItem.fromMap(c as Map<String, dynamic>))
        .toList(),
    createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
  );

  String toJson() => jsonEncode(toMap());
  factory EventItem.fromJson(String source) => EventItem.fromMap(jsonDecode(source));
}
