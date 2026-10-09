import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_gio_app/services/storage_service.dart';
import 'package:so_gio_app/services/firebase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FirebaseSyncService Architecture Tests', () {
    late StorageService storageService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storageService = StorageService();
    });

    test('Lưu và đọc Mã kết nối gia đình (Family Sync Code)', () async {
      await storageService.saveFamilySyncCode('LE-GIA-TOC-2026');
      final code = await storageService.loadFamilySyncCode();
      expect(code, equals('LE-GIA-TOC-2026'));
    });

    test('Lưu và đọc thời điểm đồng bộ gần nhất (Last Sync Time)', () async {
      final now = DateTime(2026, 10, 9, 11, 30);
      await storageService.saveLastSyncTime(now);
      final loadedTime = await storageService.loadLastSyncTime();
      expect(loadedTime, isNotNull);
      expect(loadedTime!.year, equals(2026));
      expect(loadedTime.month, equals(10));
      expect(loadedTime.day, equals(9));
      expect(loadedTime.hour, equals(11));
      expect(loadedTime.minute, equals(30));
    });

    test('FirebaseSyncService xử lý mã rỗng an toàn không gây lỗi', () async {
      final service = FirebaseSyncService();
      final result = await service.uploadFamilyData(
        familySyncCode: '   ',
        events: [],
        notes: [],
        familyPeople: [],
        profile: UserProfile(),
      );

      expect(result.success, isFalse);
      expect(result.message, contains('Family Sync Code'));
    });

    test('FirebaseSyncService download với mã rỗng trả về thông báo hợp lệ', () async {
      final service = FirebaseSyncService();
      final result = await service.downloadFamilyData('');

      expect(result.success, isFalse);
      expect(result.message, contains('Family Sync Code'));
    });
  });
}
