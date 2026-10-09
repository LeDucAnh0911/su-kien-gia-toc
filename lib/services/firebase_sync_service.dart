import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';
import '../models/event_model.dart';
import '../models/note_model.dart';
import '../models/family_person.dart';
import 'storage_service.dart';

/// Kết quả thao tác đồng bộ đám mây
class CloudSyncResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  const CloudSyncResult({
    required this.success,
    required this.message,
    this.data,
  });
}

/// Dịch vụ Đồng bộ Đám mây Firebase & Đăng nhập Google
class FirebaseSyncService {
  static final FirebaseSyncService _instance = FirebaseSyncService._internal();
  factory FirebaseSyncService() => _instance;
  FirebaseSyncService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;

  User? get currentUser => _auth?.currentUser;
  Stream<User?> get authStateChanges => _auth?.authStateChanges() ?? const Stream.empty();

  /// Khởi tạo an toàn Firebase (Local-First: Nếu lỗi hoặc chưa có key thực vẫn không crash)
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _isInitialized = true;
      debugPrint('FirebaseSyncService: Khởi tạo Firebase thành công.');
      return true;
    } catch (e) {
      debugPrint('FirebaseSyncService: Thông báo khởi tạo Firebase: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Đăng nhập bằng Google trên Web và Mobile
  Future<User?> signInWithGoogle() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (_auth == null) {
        throw Exception('Firebase Auth chưa sẵn sàng');
      }

      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      if (kIsWeb) {
        final userCredential = await _auth!.signInWithPopup(googleProvider);
        return userCredential.user;
      } else {
        final userCredential = await _auth!.signInWithProvider(googleProvider);
        return userCredential.user;
      }
    } catch (e) {
      debugPrint('Lỗi đăng nhập Google: $e');
      rethrow;
    }
  }

  /// Đăng xuất khỏi Firebase
  Future<void> signOut() async {
    try {
      await _auth?.signOut();
    } catch (e) {
      debugPrint('Lỗi khi đăng xuất: $e');
    }
  }

  /// Tải dữ liệu gia đình lên Cloud Firestore
  /// Lưu vào bộ sưu tập: `families/{familySyncCode}`
  Future<CloudSyncResult> uploadFamilyData({
    required String familySyncCode,
    required List<EventItem> events,
    required List<DailyNoteItem> notes,
    required List<FamilyPerson> familyPeople,
    required UserProfile profile,
  }) async {
    try {
      final code = familySyncCode.trim().toUpperCase();
      if (code.isEmpty) {
        return const CloudSyncResult(
          success: false,
          message: 'Mã kết nối gia đình (Family Sync Code) không được để trống.',
        );
      }

      if (!_isInitialized) {
        await initialize();
      }

      if (_firestore == null) {
        return const CloudSyncResult(
          success: false,
          message: 'Dịch vụ Firestore chưa được kết nối.',
        );
      }

      final docRef = _firestore!.collection('families').doc(code);

      final payload = {
        'syncCode': code,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedAtIso': DateTime.now().toIso8601String(),
        'updatedByEmail': currentUser?.email ?? 'anonymous',
        'updatedByName': currentUser?.displayName ?? profile.giaChu,
        'profile': profile.toMap(),
        'events': events.map((e) => e.toMap()).toList(),
        'notes': notes.map((n) => n.toMap()).toList(),
        'familyPeople': familyPeople.map((p) => p.toMap()).toList(),
        'meta': {
          'eventsCount': events.length,
          'notesCount': notes.length,
          'familyPeopleCount': familyPeople.length,
          'version': '1.3.0',
        },
      };

      await docRef.set(payload, SetOptions(merge: true));

      return CloudSyncResult(
        success: true,
        message: 'Đã tải lên đám mây thành công cho mã gia tộc "$code".',
      );
    } catch (e) {
      debugPrint('Lỗi upload dữ liệu lên Firestore: $e');
      return CloudSyncResult(
        success: false,
        message: 'Lỗi tải lên đám mây: $e',
      );
    }
  }

  /// Kéo dữ liệu gia đình từ Cloud Firestore về máy
  Future<CloudSyncResult> downloadFamilyData(String familySyncCode) async {
    try {
      final code = familySyncCode.trim().toUpperCase();
      if (code.isEmpty) {
        return const CloudSyncResult(
          success: false,
          message: 'Vui lòng nhập Mã kết nối gia đình (Family Sync Code).',
        );
      }

      if (!_isInitialized) {
        await initialize();
      }

      if (_firestore == null) {
        return const CloudSyncResult(
          success: false,
          message: 'Dịch vụ Firestore chưa được kết nối.',
        );
      }

      final docRef = _firestore!.collection('families').doc(code);
      final docSnap = await docRef.get();

      if (!docSnap.exists || docSnap.data() == null) {
        return CloudSyncResult(
          success: false,
          message: 'Không tìm thấy dữ liệu gia phả cho mã "$code" trên đám mây.',
        );
      }

      final map = docSnap.data()!;
      final List<dynamic> eventsList = map['events'] ?? [];
      final List<dynamic> notesList = map['notes'] ?? [];
      final List<dynamic> familyList = map['familyPeople'] ?? [];

      UserProfile? profile;
      if (map['profile'] != null && map['profile'] is Map<String, dynamic>) {
        try {
          profile = UserProfile.fromMap(map['profile'] as Map<String, dynamic>);
        } catch (_) {}
      }

      final resultData = {
        'events': eventsList.map((item) => EventItem.fromMap(item as Map<String, dynamic>)).toList(),
        'notes': notesList.map((item) => DailyNoteItem.fromMap(item as Map<String, dynamic>)).toList(),
        'familyPeople': familyList.map((item) => FamilyPerson.fromMap(item as Map<String, dynamic>)).toList(),
        'profile': profile,
        'updatedByName': map['updatedByName'] ?? '',
        'updatedAtIso': map['updatedAtIso'] ?? '',
      };

      return CloudSyncResult(
        success: true,
        message: 'Đã tải thành công dữ liệu gia phả cho mã "$code".',
        data: resultData,
      );
    } catch (e) {
      debugPrint('Lỗi download dữ liệu từ Firestore: $e');
      return CloudSyncResult(
        success: false,
        message: 'Lỗi kéo dữ liệu đám mây: $e',
      );
    }
  }
}
