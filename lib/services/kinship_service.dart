/// Dịch vụ tính toán vai vế, danh xưng xưng hô truyền thống Việt Nam
/// Dựa trên người làm mốc (Ví dụ: "Tôi - Lê Đức Anh")
import '../models/family_person.dart';

class KinshipService {
  /// Tìm người làm mốc (Ưu tiên tên gia chủ hoặc Lê Đức Anh, không để nhảy nhầm sang bố/ông)
  static FamilyPerson? findDefaultFocusPerson(List<FamilyPerson> people, String giaChuName) {
    if (people.isEmpty) return null;
    final target = giaChuName.trim().isNotEmpty ? giaChuName.trim().toLowerCase() : 'lê đức anh';
    final match = people.where((p) => p.name.trim().toLowerCase() == target);
    if (match.isNotEmpty) return match.first;

    // Luôn ưu tiên tìm "Lê Đức Anh" nếu target không khớp
    final ducAnh = people.where((p) => p.name.trim().toLowerCase() == 'lê đức anh');
    if (ducAnh.isNotEmpty) return ducAnh.first;

    // Tìm người có cả bố mẹ và có con (thế hệ giữa)
    final middleGen = people.where((p) => 
      (p.fatherId.isNotEmpty || p.motherId.isNotEmpty) &&
      people.any((c) => c.fatherId == p.id || c.motherId == p.id)
    );
    if (middleGen.isNotEmpty) return middleGen.first;
    return people.first;
  }

  /// Tính toàn bộ thế hệ tương đối của tất cả thành viên trong gia tộc so với người làm mốc (focus)
  /// Sử dụng thuật toán lan truyền đồ thị (BFS) chuẩn mực:
  /// - Vợ / Chồng -> cùng thế hệ (delta = 0)
  /// - Cha / Mẹ -> thế hệ trên (delta = -1)
  /// - Con cái -> thế hệ dưới (delta = +1)
  /// - Anh chị em -> cùng thế hệ (delta = 0)
  static Map<String, int> computeAllRelativeGenerations(FamilyPerson focus, List<FamilyPerson> people) {
    final genMap = <String, int>{focus.id: 0};
    final byId = {for (final p in people) p.id: p};
    final queue = <String>[focus.id];

    void link(String targetId, int gen) {
      if (targetId.isNotEmpty && byId.containsKey(targetId) && !genMap.containsKey(targetId)) {
        genMap[targetId] = gen;
        queue.add(targetId);
      }
    }

    while (queue.isNotEmpty) {
      final currId = queue.removeAt(0);
      final currGen = genMap[currId]!;
      final curr = byId[currId];
      if (curr == null) continue;

      // 1. Vợ / Chồng: cùng thế hệ (Level 0 so với nhau)
      for (final sId in curr.spouseIds) {
        link(sId, currGen);
      }
      for (final p in people) {
        if (p.spouseIds.contains(currId)) {
          link(p.id, currGen);
        }
      }

      // 2. Cha & Mẹ: lùi 1 thế hệ (-1)
      link(curr.fatherId, currGen - 1);
      link(curr.motherId, currGen - 1);

      // 3. Con cái: tiến 1 thế hệ (+1)
      for (final p in people) {
        if (p.fatherId == currId || p.motherId == currId) {
          link(p.id, currGen + 1);
        }
      }

      // 4. Anh chị em ruột: cùng thế hệ
      if (curr.fatherId.isNotEmpty || curr.motherId.isNotEmpty) {
        for (final p in people) {
          if (p.id != currId &&
              ((curr.fatherId.isNotEmpty && p.fatherId == curr.fatherId) ||
               (curr.motherId.isNotEmpty && p.motherId == curr.motherId))) {
            link(p.id, currGen);
          }
        }
      }
    }

    return genMap;
  }

