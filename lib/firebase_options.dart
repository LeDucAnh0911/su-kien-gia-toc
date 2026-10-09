// File cấu hình Firebase Options mặc định cho Web, Android, iOS
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Cung cấp cấu hình Firebase phù hợp với từng nền tảng
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  // Cấu hình Firebase Web (Sự Kiện Gia Tộc)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA88_DemoKey_SoGioGiaToc_VietNam',
    appId: '1:987654321098:web:7a8b9c0d1e2f3a4b',
    messagingSenderId: '987654321098',
    projectId: 'so-gio-gia-toc-vn',
    authDomain: 'so-gio-gia-toc-vn.firebaseapp.com',
    storageBucket: 'so-gio-gia-toc-vn.appspot.com',
  );

  // Cấu hình Firebase Android
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA88_DemoKey_SoGioGiaToc_Android',
    appId: '1:987654321098:android:8b9c0d1e2f3a4b5c',
    messagingSenderId: '987654321098',
    projectId: 'so-gio-gia-toc-vn',
    storageBucket: 'so-gio-gia-toc-vn.appspot.com',
  );

  // Cấu hình Firebase iOS
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA88_DemoKey_SoGioGiaToc_iOS',
    appId: '1:987654321098:ios:9c0d1e2f3a4b5c6d',
    messagingSenderId: '987654321098',
    projectId: 'so-gio-gia-toc-vn',
    storageBucket: 'so-gio-gia-toc-vn.appspot.com',
    iosBundleId: 'vn.io.buudienhatinh.sogio',
  );
}
