import 'dart:math';

/// Mã định danh gia tộc ngẫu nhiên. Quyền truy cập vẫn do Firestore Rules quyết định.
class FamilySyncCode {
  static final RegExp _pattern = RegExp(r'^FAM-[0-9A-F]{32}$');

  static String normalize(String value) => value.trim().toUpperCase();

  static bool isValid(String value) => _pattern.hasMatch(normalize(value));

  static String generate() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
    return 'FAM-$hex';
  }
}
