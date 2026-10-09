/// Bộ dựng Cây Phả Hệ phân cấp theo cặp vợ chồng và thế hệ
import '../models/family_person.dart';
import 'kinship_service.dart';

class FamilyTreeNode {
  final FamilyPerson person;
  final List<FamilyPerson> spouses;
  final List<FamilyTreeNode> children;
  final int generation;
  final int relativeGeneration; // Thế hệ tương đối so với Bản Thân (0 = Bản thân, -1 = Bố mẹ, -2 = Ông bà, +1 = Con...)
  final String kinshipTitle;
  final List<String> spouseKinshipTitles;
  final String rootBranchTitle;
  final int? childOrder; // Thứ tự con trong gia đình (1 = Con 1, 2 = Con 2...)
  final int totalSiblings; // Tổng số anh chị em trong đàn con này

  FamilyTreeNode({
    required this.person,
    List<FamilyPerson>? spouses,
    FamilyPerson? spouse,
    this.children = const [],
    required this.generation,
    required this.relativeGeneration,
    required this.kinshipTitle,
    List<String>? spouseKinshipTitles,
    String? spouseKinshipTitle,
    this.rootBranchTitle = '',
    this.childOrder,
    this.totalSiblings = 1,
  })  : spouses = spouses ?? (spouse != null ? [spouse] : const []),
        spouseKinshipTitles = spouseKinshipTitles ?? (spouseKinshipTitle != null ? [spouseKinshipTitle] : const []);

  FamilyPerson? get spouse => spouses.isNotEmpty ? spouses.first : null;
  String? get spouseKinshipTitle => spouseKinshipTitles.isNotEmpty ? spouseKinshipTitles.first : null;
}

