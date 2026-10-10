/// Service lưu trữ cục bộ Cross-Platform (Events, Daily Notes, Profile)
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/event_model.dart';
import '../models/note_model.dart';
import '../models/family_person.dart';

class UserProfile {
  String giaChu;
  String diaChi;
  double prayerFontSize; // Cỡ chữ khi đọc văn khấn
  bool isDarkMode;
  bool isPremium;
  DateTime? premiumExpireDate;
  String premiumTier; // 'free', 'trial', 'monthly', 'yearly', 'lifetime'

  UserProfile({
    this.giaChu = '',
    this.diaChi = '',
    this.prayerFontSize = 18.0,
    this.isDarkMode = false,
    this.isPremium = false,
    this.premiumExpireDate,
    this.premiumTier = 'free',
  });

  bool get isEffectivelyPremium {
    if (!isPremium) return false;
    if (premiumTier == 'lifetime') return true;
    if (premiumExpireDate == null) return true;
    return premiumExpireDate!.isAfter(DateTime.now());
  }

  Map<String, dynamic> toMap() => {
    'giaChu': giaChu,
    'diaChi': diaChi,
    'prayerFontSize': prayerFontSize,
    'isDarkMode': isDarkMode,
    'isPremium': isPremium,
    'premiumExpireDate': premiumExpireDate?.toIso8601String(),
    'premiumTier': premiumTier,
  };

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    final gc = (map['giaChu'] ?? '').toString().trim();
    DateTime? expire;
    if (map['premiumExpireDate'] != null) {
      expire = DateTime.tryParse(map['premiumExpireDate'].toString());
    }
    return UserProfile(
      giaChu: gc,
      diaChi: (map['diaChi'] ?? '').toString(),
      prayerFontSize: (map['prayerFontSize'] as num?)?.toDouble() ?? 18.0,
      isDarkMode: map['isDarkMode'] ?? false,
      isPremium: map['isPremium'] == true,
      premiumExpireDate: expire,
      premiumTier: (map['premiumTier'] ?? 'free').toString(),
    );
  }
}

