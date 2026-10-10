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
    final ducAnh = samplePeople.firstWhere((p) => p.name == 'Người Mẫu');

    test('Tính đúng vai vế họ nội và họ ngoại từ mốc Người Mẫu', () {
      final ongNoi = samplePeople.firstWhere((p) => p.name == 'Ông Nội Mẫu');
      final baNoi = samplePeople.firstWhere((p) => p.name == 'Bà Nội Mẫu');
      final ongNgoai = samplePeople.firstWhere((p) => p.name == 'Ông Ngoại Mẫu');
      final bo = samplePeople.firstWhere((p) => p.name == 'Cha Mẫu');
      final me = samplePeople.firstWhere((p) => p.name == 'Mẹ Mẫu');
      final vo = samplePeople.firstWhere((p) => p.name == 'Vợ Mẫu');
      final con = samplePeople.firstWhere((p) => p.name == 'Con Mẫu');
      final chuVuong = samplePeople.firstWhere((p) => p.name == 'Chú Mẫu 1');

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
    final ducAnh = samplePeople.firstWhere((p) => p.name == 'Người Mẫu');

    test('Xây dựng cây phả hệ Bên Nội với vợ chồng nằm cùng node', () {
      final treeNoi = FamilyTreeBuilder.buildTree(
        people: samplePeople,
        focusPerson: ducAnh,
        mode: 'noi',
      );

      expect(treeNoi.isNotEmpty, true);
      final rootNode = treeNoi.first;
      // Gốc bên nội là Ông Nội Mẫu, có vợ là Bà Nội Mẫu
      expect(rootNode.person.name, 'Ông Nội Mẫu');
      expect(rootNode.spouse?.name, 'Bà Nội Mẫu');
      expect(rootNode.children.isNotEmpty, true);

      // Con có Cha Mẫu
      final boNode = rootNode.children.firstWhere((c) => c.person.name == 'Cha Mẫu');
      expect(boNode.spouse?.name, 'Mẹ Mẫu');

      // Cháu có Người Mẫu
      final meNode = boNode.children.firstWhere((c) => c.person.name == 'Người Mẫu');
      expect(meNode.spouse?.name, 'Vợ Mẫu');

      // Chắt có Con Mẫu
      final conNode = meNode.children.firstWhere((c) => c.person.name == 'Con Mẫu');
      expect(conNode.person.name, 'Con Mẫu');
    });

    test('Xây dựng cây phả hệ Bên Ngoại bắt đầu từ Ông Ngoại Mẫu', () {
      final treeNgoai = FamilyTreeBuilder.buildTree(
        people: samplePeople,
        focusPerson: ducAnh,
        mode: 'ngoai',
      );

      expect(treeNgoai.isNotEmpty, true);
      final rootNgoai = treeNgoai.first;
      expect(rootNgoai.person.name, 'Ông Ngoại Mẫu');
      expect(rootNgoai.relativeGeneration, -2);
      expect(rootNgoai.children.isNotEmpty, true);
      // Con gái là Mẹ Mẫu
      expect(rootNgoai.children.first.person.name, 'Mẹ Mẫu');
      expect(rootNgoai.children.first.relativeGeneration, -1);
    });

    test('Xây dựng cây phả hệ Bên Vợ bắt đầu từ Bố Vợ Mẫu', () {
      final treeVo = FamilyTreeBuilder.buildTree(
        people: samplePeople,
        focusPerson: ducAnh,
        mode: 'vo',
      );

      expect(treeVo.isNotEmpty, true);
      final rootVo = treeVo.first;
      expect(rootVo.person.name, 'Bố Vợ Mẫu');
      expect(rootVo.spouse?.name, 'Mẹ Vợ Mẫu');
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
      expect(rootNames, contains('Ông Nội Mẫu'));
      expect(rootNames, contains('Ông Ngoại Mẫu'));
      expect(rootNames, contains('Bố Vợ Mẫu'));

      // Kiểm tra tính chuẩn xác của thế hệ tương đối để căn cùng một dòng
      final patRoot = treeAll.firstWhere((r) => r.person.name == 'Ông Nội Mẫu');
      final matRoot = treeAll.firstWhere((r) => r.person.name == 'Ông Ngoại Mẫu');
      final spRoot = treeAll.firstWhere((r) => r.person.name == 'Bố Vợ Mẫu');

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
          giaChuName: 'Người Mẫu',
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
      expect(find.text('Bố Vợ Mẫu'), findsWidgets);

      // Chuyển sang tab Danh Sách
      await tester.tap(find.text('Danh Sách'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Người Mẫu'), findsWidgets);
      expect(find.text('Cha Mẫu'), findsWidgets);
      expect(find.text('Mẹ Mẫu'), findsWidgets);
      expect(find.text('Bố Vợ Mẫu'), findsWidgets);
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
          giaChuName: 'Người Mẫu',
        ),
      ));
      await tester.pumpAndSettle();

      // Nhấn nút Thêm người
      await tester.tap(find.text('Thêm người'));
      await tester.pumpAndSettle();

      expect(find.text('Thêm người thân'), findsOneWidget);

      // Chọn Cha là Ông Nội Mẫu -> Tự động gợi ý Mẹ là Bà Nội Mẫu
      final fatherDropdown = find.byType(DropdownButtonFormField<String>).at(2);
      await tester.ensureVisible(fatherDropdown);
      await tester.pumpAndSettle();
      await tester.tap(fatherDropdown);
      await tester.pumpAndSettle();

      // Chọn Ông Nội Mẫu trong danh sách
      await tester.tap(find.text('Ông Nội Mẫu (Bên nội)').last);
      await tester.pumpAndSettle();

      // Kiểm tra dropdown Mẹ đã tự động chọn Bà Nội Mẫu
      expect(find.text('Bà Nội Mẫu (Bên nội)'), findsOneWidget);
    });

    test('Bản thân mặc định luôn là Người Mẫu khi giaChuName rỗng', () {
      final defaultFocus = KinshipService.findDefaultFocusPerson(samplePeople, '');
      expect(defaultFocus, isNotNull);
      expect(defaultFocus!.name, 'Người Mẫu');
    });

    test('Thứ tự con trong cây: Con 1 ở bên trái, các con tiếp theo ở bên phải kèm thứ tự con', () {
      final ducAnh = samplePeople.firstWhere((p) => p.name == 'Người Mẫu');
      final tree = FamilyTreeBuilder.buildTree(
        people: samplePeople,
        focusPerson: ducAnh,
        mode: 'noi',
      );

      final ongNoiNode = tree.firstWhere((n) => n.person.name == 'Ông Nội Mẫu');
      expect(ongNoiNode.children.length, 4);

      // Con 1 ở vị trí index 0 (bên trái), Con 2 ở index 1...
      expect(ongNoiNode.children[0].person.name, 'Cha Mẫu');
      expect(ongNoiNode.children[0].childOrder, 1);
      expect(ongNoiNode.children[0].totalSiblings, 4);

      expect(ongNoiNode.children[1].person.name, 'Chú Mẫu 1');
      expect(ongNoiNode.children[1].childOrder, 2);

      expect(ongNoiNode.children[2].person.name, 'Chú Mẫu 2');
      expect(ongNoiNode.children[2].childOrder, 3);

      expect(ongNoiNode.children[3].person.name, 'Cô Mẫu');
      expect(ongNoiNode.children[3].childOrder, 4);

      // Nhánh con của Cha Mẫu: Người Mẫu (Con 1), Em Trai Mẫu (Con 2)
      final boNode = ongNoiNode.children[0];
      expect(boNode.children.length, 2);
      expect(boNode.children[0].person.name, 'Người Mẫu');
      expect(boNode.children[0].childOrder, 1);
      expect(boNode.children[1].person.name, 'Em Trai Mẫu');
      expect(boNode.children[1].childOrder, 2);
    });

    test('Lỗi chọn Con 2 hoặc Con 4 không được nhảy lên đầu bên trái', () {
      final ducAnh = samplePeople.firstWhere((p) => p.name == 'Người Mẫu');

      // Test case 1: Chỉ chọn Con 2 cho Chú Mẫu 1 (birthOrder = 2), các con khác để 0 (tự động)
      final testPeople1 = samplePeople.map((p) {
        if (p.name == 'Chú Mẫu 1') return p.copyWith(birthOrder: 2);
        if (['Cha Mẫu', 'Chú Mẫu 2', 'Cô Mẫu'].contains(p.name)) {
          return p.copyWith(birthOrder: 0);
        }
        return p;
      }).toList();

      final tree1 = FamilyTreeBuilder.buildTree(
        people: testPeople1,
        focusPerson: ducAnh,
        mode: 'noi',
      );
      final ongNoiNode1 = tree1.firstWhere((n) => n.person.name == 'Ông Nội Mẫu');
      // Thứ tự vẫn phải là: Cha Mẫu (Con 1), Chú Mẫu 1 (Con 2), Chú Mẫu 2 (Con 3), Cô Mẫu (Con 4)
      expect(ongNoiNode1.children[0].person.name, 'Cha Mẫu');
      expect(ongNoiNode1.children[0].childOrder, 1);
      expect(ongNoiNode1.children[1].person.name, 'Chú Mẫu 1');
      expect(ongNoiNode1.children[1].childOrder, 2);
      expect(ongNoiNode1.children[2].person.name, 'Chú Mẫu 2');
      expect(ongNoiNode1.children[2].childOrder, 3);
      expect(ongNoiNode1.children[3].person.name, 'Cô Mẫu');
      expect(ongNoiNode1.children[3].childOrder, 4);

      // Test case 2: Chỉ chọn Con 4 cho Cô Mẫu (birthOrder = 4), các con khác để 0 (tự động)
      final testPeople2 = samplePeople.map((p) {
        if (p.name == 'Cô Mẫu') return p.copyWith(birthOrder: 4);
        if (['Cha Mẫu', 'Chú Mẫu 1', 'Chú Mẫu 2'].contains(p.name)) {
          return p.copyWith(birthOrder: 0);
        }
        return p;
      }).toList();

      final tree2 = FamilyTreeBuilder.buildTree(
        people: testPeople2,
        focusPerson: ducAnh,
        mode: 'noi',
      );
      final ongNoiNode2 = tree2.firstWhere((n) => n.person.name == 'Ông Nội Mẫu');
      // Cô Mẫu không được nhảy lên index 0, phải ở cuối bên phải (index 3)
      expect(ongNoiNode2.children[0].person.name, 'Cha Mẫu');
      expect(ongNoiNode2.children[0].childOrder, 1);
      expect(ongNoiNode2.children[1].person.name, 'Chú Mẫu 1');
      expect(ongNoiNode2.children[1].childOrder, 2);
      expect(ongNoiNode2.children[2].person.name, 'Chú Mẫu 2');
      expect(ongNoiNode2.children[2].childOrder, 3);
      expect(ongNoiNode2.children[3].person.name, 'Cô Mẫu');
      expect(ongNoiNode2.children[3].childOrder, 4);

      // Test case 3: Chọn Con 2 và Con 4 đồng thời, Con 1 và Con 3 để 0
      final testPeople3 = samplePeople.map((p) {
        if (p.name == 'Chú Mẫu 1') return p.copyWith(birthOrder: 2);
        if (p.name == 'Cô Mẫu') return p.copyWith(birthOrder: 4);
        if (['Cha Mẫu', 'Chú Mẫu 2'].contains(p.name)) {
          return p.copyWith(birthOrder: 0);
        }
        return p;
      }).toList();

      final tree3 = FamilyTreeBuilder.buildTree(
        people: testPeople3,
        focusPerson: ducAnh,
        mode: 'noi',
      );
      final ongNoiNode3 = tree3.firstWhere((n) => n.person.name == 'Ông Nội Mẫu');
      expect(ongNoiNode3.children[0].person.name, 'Cha Mẫu');
      expect(ongNoiNode3.children[0].childOrder, 1);
      expect(ongNoiNode3.children[1].person.name, 'Chú Mẫu 1');
      expect(ongNoiNode3.children[1].childOrder, 2);
      expect(ongNoiNode3.children[2].person.name, 'Chú Mẫu 2');
      expect(ongNoiNode3.children[2].childOrder, 3);
      expect(ongNoiNode3.children[3].person.name, 'Cô Mẫu');
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
