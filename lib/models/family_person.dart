/// Một người trong gia phả. Các liên kết dùng ID để việc đổi tên không làm đứt quan hệ.
class FamilyPerson {
  final String id;
  final String name;
  final String gender; // male, female, other
  final String branch; // noi, ngoai, khac
  final String birthDate; // Năm YYYY hoặc ngày DD/MM/YYYY
  final String deathDate;
  final String birthCalendar; // solar, lunar
  final String deathCalendar;
  final String fatherId;
  final String motherId;
  final List<String> spouseIds;
  final String hometown;
  final String restingPlace;
  final String notes;
  final int birthOrder; // Thứ tự con trong gia đình (1 = Con 1, 2 = Con 2...)
  final String? avatarBase64; // Ảnh chân dung đại diện (Base64)

  const FamilyPerson({
    required this.id,
    required this.name,
    this.gender = 'other',
    this.branch = 'noi',
    this.birthDate = '',
    this.deathDate = '',
    this.birthCalendar = 'solar',
    this.deathCalendar = 'solar',
    this.fatherId = '',
    this.motherId = '',
    this.spouseIds = const [],
    this.hometown = '',
    this.restingPlace = '',
    this.notes = '',
    this.birthOrder = 0,
    this.avatarBase64,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'gender': gender,
    'branch': branch,
    'birthDate': birthDate,
    'deathDate': deathDate,
    'birthCalendar': birthCalendar,
    'deathCalendar': deathCalendar,
    'fatherId': fatherId,
    'motherId': motherId,
    'spouseIds': spouseIds,
    'hometown': hometown,
    'restingPlace': restingPlace,
    'notes': notes,
    'birthOrder': birthOrder,
    'avatarBase64': avatarBase64,
  };

  factory FamilyPerson.fromMap(Map<String, dynamic> map) => FamilyPerson(
    id: (map['id'] ?? '').toString(),
    name: (map['name'] ?? '').toString(),
    gender: (map['gender'] ?? 'other').toString(),
    branch: (map['branch'] ?? 'noi').toString(),
    birthDate: (map['birthDate'] ?? '').toString(),
    deathDate: (map['deathDate'] ?? '').toString(),
    birthCalendar: (map['birthCalendar'] ?? 'solar').toString(),
    deathCalendar: (map['deathCalendar'] ?? 'solar').toString(),
    fatherId: (map['fatherId'] ?? '').toString(),
    motherId: (map['motherId'] ?? '').toString(),
    spouseIds: (map['spouseIds'] as List<dynamic>? ?? [])
        .map((id) => id.toString()).toList(),
    hometown: (map['hometown'] ?? '').toString(),
    restingPlace: (map['restingPlace'] ?? '').toString(),
    notes: (map['notes'] ?? '').toString(),
    birthOrder: (map['birthOrder'] as num?)?.toInt() ?? 0,
    avatarBase64: map['avatarBase64']?.toString(),
  );

  FamilyPerson copyWith({
    String? name,
    String? gender,
    String? branch,
    String? birthDate,
    String? deathDate,
    String? birthCalendar,
    String? deathCalendar,
    String? fatherId,
    String? motherId,
    List<String>? spouseIds,
    String? hometown,
    String? restingPlace,
    String? notes,
    int? birthOrder,
    String? avatarBase64,
    bool clearAvatar = false,
  }) => FamilyPerson(
    id: id,
    name: name ?? this.name,
    gender: gender ?? this.gender,
    branch: branch ?? this.branch,
    birthDate: birthDate ?? this.birthDate,
    deathDate: deathDate ?? this.deathDate,
    birthCalendar: birthCalendar ?? this.birthCalendar,
    deathCalendar: deathCalendar ?? this.deathCalendar,
    fatherId: fatherId ?? this.fatherId,
    motherId: motherId ?? this.motherId,
    spouseIds: spouseIds ?? this.spouseIds,
    hometown: hometown ?? this.hometown,
    restingPlace: restingPlace ?? this.restingPlace,
    notes: notes ?? this.notes,
    birthOrder: birthOrder ?? this.birthOrder,
    avatarBase64: clearAvatar ? null : (avatarBase64 ?? this.avatarBase64),
  );
}

/// Chặn việc chọn con/cháu làm cha mẹ, kể cả khi dữ liệu đã có nhiều đời.
bool createsFamilyCycle(String personId, String parentId, List<FamilyPerson> people) {
  if (parentId.isEmpty) return false;
  final children = <String, List<String>>{};
  for (final person in people) {
    for (final id in [person.fatherId, person.motherId]) {
      if (id.isNotEmpty) children.putIfAbsent(id, () => []).add(person.id);
    }
  }
  final seen = <String>{};
  final pending = [personId];
  while (pending.isNotEmpty) {
    final current = pending.removeLast();
    if (current == parentId) return true;
    if (seen.add(current)) pending.addAll(children[current] ?? []);
  }
  return false;
}
