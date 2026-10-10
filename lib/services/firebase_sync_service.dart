import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase_options.dart';
import '../models/event_model.dart';
import '../models/note_model.dart';
import '../models/family_person.dart';
import 'family_sync_code.dart';
import 'storage_service.dart';

class _SyncProblem implements Exception {
  final String message;
  const _SyncProblem(this.message);
}

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
  Future<void>? _googleSignInInitialization;

  static const _webClientId =
      '350014991052-4kh8o8qjrrq5dncrbbr8iftd2q1r1h4u.apps.googleusercontent.com';
  static const _iosClientId =
      '350014991052-1g1e7hjlouf6cm7e10kikvog3fjdr9vb.apps.googleusercontent.com';

  User? get currentUser => _auth?.currentUser;
  Stream<User?> get authStateChanges =>
      _auth?.authStateChanges() ?? const Stream.empty();

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

      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        final userCredential = await _auth!.signInWithPopup(googleProvider);
        return userCredential.user;
      }

      if (defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS) {
        final userCredential = await _auth!.signInWithProvider(
          GoogleAuthProvider(),
        );
        return userCredential.user;
      }

      _googleSignInInitialization ??= GoogleSignIn.instance.initialize(
        clientId: defaultTargetPlatform == TargetPlatform.iOS
            ? _iosClientId
            : null,
        serverClientId: _webClientId,
      );
      await _googleSignInInitialization;
      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth!.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      debugPrint('Lỗi đăng nhập Google: $e');
      rethrow;
    }
  }

  /// Đăng xuất khỏi Firebase
  Future<void> signOut() async {
    try {
      await _auth?.signOut();
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS) &&
          _googleSignInInitialization != null) {
        await GoogleSignIn.instance.signOut();
      }
    } catch (e) {
      debugPrint('Lỗi khi đăng xuất: $e');
    }
  }

  CloudSyncResult _failure(Object error) {
    if (error is _SyncProblem) {
      return CloudSyncResult(success: false, message: error.message);
    }
    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return const CloudSyncResult(
          success: false,
          message: 'Tài khoản này chưa được cấp quyền truy cập gia tộc. Kiểm tra email đăng nhập và quyền do chủ gia tộc cấp.',
        );
      }
      if (error.code == 'unavailable' || error.code == 'failed-precondition') {
        return const CloudSyncResult(
          success: false,
          message: 'Firestore chưa sẵn sàng hoặc thiết bị đang mất kết nối. Dữ liệu trên máy chưa thay đổi.',
        );
      }
    }
    debugPrint('Lỗi đồng bộ Firestore: $error');
    return const CloudSyncResult(
      success: false,
      message: 'Không thể đồng bộ lúc này. Dữ liệu trên máy chưa thay đổi; vui lòng thử lại.',
    );
  }

  Future<User?> _signedInUser() async {
    if (!_isInitialized) await initialize();
    return currentUser;
  }

  /// Chỉ chủ gia tộc được tải lên. Mỗi bản cập nhật phải dựa trên phiên bản đã kéo về.
  Future<CloudSyncResult> uploadFamilyData({
    required String familySyncCode,
    required List<EventItem> events,
    required List<DailyNoteItem> notes,
    required List<FamilyPerson> familyPeople,
    required UserProfile profile,
  }) async {
    try {
      final code = FamilySyncCode.normalize(familySyncCode);
      if (!FamilySyncCode.isValid(code)) {
        return const CloudSyncResult(
          success: false,
          message: 'Mã kết nối gia đình (Family Sync Code) chưa hợp lệ. Hãy tạo mã mới trong Cài đặt.',
        );
      }
      final familyData = <String, dynamic>{
        'profile': profile.toMap(),
        'events': events.map((e) => e.toMap()).toList(),
        'notes': notes.map((n) => n.toMap()).toList(),
        'familyPeople': familyPeople.map((p) => p.toMap()).toList(),
      };
      if (utf8.encode(jsonEncode(familyData)).length > 850000) {
        return const CloudSyncResult(
          success: false,
          message: 'Dữ liệu gia tộc quá lớn cho một bản đám mây. Hãy giảm số ảnh trong gia phả hoặc xuất bản sao lưu trước khi thử lại.',
        );
      }
      final user = await _signedInUser();
      if (user == null) {
        return const CloudSyncResult(
          success: false,
          message: 'Hãy đăng nhập Google trước khi tải dữ liệu lên.',
        );
      }
      if (_firestore == null) {
        return const CloudSyncResult(
          success: false,
          message: 'Dịch vụ Firestore chưa được kết nối.',
        );
      }

      final docRef = _firestore!.collection('families').doc(code);
      final expectedRevision = await StorageService().loadSyncRevision(code);
      final payload = <String, dynamic>{
        'syncCode': code,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedAtIso': DateTime.now().toIso8601String(),
        'updatedByEmail': user.email ?? '',
        'updatedByName': user.displayName ?? profile.giaChu,
        ...familyData,
      };
      final revision = await _firestore!.runTransaction<int>((
        transaction,
      ) async {
        final remote = await transaction.get(docRef);
        if (!remote.exists) {
          if (expectedRevision != null) {
            throw const _SyncProblem(
              'Bản đám mây không còn tồn tại. Hãy tạo mã mới và kiểm tra bản sao lưu trước khi tải lên.',
            );
          }
          transaction.set(docRef, {
            ...payload,
            'ownerUid': user.uid,
            'memberEmails': <String>[],
            'revision': 1,
          });
          return 1;
        }
        final data = remote.data()!;
        if (data['ownerUid'] != user.uid) {
          throw const _SyncProblem(
            'Chỉ chủ gia tộc đã tạo bộ dữ liệu mới được tải lên.',
          );
        }
        final remoteRevision = data['revision'];
        if (remoteRevision is! int || expectedRevision != remoteRevision) {
          throw const _SyncProblem(
            'Bản đám mây đã thay đổi hoặc máy này chưa kéo bản mới nhất. Hãy sao lưu dữ liệu trên máy, kéo về và kiểm tra trước khi tải lên lại.',
          );
        }
        final nextRevision = remoteRevision + 1;
        transaction.update(docRef, {...payload, 'revision': nextRevision});
        return nextRevision;
      });
      await StorageService().saveSyncRevision(code, revision);

      return CloudSyncResult(
        success: true,
        message: 'Đã tải lên đám mây bản số $revision cho gia tộc "$code".',
      );
    } catch (e) {
      return _failure(e);
    }
  }

  /// Thành viên được chủ gia tộc cấp quyền chỉ có thể đọc bản đám mây.
  Future<CloudSyncResult> downloadFamilyData(String familySyncCode) async {
    try {
      final code = FamilySyncCode.normalize(familySyncCode);
      if (!FamilySyncCode.isValid(code)) {
        return const CloudSyncResult(
          success: false,
          message: 'Mã kết nối gia đình (Family Sync Code) chưa hợp lệ.',
        );
      }
      final user = await _signedInUser();
      if (user == null) {
        return const CloudSyncResult(
          success: false,
          message: 'Hãy đăng nhập Google trước khi kéo dữ liệu về.',
        );
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
          message:
              'Không tìm thấy dữ liệu gia phả cho mã "$code" trên đám mây.',
        );
      }

      final map = docSnap.data()!;
      if (map['ownerUid'] is! String || map['revision'] is! int) {
        return const CloudSyncResult(
          success: false,
          message: 'Bản đám mây dùng định dạng cũ chưa có chủ sở hữu. Hãy dùng bản sao lưu trên máy để tạo gia tộc với mã mới.',
        );
      }
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
        'events': eventsList
            .map((item) => EventItem.fromMap(item as Map<String, dynamic>))
            .toList(),
        'notes': notesList
            .map((item) => DailyNoteItem.fromMap(item as Map<String, dynamic>))
            .toList(),
        'familyPeople': familyList
            .map((item) => FamilyPerson.fromMap(item as Map<String, dynamic>))
            .toList(),
        'profile': profile,
        'updatedByName': map['updatedByName'] ?? '',
        'updatedAtIso': map['updatedAtIso'] ?? '',
        'revision': map['revision'],
        'cloudRole': map['ownerUid'] == user.uid ? 'owner' : 'viewer',
      };

      return CloudSyncResult(
        success: true,
        message: 'Đã tải thành công dữ liệu gia phả cho mã "$code".',
        data: resultData,
      );
    } catch (e) {
      return _failure(e);
    }
  }

  /// Chủ gia tộc cấp quyền xem theo email Google đã xác minh.
  Future<CloudSyncResult> grantViewerAccess(
    String familySyncCode,
    String email,
  ) => _changeViewerAccess(familySyncCode, email, grant: true);

  /// Chủ gia tộc có thể thu hồi quyền xem của một email đã mời.
  Future<CloudSyncResult> revokeViewerAccess(
    String familySyncCode,
    String email,
  ) => _changeViewerAccess(familySyncCode, email, grant: false);

  Future<CloudSyncResult> _changeViewerAccess(
    String familySyncCode,
    String email, {
    required bool grant,
  }) async {
    try {
      final code = FamilySyncCode.normalize(familySyncCode);
      final viewerEmail = email.trim().toLowerCase();
      if (!FamilySyncCode.isValid(code)) {
        return const CloudSyncResult(
          success: false,
          message: 'Mã gia tộc chưa hợp lệ.',
        );
      }
      if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(viewerEmail)) {
        return const CloudSyncResult(
          success: false,
          message: 'Email thành viên chưa hợp lệ.',
        );
      }
      final user = await _signedInUser();
      if (user == null) {
        return const CloudSyncResult(
          success: false,
          message: 'Hãy đăng nhập Google bằng tài khoản chủ gia tộc.',
        );
      }
      if (_firestore == null) {
        return const CloudSyncResult(
          success: false,
          message: 'Firestore chưa sẵn sàng.',
        );
      }
      final docRef = _firestore!.collection('families').doc(code);
      await _firestore!.runTransaction<void>((transaction) async {
        final remote = await transaction.get(docRef);
        if (!remote.exists) {
          throw const _SyncProblem(
            'Chưa có dữ liệu gia tộc trên đám mây. Chủ gia tộc cần tải lên trước.',
          );
        }
        final data = remote.data()!;
        if (data['ownerUid'] != user.uid) {
          throw const _SyncProblem(
            'Chỉ chủ gia tộc mới được cấp quyền cho thành viên.',
          );
        }
        final emails = List<String>.from(
          data['memberEmails'] ?? const <String>[],
        );
        if (grant) {
          if (emails.contains(viewerEmail)) return;
          if (emails.length >= 50) {
            throw const _SyncProblem(
              'Gia tộc đã đạt giới hạn 50 tài khoản được mời.',
            );
          }
          emails.add(viewerEmail);
        } else {
          if (!emails.remove(viewerEmail)) {
            throw const _SyncProblem('Email này chưa được cấp quyền xem.');
          }
        }
        transaction.update(docRef, {
          'memberEmails': emails,
        });
      });
      return CloudSyncResult(
        success: true,
        message: grant
            ? 'Đã cấp quyền xem cho $viewerEmail. Thành viên cần đăng nhập đúng email này và kéo dữ liệu về.'
            : 'Đã thu hồi quyền xem của $viewerEmail trên đám mây. Bản sao người này đã tải về thiết bị vẫn còn.',
      );
    } catch (e) {
      return _failure(e);
    }
  }
}
