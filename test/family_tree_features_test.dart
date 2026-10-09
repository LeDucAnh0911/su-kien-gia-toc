import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_gio_app/models/family_person.dart';
import 'package:so_gio_app/screens/family_screen.dart';
import 'package:so_gio_app/services/family_tree_builder.dart';
import 'package:so_gio_app/services/kinship_service.dart';
import 'package:so_gio_app/services/storage_service.dart';

void main() {
  final samplePeople = StorageService.getInitialSampleFamilyPeople();

  group('KinshipService Tests (Xưng hô chuẩn mực theo mốc)', () {
    final ducAnh = samplePeople.firstWhere((p) => p.name == 'Lê Đức Anh');

    test('Tính đúng vai vế họ nội và họ ngoại từ mốc Lê Đức Anh', () {
      final ongNoi = samplePeople.firstWhere((p) => p.name == 'Lê Văn Đô');
      final baNoi = samplePeople.firstWhere((p) => p.name == 'Trương Thị Lạng');
      final ongNgoai = samplePeople.firstWhere((p) => p.name == 'Nghiêm Khang');
      final bo = samplePeople.firstWhere((p) => p.name == 'Lê Văn Hùng');
      final me = samplePeople.firstWhere((p) => p.name == 'Nghiêm Thị Linh');
      final vo = samplePeople.firstWhere((p) => p.name == 'Nguyễn Thị Thương');
      final con = samplePeople.firstWhere((p) => p.name == 'Lê Tùng Lâm');
      final chuVuong = samplePeople.firstWhere((p) => p.name == 'Lê Quang Vượng');

      expect(KinshipService.getKinshipTitle(ducAnh, ducAnh, samplePeople), 'Tôi (Bản thân)');
      expect(KinshipService.getKinshipTitle(ongNoi, ducAnh, samplePeople), 'Ông nội');
      expect(KinshipService.getKinshipTitle(baNoi, ducAnh, samplePeople), 'Bà nội');
      expect(KinshipService.getKinshipTitle(ongNgoai, ducAnh, samplePeople), 'Ông ngoại');
      expect(KinshipService.getKinshipTitle(bo, ducAnh, samplePeople), 'Bố (Cha)');
      expect(KinshipService.getKinshipTitle(me, ducAnh, samplePeople), 'Mẹ');
      expect(KinshipService.getKinshipTitle(vo, ducAnh, samplePeople), 'Vợ');
      expect(KinshipService.getKinshipTitle(con, ducAnh, samplePeople), 'Con trai');
      expect(KinshipService.getKinshipTitle(chuVuong, ducAnh, samplePeople), contains('Bên nội'));
    });
  });

  group('FamilyTreeBuilder Tests (Cặp vợ chồng & Phân cấp thế hệ)', () {
    final ducAnh = samplePeople.firstWhere((p) => p.name == 'Lê Đức Anh');

    test('Xây dựng cây phả hệ Bên Nội với vợ chồng nằm cùng node', () {
      final treeNoi = FamilyTreeBuilder.buildTree(
        people: samplePeople,
        focusPerson: ducAnh,
        mode: 'noi',
      );

      expect(treeNoi.isNotEmpty, true);
      final rootNode = treeNoi.first;
      // Gốc bên nội là Lê Văn Đô, có vợ là Trương Thị Lạng
      expect(rootNode.person.name, 'Lê Văn Đô');
      expect(rootNode.spouse?.name, 'Trương Thị Lạng');
      expect(rootNode.children.isNotEmpty, true);

      // Con có Lê Văn Hùng
      final boNode = rootNode.children.firstWhere((c) => c.person.name == 'Lê Văn Hùng');
      expect(boNode.spouse?.name, 'Nghiêm Thị Linh');

      // Cháu có Lê Đức Anh
      final meNode = boNode.children.firstWhere((c) => c.person.name == 'Lê Đức Anh');
      expect(meNode.spouse?.name, 'Nguyễn Thị Thương');

      // Chắt có Lê Tùng Lâm
      final conNode = meNode.children.firstWhere((c) => c.person.name == 'Lê Tùng Lâm');
      expect(conNode.person.name, 'Lê Tùng Lâm');
    });

    test('Xây dựng cây phả hệ Bên Ngoại bắt đầu từ Nghiêm Khang', () {
      final treeNgoai = FamilyTreeBuilder.buildTree(
        people: samplePeople,
        focusPerson: ducAnh,
        mode: 'ngoai',
      );

      expect(treeNgoai.isNotEmpty, true);
      final rootNgoai = treeNgoai.first;
      expect(rootNgoai.person.name, 'Nghiêm Khang');
      expect(rootNgoai.relativeGeneration, -2);
      expect(rootNgoai.children.isNotEmpty, true);
      // Con gái là Nghiêm Thị Linh
      expect(rootNgoai.children.first.person.name, 'Nghiêm Thị Linh');
      expect(rootNgoai.children.first.relativeGeneration, -1);
    });

    test('Xây dựng cây phả hệ Bên Vợ bắt đầu từ Nguyễn Quốc Nam', () {
      final treeVo = FamilyTreeBuilder.buildTree(
        people: samplePeople,
        focusPerson: ducAnh,
        mode: 'vo',
      );

      expect(treeVo.isNotEmpty, true);
      final rootVo = treeVo.first;
      expect(rootVo.person.name, 'Nguyễn Quốc Nam');
      expect(rootVo.spouse?.name, 'Từ Thị Nga');
      expect(rootVo.relativeGeneration, -1); // Bố mẹ vợ cùng đời -1
      expect(rootVo.children.isNotEmpty, true);
    });

    test('Xây dựng Toàn Cảnh bao quát cả 3 dòng họ với thế hệ ngang hàng chuẩn xác', () {
      final treeAll = FamilyTreeBuilder.buildTree(
        people: samplePeople,
        focusPerson: ducAnh,
        mode: 'all',
      );

      expect(treeAll.length, greaterThanOrEqualTo(3));
      final rootNames = treeAll.map((r) => r.person.name).toList();
      expect(rootNames, contains('Lê Văn Đô'));
      expect(rootNames, contains('Nghiêm Khang'));
      expect(rootNames, contains('Nguyễn Quốc Nam'));

      // Kiểm tra tính chuẩn xác của thế hệ tương đối để căn cùng một dòng
      final patRoot = treeAll.firstWhere((r) => r.person.name == 'Lê Văn Đô');
      final matRoot = treeAll.firstWhere((r) => r.person.name == 'Nghiêm Khang');
      final spRoot = treeAll.firstWhere((r) => r.person.name == 'Nguyễn Quốc Nam');

      expect(patRoot.relativeGeneration, -2); // Ông bà nội
      expect(matRoot.relativeGeneration, -2); // Ông bà ngoại
      expect(spRoot.relativeGeneration, -1);  // Bố mẹ vợ
    });
  });

  group('FamilyScreen UI Widget Tests', () {
    testWidgets('Hiển thị các tab Bên Nội, Bên Ngoại, Bên Vợ, Toàn Cảnh, Danh Sách', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(MaterialApp(
        home: FamilyScreen(
          people: samplePeople,
          onSaved: (_) {},
          onDeleted: (_) {},
          giaChuName: 'Lê Đức Anh',
        ),
      ));
      await tester.pumpAndSettle();

      // Kiểm tra sự xuất hiện của các tab chế độ xem
      expect(find.text('Bên Nội'), findsOneWidget);
      expect(find.text('Bên Ngoại'), findsOneWidget);
      expect(find.text('Bên Vợ'), findsOneWidget);
      expect(find.text('Toàn Cảnh'), findsOneWidget);
      expect(find.text('Danh Sách'), findsOneWidget);

      // Chuyển sang tab Bên Vợ
      await tester.tap(find.text('Bên Vợ'));
      await tester.pumpAndSettle();
      expect(find.text('Nguyễn Quốc Nam'), findsWidgets);

      // Chuyển sang tab Danh Sách
      await tester.tap(find.text('Danh Sách'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Lê Đức Anh'), findsWidgets);
      expect(find.text('Lê Văn Hùng'), findsWidgets);
      expect(find.text('Nghiêm Thị Linh'), findsWidgets);
      expect(find.text('Nguyễn Quốc Nam'), findsWidgets);
    });

    testWidgets('Tự động gợi ý Mẹ khi chọn Cha trong Form thêm người', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(MaterialApp(
        home: FamilyScreen(
          people: samplePeople,
          onSaved: (_) {},
          onDeleted: (_) {},
          giaChuName: 'Lê Đức Anh',
        ),
      ));
      await tester.pumpAndSettle();

      // Nhấn nút Thêm người
      await tester.tap(find.text('Thêm người'));
      await tester.pumpAndSettle();

      expect(find.text('Thêm người thân'), findsOneWidget);

      // Chọn Cha là Lê Văn Đô -> Tự động gợi ý Mẹ là Trương Thị Lạng
      final fatherDropdown = find.byType(DropdownButtonFormField<String>).at(2);
      await tester.ensureVisible(fatherDropdown);
      await tester.pumpAndSettle();
      await tester.tap(fatherDropdown);
      await tester.pumpAndSettle();

      // Chọn Lê Văn Đô trong danh sách
      await tester.tap(find.text('Lê Văn Đô (Bên nội)').last);
      await tester.pumpAndSettle();

      // Kiểm tra dropdown Mẹ đã tự động chọn Trương Thị Lạng
      expect(find.text('Trương Thị Lạng (Bên nội)'), findsOneWidget);
    });

    test('Bản thân mặc định luôn là Lê Đức Anh khi giaChuName rỗng', () {
      final defaultFocus = KinshipService.findDefaultFocusPerson(samplePeople, '');
      expect(defaultFocus, isNotNull);
      expect(defaultFocus!.name, 'Lê Đức Anh');
    });

    test('Thứ tự con trong cây: Con 1 ở bên trái, các con tiếp theo ở bên phải kèm thứ tự con', () {
      final ducAnh = samplePeople.firstWhere((p) => p.name == 'Lê Đức Anh');
      final tree = FamilyTreeBuilder.buildTree(
        people: samplePeople,
        focusPerson: ducAnh,
        mode: 'noi',
      );

      final ongNoiNode = tree.firstWhere((n) => n.person.name == 'Lê Văn Đô');
      expect(ongNoiNode.children.length, 4);

      // Con 1 ở vị trí index 0 (bên trái), Con 2 ở index 1...
      expect(ongNoiNode.children[0].person.name, 'Lê Văn Hùng');
      expect(ongNoiNode.children[0].childOrder, 1);
      expect(ongNoiNode.children[0].totalSiblings, 4);

      expect(ongNoiNode.children[1].person.name, 'Lê Quang Vượng');
      expect(ongNoiNode.children[1].childOrder, 2);

      expect(ongNoiNode.children[2].person.name, 'Lê Kiên Cường');
      expect(ongNoiNode.children[2].childOrder, 3);

      expect(ongNoiNode.children[3].person.name, 'Lê Thị Hường');
      expect(ongNoiNode.children[3].childOrder, 4);

      // Nhánh con của Lê Văn Hùng: Lê Đức Anh (Con 1), Lê Quang Minh (Con 2)
      final boNode = ongNoiNode.children[0];
      expect(boNode.children.length, 2);
      expect(boNode.children[0].person.name, 'Lê Đức Anh');
      expect(boNode.children[0].childOrder, 1);
      expect(boNode.children[1].person.name, 'Lê Quang Minh');
      expect(boNode.children[1].childOrder, 2);
    });

    test('Lỗi chọn Con 2 hoặc Con 4 không được nhảy lên đầu bên trái', () {
      final ducAnh = samplePeople.firstWhere((p) => p.name == 'Lê Đức Anh');

      // Test case 1: Chỉ chọn Con 2 cho Lê Quang Vượng (birthOrder = 2), các con khác để 0 (tự động)
      final testPeople1 = samplePeople.map((p) {
        if (p.name == 'Lê Quang Vượng') return p.copyWith(birthOrder: 2);
        if (['Lê Văn Hùng', 'Lê Kiên Cường', 'Lê Thị Hường'].contains(p.name)) {
          return p.copyWith(birthOrder: 0);
        }
        return p;
      }).toList();

      final tree1 = FamilyTreeBuilder.buildTree(
        people: testPeople1,
        focusPerson: ducAnh,
        mode: 'noi',
      );
      final ongNoiNode1 = tree1.firstWhere((n) => n.person.name == 'Lê Văn Đô');
      // Thứ tự vẫn phải là: Lê Văn Hùng (Con 1), Lê Quang Vượng (Con 2), Lê Kiên Cường (Con 3), Lê Thị Hường (Con 4)
      expect(ongNoiNode1.children[0].person.name, 'Lê Văn Hùng');
      expect(ongNoiNode1.children[0].childOrder, 1);
      expect(ongNoiNode1.children[1].person.name, 'Lê Quang Vượng');
      expect(ongNoiNode1.children[1].childOrder, 2);
      expect(ongNoiNode1.children[2].person.name, 'Lê Kiên Cường');
      expect(ongNoiNode1.children[2].childOrder, 3);
      expect(ongNoiNode1.children[3].person.name, 'Lê Thị Hường');
      expect(ongNoiNode1.children[3].childOrder, 4);

      // Test case 2: Chỉ chọn Con 4 cho Lê Thị Hường (birthOrder = 4), các con khác để 0 (tự động)
      final testPeople2 = samplePeople.map((p) {
        if (p.name == 'Lê Thị Hường') return p.copyWith(birthOrder: 4);
        if (['Lê Văn Hùng', 'Lê Quang Vượng', 'Lê Kiên Cường'].contains(p.name)) {
          return p.copyWith(birthOrder: 0);
        }
        return p;
      }).toList();

      final tree2 = FamilyTreeBuilder.buildTree(
        people: testPeople2,
        focusPerson: ducAnh,
        mode: 'noi',
      );
      final ongNoiNode2 = tree2.firstWhere((n) => n.person.name == 'Lê Văn Đô');
      // Lê Thị Hường không được nhảy lên index 0, phải ở cuối bên phải (index 3)
      expect(ongNoiNode2.children[0].person.name, 'Lê Văn Hùng');
      expect(ongNoiNode2.children[0].childOrder, 1);
      expect(ongNoiNode2.children[1].person.name, 'Lê Quang Vượng');
      expect(ongNoiNode2.children[1].childOrder, 2);
      expect(ongNoiNode2.children[2].person.name, 'Lê Kiên Cường');
      expect(ongNoiNode2.children[2].childOrder, 3);
      expect(ongNoiNode2.children[3].person.name, 'Lê Thị Hường');
      expect(ongNoiNode2.children[3].childOrder, 4);

      // Test case 3: Chọn Con 2 và Con 4 đồng thời, Con 1 và Con 3 để 0
      final testPeople3 = samplePeople.map((p) {
        if (p.name == 'Lê Quang Vượng') return p.copyWith(birthOrder: 2);
        if (p.name == 'Lê Thị Hường') return p.copyWith(birthOrder: 4);
        if (['Lê Văn Hùng', 'Lê Kiên Cường'].contains(p.name)) {
          return p.copyWith(birthOrder: 0);
        }
        return p;
      }).toList();

      final tree3 = FamilyTreeBuilder.buildTree(
        people: testPeople3,
        focusPerson: ducAnh,
        mode: 'noi',
      );
      final ongNoiNode3 = tree3.firstWhere((n) => n.person.name == 'Lê Văn Đô');
      expect(ongNoiNode3.children[0].person.name, 'Lê Văn Hùng');
      expect(ongNoiNode3.children[0].childOrder, 1);
      expect(ongNoiNode3.children[1].person.name, 'Lê Quang Vượng');
      expect(ongNoiNode3.children[1].childOrder, 2);
      expect(ongNoiNode3.children[2].person.name, 'Lê Kiên Cường');
      expect(ongNoiNode3.children[2].childOrder, 3);
      expect(ongNoiNode3.children[3].person.name, 'Lê Thị Hường');
      expect(ongNoiNode3.children[3].childOrder, 4);
    });

    test('Trường hợp 2 vợ: hiển thị 3 người ngang hàng (Chồng, Vợ Cả, Vợ Hai) và gom con cái', () {
      final husband = FamilyPerson(
        id: 'fp_poly_man',
        name: 'Lê Thế Gia',
        gender: 'male',
        branch: 'noi',
        birthDate: '1940',
        spouseIds: ['fp_poly_wife1', 'fp_poly_wife2'],
      );
      final wife1 = FamilyPerson(
        id: 'fp_poly_wife1',
        name: 'Nguyễn Thị Cả',
        gender: 'female',
        branch: 'vo',
        birthDate: '1942',
        spouseIds: ['fp_poly_man'],
      );
      final wife2 = FamilyPerson(
        id: 'fp_poly_wife2',
        name: 'Trần Thị Hai',
        gender: 'female',
        branch: 'vo',
        birthDate: '1948',
        spouseIds: ['fp_poly_man'],
      );
      final child1 = FamilyPerson(
        id: 'fp_child1',
        name: 'Lê Văn Trưởng',
        gender: 'male',
        branch: 'noi',
        birthDate: '1965',
        fatherId: 'fp_poly_man',
        motherId: 'fp_poly_wife1',
        birthOrder: 1,
      );
      final child2 = FamilyPerson(
        id: 'fp_child2',
        name: 'Lê Văn Thứ',
        gender: 'male',
        branch: 'noi',
        birthDate: '1970',
        fatherId: 'fp_poly_man',
        motherId: 'fp_poly_wife2',
        birthOrder: 2,
      );

      final testPeople = [husband, wife1, wife2, child1, child2];

      final tree = FamilyTreeBuilder.buildTree(
        people: testPeople,
        focusPerson: husband,
        mode: 'noi',
      );

      expect(tree.isNotEmpty, true);
      final node = tree.first;
      expect(node.person.name, 'Lê Thế Gia');
      // 2 người vợ phải cùng thuộc node này
      expect(node.spouses.length, 2);
      expect(node.spouses[0].name, 'Nguyễn Thị Cả');
      expect(node.spouses[1].name, 'Trần Thị Hai');

      // Vợ cả đứng trước vợ hai
      expect(node.spouseKinshipTitles[0], contains('Cả'));
      expect(node.spouseKinshipTitles[1], contains('Hai'));

      // Con của cả 2 vợ đều được gom vào đàn con chung
      expect(node.children.length, 2);
      expect(node.children[0].person.name, 'Lê Văn Trưởng');
      expect(node.children[1].person.name, 'Lê Văn Thứ');
    });
  });
}
