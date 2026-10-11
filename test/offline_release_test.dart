import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_gio_app/screens/settings_screen.dart';
import 'package:so_gio_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Bản dùng thử giải thích lưu trên máy và ẩn đồng bộ chưa sẵn sàng',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            profile: UserProfile(),
            events: const [],
            notes: const [],
            familyPeople: const [],
            storageService: StorageService(
              databaseFactory: newDatabaseFactoryMemory(),
            ),
            onProfileUpdated: (_) {},
            onDataRestored: (_, _, _) {},
          ),
        ),
      );
      await tester.pump();
      await tester.scrollUntilVisible(
        find.textContaining('Bản dùng thử hoạt động ngoại tuyến'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.textContaining('Bản dùng thử hoạt động ngoại tuyến'),
        findsOneWidget,
      );
      expect(find.textContaining('Đăng Nhập Bằng Google'), findsNothing);
      expect(find.text('Tải Lên Đám Mây'), findsNothing);
    },
  );
}
