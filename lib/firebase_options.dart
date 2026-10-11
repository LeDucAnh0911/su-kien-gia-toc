// Cấu hình Firebase Web hiện có. Bản cài Android/iOS cá nhân cần đăng ký lại
// trong Firebase trước khi bật đồng bộ đám mây.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Cung cấp cấu hình Firebase phù hợp với từng nền tảng
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      'Firebase cho bản cài cá nhân chưa được đăng ký.',
    );
  }

  // Cấu hình Firebase Web (Sự kiện gia tộc)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA5rsB3tSgGs-wWKz1MzxFDwK0r9ub3rYA',
    appId: '1:350014991052:web:cf506d66a541c46da33069',
    messagingSenderId: '350014991052',
    projectId: 'so-gio-gia-toc',
    authDomain: 'so-gio-gia-toc.firebaseapp.com',
    storageBucket: 'so-gio-gia-toc.firebasestorage.app',
  );
}