class StorageService {
  static const String _keyEvents = 'app_events_json';
  static const String _keyNotes = 'app_daily_notes_json';
  static const String _keyProfile = 'app_profile_json';
  static const String _keyFamily = 'app_family_people_json';
  static const String _keyFocusPersonId = 'app_family_focus_id';
  static const String _keyFamilySyncCode = 'app_family_sync_code';
  static const String _keyLastSyncTime = 'app_last_sync_time';
  static const String _keySyncRevisions = 'app_family_sync_revisions';
  Future<String?> loadFamilySyncCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFamilySyncCode);
  }

  Future<void> saveFamilySyncCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFamilySyncCode, code);
  }

  Future<DateTime?> loadLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyLastSyncTime);
    if (str == null) return null;
    return DateTime.tryParse(str);
  }

  Future<void> saveLastSyncTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastSyncTime, time.toIso8601String());
  }

  Future<int?> loadSyncRevision(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keySyncRevisions);
    if (raw == null) return null;
    try {
      final revisions = jsonDecode(raw) as Map<String, dynamic>;
      return revisions[code] is int ? revisions[code] as int : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSyncRevision(String code, int revision) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keySyncRevisions);
    Map<String, dynamic> revisions = {};
    if (raw != null) {
      try {
        revisions = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {}
    }
    revisions[code] = revision;
    await prefs.setString(_keySyncRevisions, jsonEncode(revisions));
  }

  Future<String?> loadFocusPersonId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFocusPersonId);
  }

  Future<void> saveFocusPersonId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFocusPersonId, id);
  }

  Future<List<FamilyPerson>> loadFamilyPeople() async {
    final prefs = await SharedPreferences.getInstance();
    final content = prefs.getString(_keyFamily);
    if (content == null || content.trim().isEmpty) {
      return [];
    }
    try {
      final list = jsonDecode(content) as List<dynamic>;
      if (list.isEmpty) {
        return [];
      }
      return list
          .map((item) => FamilyPerson.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveFamilyPeople(List<FamilyPerson> people) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyFamily,
      jsonEncode(people.map((p) => p.toMap()).toList()),
    );
  }

  /// Tải danh sách sự kiện từ SharedPreferences
  Future<List<EventItem>> loadEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final content = prefs.getString(_keyEvents);

      if (content == null || content.trim().isEmpty) {
        return [];
      }

      final List<dynamic> list = jsonDecode(content);
      if (list.isEmpty) {
        return [];
      }
      return list
          .map((item) => EventItem.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Lưu danh sách sự kiện
  Future<void> saveEvents(List<EventItem> events) async {
    final prefs = await SharedPreferences.getInstance();
    final list = events.map((e) => e.toMap()).toList();
    await prefs.setString(_keyEvents, jsonEncode(list));
  }

  /// Tải danh sách ghi chú theo ngày
  Future<List<DailyNoteItem>> loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final content = prefs.getString(_keyNotes);

      if (content == null || content.trim().isEmpty) {
        return [];
      }

      final List<dynamic> list = jsonDecode(content);
      return list
          .map((item) => DailyNoteItem.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Lưu danh sách ghi chú
  Future<void> saveNotes(List<DailyNoteItem> notes) async {
    final prefs = await SharedPreferences.getInstance();
    final list = notes.map((n) => n.toMap()).toList();
    await prefs.setString(_keyNotes, jsonEncode(list));
  }

  /// Tải thông tin người dùng / gia chủ
  Future<UserProfile> loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final content = prefs.getString(_keyProfile);
      if (content == null) {
        return UserProfile();
      }
      return UserProfile.fromMap(jsonDecode(content));
    } catch (e) {
      return UserProfile();
    }
  }

  /// Lưu thông tin người dùng
  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfile, jsonEncode(profile.toMap()));
  }

  /// Xuất dữ liệu ra chuỗi JSON để sao lưu (Backup)
  Future<String> exportBackupData(
    List<EventItem> events,
    List<DailyNoteItem> notes,
    UserProfile profile,
    List<FamilyPerson> familyPeople,
  ) async {
    final backup = {
      'app': 'SoGioVaKyNiem',
      'version': '1.4.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'profile': profile.toMap(),
      'events': events.map((e) => e.toMap()).toList(),
      'notes': notes.map((n) => n.toMap()).toList(),
      'familyPeople': familyPeople.map((p) => p.toMap()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(backup);
  }

  /// Phục hồi dữ liệu từ chuỗi JSON (Restore)
  Map<String, dynamic> parseBackupData(String jsonString) {
    if (jsonString.length > 10 * 1024 * 1024) {
      throw const FormatException('Tệp sao lưu vượt quá 10 MB.');
    }
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    if (map['events'] is! List || map['notes'] is! List ||
        (map.containsKey('familyPeople') && map['familyPeople'] is! List)) {
      throw const FormatException('Bản sao lưu thiếu danh sách sự kiện hoặc ghi chú.');
    }
    final List<dynamic> eventsList = map['events'] as List<dynamic>;
    final List<dynamic> notesList = map['notes'] as List<dynamic>;
    final List<dynamic> familyList = (map['familyPeople'] as List<dynamic>?) ?? [];

    UserProfile? profile;
    if (map['profile'] != null && map['profile'] is Map<String, dynamic>) {
      try {
        profile = UserProfile.fromMap(map['profile'] as Map<String, dynamic>);
      } catch (_) {}
    }

    return {
      'events': eventsList
          .map((item) => EventItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      'notes': notesList
          .map((item) => DailyNoteItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      'familyPeople': familyList
          .map((item) => FamilyPerson.fromMap(item as Map<String, dynamic>))
          .toList(),
      'hasFamilyPeople': map.containsKey('familyPeople'),
      'profile': profile,
    };
  }

  /// Dữ liệu sự kiện mẫu khởi đầu
  static List<EventItem> getInitialSampleEvents() {
    final now = DateTime.now();
    return [
      EventItem(
        id: 'sample_1',
        title: 'Giỗ Cụ Ông (Nội)',
        type: EventType.deathAnniversary,
        calendar: CalendarType.lunar,
        day: 15,
        month: 8,
        year: 2012,
        personName: 'Cụ Ông Mẫu',
        relation: 'Cụ Ông (Nội)',
        restingPlace: 'Nơi an nghỉ mẫu',
        ageAtDeath: 86,
        remindTienThuong: true,
        remindChinhKy: true,
        advanceDays: 3,
        notes: 'Cụ thích ăn xôi gấc và canh măng miến. Báo các cô chú ở xa trước 3 ngày.',
        dishes: [
          'Gà trống thiến luộc ngậm hoa hồng',
          'Xôi gấc đỏ truyền thống',
          'Canh măng sườn mộc nhĩ',
          'Nem rán truyền thống',
          'Giò lụa',
          'Miến xào lòng mề',
          'Chè sen tráng miệng',
        ],
        contributions: [
          ContributionItem(
            id: 'c1',
            memberName: 'Gia đình Bác Cả',
            amount: 2000000,
            note: 'Mua lễ vật và vàng mã',
          ),
          ContributionItem(
            id: 'c2',
            memberName: 'Gia đình Chú Hai',
            amount: 1500000,
            note: 'Đóng góp làm cỗ',
          ),
        ],
        createdAt: now,
        updatedAt: now,
      ),
      EventItem(
        id: 'sample_2',
        title: 'Giỗ Cụ Bà (Ngoại)',
        type: EventType.deathAnniversary,
        calendar: CalendarType.lunar,
        day: 30,
        month: 12,
        year: 2018,
        personName: 'Cụ Bà Mẫu',
        relation: 'Cụ Bà (Ngoại)',
        restingPlace: 'Nơi an nghỉ mẫu',
        ageAtDeath: 82,
        remindTienThuong: true,
        remindChinhKy: true,
        advanceDays: 5,
        notes:
            'Nếu tháng Chạp chỉ có 29 ngày thì cúng vào ngày 29 (Tháng thiếu).',
        dishes: [
          'Gà luộc',
          'Bánh chưng Tết',
          'Canh bóng thập cẩm',
          'Thịt đông',
          'Dưa hành muối',
        ],
        contributions: [],
        createdAt: now,
        updatedAt: now,
      ),
      EventItem(
        id: 'sample_3',
        title: 'Sinh Nhật Bố',
        type: EventType.birthday,
        calendar: CalendarType.solar,
        day: 20,
        month: 11,
        year: 1965,
        personName: 'Cha Mẫu',
        relation: 'Bố',
        remindTienThuong: false,
        remindChinhKy: true,
        advanceDays: 2,
        notes: 'Cả nhà quây quần ăn bữa cơm tối chúc mừng sinh nhật Bố.',
        dishes: [],
        contributions: [],
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  /// Dữ liệu ghi chú mẫu khởi đầu
  static List<DailyNoteItem> getInitialSampleNotes() {
    final now = DateTime.now();
    return [
      DailyNoteItem(
        id: 'note_1',
        title: 'Mua hoa quả và trầu cau chuẩn bị ngày Rằm',
        content: 'Ra chợ sớm chọn hoa cúc vàng tươi, cau tươi tròn quả, trầu không rách lá.',
        date: DateTime(now.year, now.month, now.day),
        lunarDay: 25,
        lunarMonth: 8,
        lunarYear: 2026,
        category: NoteCategory.offering,
        isCompleted: false,
        time: '08:00',
        createdAt: now,
      ),
      DailyNoteItem(
        id: 'note_2',
        title: 'Gọi điện cho bác Cả nhắc lịch giỗ Cụ sắp tới',
        content: 'Thống nhất thực đơn mâm cỗ và giờ làm lễ Tiên thường chiều hôm trước.',
        date: DateTime(now.year, now.month, now.day),
        lunarDay: 25,
        lunarMonth: 8,
        lunarYear: 2026,
        category: NoteCategory.family,
        isCompleted: true,
        time: '19:30',
        createdAt: now,
      ),
    ];
  }

  /// Dữ liệu gia phả mẫu chuẩn xác cho gia đình
  static List<FamilyPerson> getInitialSampleFamilyPeople() {
    return [
      // 1. Ông bà nội (Đời 1)
      const FamilyPerson(
        id: 'fp_ong_noi',
        name: 'Ông Nội Mẫu',
        gender: 'male',
        branch: 'noi',
        birthDate: '',
        spouseIds: ['fp_ba_noi'],
        notes: 'Ông nội',
      ),
      const FamilyPerson(
        id: 'fp_ba_noi',
        name: 'Bà Nội Mẫu',
        gender: 'female',
        branch: 'noi',
        birthDate: '',
        spouseIds: ['fp_ong_noi'],
        notes: 'Bà nội',
      ),

      // 2. Ông ngoại (Đời 1)
      const FamilyPerson(
        id: 'fp_ong_ngoai',
        name: 'Ông Ngoại Mẫu',
        gender: 'male',
        branch: 'ngoai',
        birthDate: '',
        notes: 'Ông ngoại',
      ),

      // 3. Thế hệ bố mẹ & các cô chú bác (Đời 2)
      const FamilyPerson(
        id: 'fp_bo',
        name: 'Cha Mẫu',
        gender: 'male',
        branch: 'noi',
        birthDate: '1960',
        birthOrder: 1,
        fatherId: 'fp_ong_noi',
        motherId: 'fp_ba_noi',
        spouseIds: ['fp_me'],
        notes: 'Bố',
      ),
      const FamilyPerson(
        id: 'fp_me',
        name: 'Mẹ Mẫu',
        gender: 'female',
        branch: 'ngoai',
        birthDate: '',
        fatherId: 'fp_ong_ngoai',
        spouseIds: ['fp_bo'],
        notes: 'Mẹ',
      ),
      const FamilyPerson(
        id: 'fp_uncle_one',
        name: 'Chú Mẫu 1',
        gender: 'male',
        branch: 'noi',
        birthDate: '1970',
        birthOrder: 2,
        fatherId: 'fp_ong_noi',
        motherId: 'fp_ba_noi',
        notes: 'Chú ruột',
      ),
      const FamilyPerson(
        id: 'fp_chu_cuong',
        name: 'Chú Mẫu 2',
        gender: 'male',
        branch: 'noi',
        birthDate: '',
        birthOrder: 3,
        fatherId: 'fp_ong_noi',
        motherId: 'fp_ba_noi',
        notes: 'Chú ruột',
      ),
      const FamilyPerson(
        id: 'fp_co_huong',
        name: 'Cô Mẫu',
        gender: 'female',
        branch: 'noi',
        birthDate: '',
        birthOrder: 4,
        fatherId: 'fp_ong_noi',
        motherId: 'fp_ba_noi',
        notes: 'Cô ruột',
      ),

      // 4. Tôi & Vợ (Đời 3)
      const FamilyPerson(
        id: 'fp_focus',
        name: 'Người Mẫu',
        gender: 'male',
        branch: 'noi',
        birthDate: '',
        birthOrder: 1,
        fatherId: 'fp_bo',
        motherId: 'fp_me',
        spouseIds: ['fp_spouse'],
        notes: 'Bản thân (Chủ gia phả)',
      ),
      const FamilyPerson(
        id: 'fp_sibling',
        name: 'Em Trai Mẫu',
        gender: 'male',
        branch: 'noi',
        birthDate: '',
        birthOrder: 2,
        fatherId: 'fp_bo',
        motherId: 'fp_me',
        notes: 'Em trai',
      ),

      // 5. Bên Vợ (Họ Nguyễn)
      const FamilyPerson(
        id: 'fp_bo_vo',
        name: 'Bố Vợ Mẫu',
        gender: 'male',
        branch: 'vo',
        birthDate: '',
        spouseIds: ['fp_me_vo'],
        notes: 'Bố vợ (Nhạc phụ)',
      ),
      const FamilyPerson(
        id: 'fp_me_vo',
        name: 'Mẹ Vợ Mẫu',
        gender: 'female',
        branch: 'vo',
        birthDate: '',
        spouseIds: ['fp_bo_vo'],
        notes: 'Mẹ vợ (Nhạc mẫu)',
      ),
      const FamilyPerson(
        id: 'fp_chi_vo_trang',
        name: 'Chị Vợ Mẫu Một',
        gender: 'female',
        branch: 'vo',
        birthDate: '',
        birthOrder: 1,
        fatherId: 'fp_bo_vo',
        motherId: 'fp_me_vo',
        notes: 'Chị vợ',
      ),
      const FamilyPerson(
        id: 'fp_chi_vo_dung',
        name: 'Chị Vợ Mẫu Hai',
        gender: 'female',
        branch: 'vo',
        birthDate: '',
        birthOrder: 2,
        fatherId: 'fp_bo_vo',
        motherId: 'fp_me_vo',
        notes: 'Chị vợ',
      ),
      const FamilyPerson(
        id: 'fp_spouse',
        name: 'Vợ Mẫu',
        gender: 'female',
        branch: 'vo',
        birthDate: '',
        birthOrder: 3,
        fatherId: 'fp_bo_vo',
        motherId: 'fp_me_vo',
        spouseIds: ['fp_focus'],
        notes: 'Vợ',
      ),
      const FamilyPerson(
        id: 'fp_em_vo_quyen',
        name: 'Em Vợ Mẫu',
        gender: 'female',
        branch: 'vo',
        birthDate: '',
        birthOrder: 4,
        fatherId: 'fp_bo_vo',
        motherId: 'fp_me_vo',
        notes: 'Em gái vợ',
      ),

      // 6. Con trai (Đời 4)
      const FamilyPerson(
        id: 'fp_child',
        name: 'Con Mẫu',
        gender: 'male',
        branch: 'con_chau',
        birthDate: '',
        birthOrder: 1,
        fatherId: 'fp_focus',
        motherId: 'fp_spouse',
        notes: 'Con trai',
      ),
    ];
  }
}
