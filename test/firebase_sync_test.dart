import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_gio_app/services/storage_service.dart';
import 'package:so_gio_app/services/firebase_sync_service.dart';
import 'package:so_gio_app/services/family_sync_code.dart';

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

    test('Mã mới có 128 bit ngẫu nhiên và mã cũ dễ đoán bị từ chối', () {
      final codes = List<String>.generate(100, (_) => FamilySyncCode.generate());
      expect(codes.toSet().length, 100);
      expect(codes.every(FamilySyncCode.isValid), isTrue);
      expect(FamilySyncCode.isValid('LE-GIA-TOC-2026'), isFalse);
      expect(FamilySyncCode.isValid('FAM-1234'), isFalse);
    });

    test('Phiên bản đồng bộ lưu riêng theo từng gia tộc', () async {
      final first = FamilySyncCode.generate();
      final second = FamilySyncCode.generate();
      expect(await storageService.loadSyncRevision(first), isNull);
      await storageService.saveSyncRevision(first, 3);
      await storageService.saveSyncRevision(second, 7);
      expect(await storageService.loadSyncRevision(first), 3);
      expect(await storageService.loadSyncRevision(second), 7);
    });

    test('Sổ mới và danh sách đã xóa hết đều trống, không tự chèn dữ liệu mẫu', () async {
      expect(await storageService.loadEvents(), isEmpty);
      expect(await storageService.loadNotes(), isEmpty);
      expect(await storageService.loadFamilyPeople(), isEmpty);
      await storageService.saveEvents([]);
      await storageService.saveFamilyPeople([]);
      expect(await storageService.loadEvents(), isEmpty);
      expect(await storageService.loadFamilyPeople(), isEmpty);
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