class FamilyTreeBuilder {
  static String getFamilyLastName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'GIA TỘC';
    final parts = trimmed.split(RegExp(r'\s+'));
    return parts.first.toUpperCase();
  }

  /// Xây dựng cây phả hệ dựa theo chế độ:
  /// - 'noi': Bên nội (Họ cha)
  /// - 'ngoai': Bên ngoại (Họ mẹ)
  /// - 'vo': Bên vợ / Bên chồng
  /// - 'all': Toàn cảnh (Hợp nhất cả 3 bảng ngang hàng)
  static List<FamilyTreeNode> buildTree({
    required List<FamilyPerson> people,
    required FamilyPerson focusPerson,
    required String mode, // 'noi', 'ngoai', 'vo', 'all'
  }) {
    if (people.isEmpty) return [];

    final byId = {for (final p in people) p.id: p};

    // Tìm tổ tiên cao nhất bên nội (Paternal ancestor)
    FamilyPerson findPaternalRoot(FamilyPerson start) {
      var current = start;
      final visited = <String>{current.id};
      while (current.fatherId.isNotEmpty && byId.containsKey(current.fatherId)) {
        final father = byId[current.fatherId]!;
        if (visited.contains(father.id)) break;
        visited.add(father.id);
        current = father;
      }
      return current;
    }

    // Tìm tổ tiên cao nhất bên ngoại (Maternal ancestor)
    FamilyPerson? findMaternalRoot(FamilyPerson start) {
      if (start.motherId.isEmpty || !byId.containsKey(start.motherId)) return null;
      var current = byId[start.motherId]!;
      final visited = <String>{current.id};
      while (current.fatherId.isNotEmpty && byId.containsKey(current.fatherId)) {
        final father = byId[current.fatherId]!;
        if (visited.contains(father.id)) break;
        visited.add(father.id);
        current = father;
      }
      return current;
    }

    // Tìm tổ tiên cao nhất bên vợ / chồng (Spouse ancestor)
    FamilyPerson? findSpouseRoot(FamilyPerson start) {
      String? spouseId;
      if (start.spouseIds.isNotEmpty) {
        spouseId = start.spouseIds.first;
      } else {
        final sp = people.where((p) => p.spouseIds.contains(start.id)).firstOrNull;
        if (sp != null) spouseId = sp.id;
      }
      if (spouseId == null || !byId.containsKey(spouseId)) return null;

      var current = byId[spouseId]!;
      final visited = <String>{current.id};
      while (current.fatherId.isNotEmpty && byId.containsKey(current.fatherId)) {
        final father = byId[current.fatherId]!;
        if (visited.contains(father.id)) break;
        visited.add(father.id);
        current = father;
      }
      if (current.fatherId.isEmpty && current.motherId.isNotEmpty && byId.containsKey(current.motherId)) {
        var mCurrent = byId[current.motherId]!;
        while (mCurrent.fatherId.isNotEmpty && byId.containsKey(mCurrent.fatherId)) {
          final mFather = byId[mCurrent.fatherId]!;
          if (visited.contains(mFather.id)) break;
          visited.add(mFather.id);
          mCurrent = mFather;
        }
        return mCurrent;
      }
      return current;
    }

    // Xác định các gốc (Roots) cần xây dựng cây kèm nhãn dòng tộc
    final rootsToProcess = <(FamilyPerson, String)>[];

    final patRoot = findPaternalRoot(focusPerson);
    final matRoot = findMaternalRoot(focusPerson);
    final spRoot = findSpouseRoot(focusPerson);

    final isFemale = focusPerson.gender == 'female';
    final spouseLabel = isFemale ? 'BÊN CHỒNG' : 'BÊN VỢ';

    if (mode == 'noi') {
      rootsToProcess.add((patRoot, '🌿 BÊN NỘI • HỌ ${getFamilyLastName(patRoot.name)}'));
    } else if (mode == 'ngoai') {
      if (matRoot != null) {
        rootsToProcess.add((matRoot, '🌸 BÊN NGOẠI • HỌ ${getFamilyLastName(matRoot.name)}'));
      } else if (focusPerson.motherId.isNotEmpty && byId.containsKey(focusPerson.motherId)) {
        final m = byId[focusPerson.motherId]!;
        rootsToProcess.add((m, '🌸 BÊN NGOẠI • HỌ ${getFamilyLastName(m.name)}'));
      } else {
        rootsToProcess.add((focusPerson, '🌸 BÊN NGOẠI'));
      }
    } else if (mode == 'vo') {
      if (spRoot != null) {
        rootsToProcess.add((spRoot, '💍 $spouseLabel • HỌ ${getFamilyLastName(spRoot.name)}'));
      }
    } else {
      // Chế độ Toàn Cảnh (Hợp nhất 3 bên)
      final rootSet = <String>{};

      rootSet.add(patRoot.id);
      rootsToProcess.add((patRoot, '🌿 BÊN NỘI • HỌ ${getFamilyLastName(patRoot.name)}'));

      if (matRoot != null && !rootSet.contains(matRoot.id)) {
        rootSet.add(matRoot.id);
        rootsToProcess.add((matRoot, '🌸 BÊN NGOẠI • HỌ ${getFamilyLastName(matRoot.name)}'));
      }

      if (spRoot != null && !rootSet.contains(spRoot.id)) {
        rootSet.add(spRoot.id);
        rootsToProcess.add((spRoot, '💍 $spouseLabel • HỌ ${getFamilyLastName(spRoot.name)}'));
      }

      // Thêm các gốc khác chưa được bao quát
      for (final p in people) {
        if (p.fatherId.isEmpty && p.motherId.isEmpty) {
          final isSpouseOfRoot = rootsToProcess.any((r) =>
            r.$1.spouseIds.contains(p.id) || p.spouseIds.contains(r.$1.id));
          if (!rootSet.contains(p.id) && !isSpouseOfRoot) {
            final hasChildren = people.any((c) => c.fatherId == p.id || c.motherId == p.id);
            if (hasChildren && rootSet.add(p.id)) {
              rootsToProcess.add((p, 'NHÁNH • HỌ ${getFamilyLastName(p.name)}'));
            }
          }
        }
      }
    }

    final allGenerations = KinshipService.computeAllRelativeGenerations(focusPerson, people);
    final treeList = <FamilyTreeNode>[];

    for (final item in rootsToProcess) {
      final root = item.$1;
      final branchTitle = item.$2;
      final branchVisited = <String>{};

      FamilyTreeNode buildSubTree(
        FamilyPerson person, 
        int currentGen, {
        int? childOrder,
        int totalSiblings = 1,
      }) {
        branchVisited.add(person.id);

        // Tìm các vợ/chồng của người này (hỗ trợ nhiều vợ/chồng: Vợ cả, Vợ hai...)
        final spousesList = <FamilyPerson>[];
        final spouseIdSet = <String>{};

        // 1. Duyệt qua person.spouseIds theo đúng thứ tự đã chỉ định (Vợ cả trước, Vợ hai sau)
        for (final sId in person.spouseIds) {
          if (byId.containsKey(sId) && !spouseIdSet.contains(sId)) {
            final sp = byId[sId]!;
            spousesList.add(sp);
            spouseIdSet.add(sId);
            branchVisited.add(sId);
          }
        }

        // 2. Tìm thêm những người khác có liên kết bạn đời với person nhưng chưa có trong spouseIds
        for (final p in people) {
          if (p.spouseIds.contains(person.id) && !spouseIdSet.contains(p.id)) {
            spousesList.add(p);
            spouseIdSet.add(p.id);
            branchVisited.add(p.id);
          }
        }

        // Danh sách con của người này và tất cả các bạn đời
        final childrenList = people.where((c) {
          if (c.id == person.id || spouseIdSet.contains(c.id)) return false;
          if (branchVisited.contains(c.id)) return false;

          if (c.fatherId == person.id || c.motherId == person.id) return true;
          for (final sp in spousesList) {
            if (c.fatherId == sp.id || c.motherId == sp.id) return true;
          }
          return false;
        }).toList();

        // Sắp xếp các con: Con cả sinh trước ở bên trái (Con 1), con sau tiếp bên phải (Con 2, 3...)
        // 1. Thu thập các thứ tự (birthOrder) đã được người dùng chỉ định rõ (> 0)
        final explicitOrders = <int>{};
        for (final c in childrenList) {
          if (c.birthOrder > 0) {
            explicitOrders.add(c.birthOrder);
          }
        }

        // 2. Sắp xếp các con chưa có birthOrder theo năm sinh (tự nhiên)
        final unassigned = childrenList.where((c) => c.birthOrder <= 0).toList();
        unassigned.sort((a, b) {
          final aYear = _parseYear(a.birthDate);
          final bYear = _parseYear(b.birthDate);
          if (aYear != bYear) return aYear.compareTo(bYear);
          return a.name.compareTo(b.name);
        });

        // 3. Phân bổ các slot thứ tự còn trống (1, 2, 3...) cho các con chưa chỉ định
        final effectiveRanks = <String, int>{};
        int nextSlot = 1;
        for (final c in unassigned) {
          while (explicitOrders.contains(nextSlot)) {
            nextSlot++;
          }
          effectiveRanks[c.id] = nextSlot;
          nextSlot++;
        }
        for (final c in childrenList) {
          if (c.birthOrder > 0) {
            effectiveRanks[c.id] = c.birthOrder;
          }
        }

        // 4. Sắp xếp danh sách con theo thứ tự từ trái qua phải (Con 1 bên trái, con sau tiếp bên phải)
        childrenList.sort((a, b) {
          final rA = effectiveRanks[a.id] ?? 999;
          final rB = effectiveRanks[b.id] ?? 999;
          if (rA != rB) return rA.compareTo(rB);

          final aYear = _parseYear(a.birthDate);
          final bYear = _parseYear(b.birthDate);
          if (aYear != bYear) return aYear.compareTo(bYear);
          return a.name.compareTo(b.name);
        });

        // Đệ quy dựng cây con
        final childNodes = <FamilyTreeNode>[];
        for (int i = 0; i < childrenList.length; i++) {
          final child = childrenList[i];
          if (!branchVisited.contains(child.id)) {
            final order = child.birthOrder > 0 ? child.birthOrder : (effectiveRanks[child.id] ?? (i + 1));
            childNodes.add(buildSubTree(
              child, 
              currentGen + 1,
              childOrder: order,
              totalSiblings: childrenList.length,
            ));
          }
        }

        final kinship = KinshipService.getKinshipTitle(person, focusPerson, people);
        final spouseKinshipList = <String>[];
        for (int i = 0; i < spousesList.length; i++) {
          final sp = spousesList[i];
          var title = KinshipService.getKinshipTitle(sp, focusPerson, people);
          if (spousesList.length > 1) {
            final orderLabel = (i == 0) ? 'Cả' : (i == 1 ? 'Hai' : '${i + 1}');
            if (sp.gender == 'female') {
              if (title == 'Vợ' || title == 'Mẹ' || title == 'Bà' || title == 'Thím' || title == 'Bác' ||
                  title.startsWith('Bà ') || title.startsWith('Mẹ ')) {
                title = '$title $orderLabel';
              } else {
                title = '$title (Vợ $orderLabel)';
              }
            } else {
              title = '$title (Chồng $orderLabel)';
            }
          }
          spouseKinshipList.add(title);
        }
        final relGen = allGenerations[person.id] ?? (currentGen - 1);

        return FamilyTreeNode(
          person: person,
          spouses: spousesList,
          children: childNodes,
          generation: currentGen,
          relativeGeneration: relGen,
          kinshipTitle: kinship,
          spouseKinshipTitles: spouseKinshipList,
          rootBranchTitle: branchTitle,
          childOrder: childOrder,
          totalSiblings: totalSiblings,
        );
      }

      treeList.add(buildSubTree(root, 1));
    }

    return treeList;
  }

  static int _parseYear(String dateStr) {
    if (dateStr.isEmpty) return 9999;
    final match = RegExp(r'\b(19\d\d|20\d\d)\b').firstMatch(dateStr);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 9999;
    }
    final parts = dateStr.split(RegExp(r'[/.-]'));
    return int.tryParse(parts.last.trim()) ?? 9999;
  }
}
