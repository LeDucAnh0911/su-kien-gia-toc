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

  // Cấu hình Firebase Web (Sự kiện gia tộc)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA5rsB3tSgGs-wWKz1MzxFDwK0r9ub3rYA',
    appId: '1:350014991052:web:cf506d66a541c46da33069',
    messagingSenderId: '350014991052',
    projectId: 'so-gio-gia-toc',
    authDomain: 'so-gio-gia-toc.firebaseapp.com',
    storageBucket: 'so-gio-gia-toc.firebasestorage.app',
  );

  // Cấu hình Firebase Android
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCVVcqRdrPuikMiFDQdWtupuHPmHETIKXs',
    appId: '1:350014991052:android:17668fb40e4ca6aca33069',
    messagingSenderId: '350014991052',
    projectId: 'so-gio-gia-toc',
    storageBucket: 'so-gio-gia-toc.firebasestorage.app',
  );

  // Cấu hình Firebase iOS
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCI4s4aku20Zu6kPhAdpwQlygOhLDKCU0U',
    appId: '1:350014991052:ios:0ccf8721f9ce92a2a33069',
    messagingSenderId: '350014991052',
    projectId: 'so-gio-gia-toc',
    storageBucket: 'so-gio-gia-toc.firebasestorage.app',
    iosBundleId: 'vn.buudienhatinh.sogio.soGioApp',
  );
}
