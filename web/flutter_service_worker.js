'use strict';

const CACHE_NAME = 'su-kien-gia-toc-v20261011-1';

// Danh sách tài nguyên cốt lõi cần nạp sẵn để mở tức thì (< 1 giây) trên iPhone & Android
const PRECACHE_ASSETS = [
  './',
  'index.html',
  'flutter_bootstrap.js',
  'main.dart.js',
  'manifest.json',
  'favicon.png',
  'apple-touch-icon.png',
  'icons/Icon-192.png',
  'icons/Icon-512.png',
  'icons/Icon-maskable-192.png',
  'icons/Icon-maskable-512.png',
  'canvaskit/canvaskit.js',
  'canvaskit/canvaskit.wasm',
  'canvaskit/chromium/canvaskit.wasm',
  'canvaskit/webparagraph/canvaskit.wasm',
  'assets/FontManifest.json',
  'assets/fonts/MaterialIcons-Regular.otf'
];

// Cài đặt: Tải trước tài nguyên vào bộ nhớ đệm
self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return Promise.allSettled(
        PRECACHE_ASSETS.map((url) =>
          cache.add(new Request(url, { cache: 'reload' })).catch((err) => {
            console.log('Tài nguyên tùy chọn không có sẵn để nạp sẵn:', url);
          })
        )
      );
    })
  );
});

// Kích hoạt: Dọn dẹp cache cũ và chiếm quyền điều khiển ngay lập tức (KHÔNG unregister, KHÔNG navigate vòng lặp)
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys
          .filter((key) => key.startsWith('su-kien-gia-toc-') && key !== CACHE_NAME)
          .map((key) => caches.delete(key))
      );
    }).then(() => self.clients.claim())
  );
});

// Xử lý truy vấn mạng
self.addEventListener('fetch', (event) => {
  const req = event.request;
  const url = new URL(req.url);

  // Bỏ qua các yêu cầu không phải GET hoặc dịch vụ đồng bộ Firebase / Google
  if (req.method !== 'GET') return;
  if (url.origin !== self.location.origin) {
    if (url.hostname.includes('firebase') ||
        url.hostname.includes('firestore') ||
        url.hostname.includes('googleapis.com') ||
        url.hostname.includes('google.com')) {
      return;
    }
  }

  // Đối với trang HTML điều hướng: Network-First có Cache fallback để luôn cập nhật
  if (req.mode === 'navigate' || req.destination === 'document') {
    event.respondWith(
      fetch(req)
        .then((networkRes) => {
          if (networkRes && networkRes.status === 200) {
            const clone = networkRes.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(req, clone));
          }
          return networkRes;
        })
        .catch(() => {
          return caches.match(req).then((cached) => cached || caches.match('./') || caches.match('index.html'));
        })
    );
    return;
  }

  // Đối với toàn bộ tài nguyên tĩnh (JS, WASM, Fonts, Images, CSS): Cache-First cực nhanh
  event.respondWith(
    caches.match(req).then((cachedRes) => {
      if (cachedRes) {
        return cachedRes;
      }
      return fetch(req).then((networkRes) => {
        if (networkRes && networkRes.status === 200) {
          const clone = networkRes.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(req, clone));
        }
        return networkRes;
      });
    })
  );
});