  /// Tính thế hệ tương đối so với người làm mốc (focus)
  /// Level 0 = Đời mình (Bản thân, Vợ, Anh chị em ruột, Anh chị em họ, Anh chị em vợ...)
  /// Level -1 = Đời bố mẹ (Bố, Mẹ, Cô, Chú, Bác, Bố mẹ vợ, Cậu, Dì...)
  /// Level -2 = Đời ông bà (Ông Bà nội, Ông Bà ngoại, Ông Bà bên vợ...)
  /// Level -3 = Đời cụ
  /// Level +1 = Đời con
  /// Level +2 = Đời cháu
  static int getRelativeGeneration(FamilyPerson target, FamilyPerson focus, List<FamilyPerson> people) {
    if (target.id == focus.id) return 0;
    final allGens = computeAllRelativeGenerations(focus, people);
    if (allGens.containsKey(target.id)) {
      return allGens[target.id]!;
    }
    return 0;
  }

  /// Tính danh xưng xưng hô chi tiết chuẩn thuần phong mỹ tục Việt Nam
  static String getKinshipTitle(FamilyPerson target, FamilyPerson focus, List<FamilyPerson> people) {
    if (target.id == focus.id) return 'Tôi (Bản thân)';

    // Vợ / Chồng
    if (focus.spouseIds.contains(target.id) || target.spouseIds.contains(focus.id)) {
      if (target.gender == 'female') return 'Vợ';
      if (target.gender == 'male') return 'Chồng';
      return 'Bạn đời';
    }

    final byId = {for (final p in people) p.id: p};

    // Cha & Mẹ trực tiếp
    if (focus.fatherId == target.id) return 'Bố (Cha)';
    if (focus.motherId == target.id) return 'Mẹ';

    final focusFather = byId[focus.fatherId];
    final focusMother = byId[focus.motherId];

    // Ông Bà Nội (Cha mẹ của Bố)
    if (focusFather != null) {
      if (focusFather.fatherId == target.id) return 'Ông nội';
      if (focusFather.motherId == target.id) return 'Bà nội';

      // Cụ Nội
      final grandfather = byId[focusFather.fatherId];
      final grandmother = byId[focusFather.motherId];
      if (grandfather != null) {
        if (grandfather.fatherId == target.id) return 'Cụ cố nội (Cụ Ông)';
        if (grandfather.motherId == target.id) return 'Cụ cố nội (Cụ Bà)';
      }
      if (grandmother != null) {
        if (grandmother.fatherId == target.id) return 'Cụ cố nội';
        if (grandmother.motherId == target.id) return 'Cụ cố nội';
      }

      // Bác, Chú, Cô bên nội (Anh chị em của Bố)
      if (focusFather.fatherId.isNotEmpty &&
          (target.fatherId == focusFather.fatherId || target.motherId == focusFather.motherId)) {
        if (target.gender == 'female') return 'Cô (Bên nội)';
        // So sánh năm sinh nếu có
        final fatherYear = _getBirthYear(focusFather);
        final targetYear = _getBirthYear(target);
        if (targetYear != null && fatherYear != null && targetYear < fatherYear) {
          return 'Bác (Bên nội)';
        }
        return targetYear != null && fatherYear != null && targetYear > fatherYear
            ? 'Chú (Bên nội)'
            : 'Bác / Chú (Nội)';
      }
    }

    // Ông Bà Ngoại (Cha mẹ của Mẹ)
    if (focusMother != null) {
      if (focusMother.fatherId == target.id) return 'Ông ngoại';
      if (focusMother.motherId == target.id) return 'Bà ngoại';

      // Cụ Ngoại
      final maternalGrandfather = byId[focusMother.fatherId];
      final maternalGrandmother = byId[focusMother.motherId];
      if (maternalGrandfather != null) {
        if (maternalGrandfather.fatherId == target.id) return 'Cụ ngoại (Cụ Ông)';
        if (maternalGrandfather.motherId == target.id) return 'Cụ ngoại (Cụ Bà)';
      }
      if (maternalGrandmother != null) {
        if (maternalGrandmother.fatherId == target.id) return 'Cụ ngoại';
        if (maternalGrandmother.motherId == target.id) return 'Cụ ngoại';
      }

      // Cậu, Dì bên ngoại (Anh chị em của Mẹ)
      if (focusMother.fatherId.isNotEmpty &&
          (target.fatherId == focusMother.fatherId || target.motherId == focusMother.motherId)) {
        if (target.gender == 'female') return 'Dì (Bên ngoại)';
        return 'Cậu / Bác (Ngoại)';
      }
    }

    // Anh chị em ruột
    if ((focus.fatherId.isNotEmpty && focus.fatherId == target.fatherId) ||
        (focus.motherId.isNotEmpty && focus.motherId == target.motherId)) {
      final focusYear = _getBirthYear(focus);
      final targetYear = _getBirthYear(target);
      if (target.gender == 'female') {
        return (targetYear != null && focusYear != null && targetYear < focusYear) ? 'Chị gái' : 'Em gái';
      } else {
        return (targetYear != null && focusYear != null && targetYear < focusYear) ? 'Anh trai' : 'Em trai';
      }
    }

    // Con ruột của focus
    if (target.fatherId == focus.id || target.motherId == focus.id) {
      if (target.gender == 'male') return 'Con trai';
      if (target.gender == 'female') return 'Con gái';
      return 'Con';
    }

    // Con dâu / con rể (vợ/chồng của con)
    final childrenIds = people.where((c) => c.fatherId == focus.id || c.motherId == focus.id).map((c) => c.id).toSet();
    if (target.spouseIds.any(childrenIds.contains)) {
      if (target.gender == 'female') return 'Con dâu';
      if (target.gender == 'male') return 'Con rể';
    }

    // Cháu nội / cháu ngoại (con của con)
    final targetParents = [target.fatherId, target.motherId];
    if (targetParents.any(childrenIds.contains)) {
      final isFromSon = people.any((c) => c.id == target.fatherId && c.fatherId == focus.id);
      return isFromSon ? 'Cháu nội' : 'Cháu ngoại';
    }

    // Bên nhà vợ / chồng (Thông gia)
    for (final spouseId in focus.spouseIds) {
      final spouse = byId[spouseId];
      if (spouse != null) {
        if (spouse.fatherId == target.id) return focus.gender == 'female' ? 'Bố chồng' : 'Bố vợ (Nhạc phụ)';
        if (spouse.motherId == target.id) return focus.gender == 'female' ? 'Mẹ chồng' : 'Mẹ vợ (Nhạc mẫu)';

        // Anh chị em của vợ / chồng
        if ((spouse.fatherId.isNotEmpty && target.fatherId == spouse.fatherId) ||
            (spouse.motherId.isNotEmpty && target.motherId == spouse.motherId)) {
          final sYear = _getBirthYear(spouse);
          final tYear = _getBirthYear(target);
          if (focus.gender == 'female') {
            return target.gender == 'female' ? 'Chị/Em chồng' : 'Anh/Em chồng';
          } else {
            if (target.gender == 'female') {
              return (tYear != null && sYear != null && tYear < sYear) ? 'Chị vợ' : 'Em gái vợ';
            } else {
              return (tYear != null && sYear != null && tYear < sYear) ? 'Anh vợ' : 'Em trai vợ';
            }
          }
        }
      }
    }

    // Fallback theo thế hệ
    final gen = getRelativeGeneration(target, focus, people);
    switch (gen) {
      case -3:
        return 'Thế hệ Cụ';
      case -2:
        return 'Thế hệ Ông Bà';
      case -1:
        return target.gender == 'female' ? 'Cô / Dì / Bác gái' : 'Bác / Chú / Cậu';
      case 0:
        return 'Anh chị em họ';
      case 1:
        return 'Thế hệ Con cháu';
      case 2:
        return 'Thế hệ Cháu chắt';
      default:
        return 'Người thân';
    }
  }

  static int? _getBirthYear(FamilyPerson p) {
    if (p.birthDate.isEmpty) return null;
    final parts = p.birthDate.split('/');
    return int.tryParse(parts.last);
  }
}
