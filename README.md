# SỔ GIỖ & LỊCH GIA TỘC (VIETNAMESE ANCESTRAL CALENDAR & MEMORIAL APP)

Ứng dụng đa nền tảng (Android, iOS qua mã Flutter, Web/PWA) hỗ trợ quản lý ngày giỗ, gia phả nội ngoại, tra cứu lịch âm dương, văn khấn, ghi chú và chia sẻ sổ giỗ.

---

## 1. Các Tiêu Chí Nâng Cấp Nổi Bật

### 🏛️ Bản Sắc Dân Tộc & Cung Đình Hoàng Gia
- **Tone màu chủ đạo**: Đỏ Chu Sa sơn mài truyền thống (`#8B1E0F`), điểm xuyết ánh Vàng Hoàng Kim dát vàng (`#D4AF37`) trên nền giấy dó thanh tịnh.
- **Họa tiết**: Trống Đồng Đông Sơn, Hoa Sen, vân mây cung đình mềm mại, tôn nghiêm.
- **Văn hóa cổ truyền chuẩn mực**:
  - Tự động phân định **Lễ Tiên Thường** (chiều hôm trước giỗ) và **Lễ Chính Kỵ** (ngày giỗ chính).
  - Thuật toán thiên văn học **Âm Lịch Việt Nam chuẩn GMT+7** của TS. Hồ Ngọc Đức.
  - Tự động xử lý **tháng thiếu 29 ngày** và **tháng nhuận**, không bao giờ bị lệch ngày cúng.
  - Hiển thị **Can Chi** của Năm, Tháng, Ngày; tính **24 Tiết Khí** trong năm và **Ngày Hoàng Đạo / Hắc Đạo**.
  - Liệt kê **6 khung giờ Hoàng Đạo trong ngày** để gia chủ chọn giờ đẹp làm lễ cúng.

### ⚡ Công Nghệ Hiện Đại & Đa Nền Tảng (Dual-Mode Responsive)
- **Trên Máy Tính / Màn hình rộng (Desktop / Tablet)**:
  - Sidebar Hoàng Gia bên trái với đồng hồ Âm Dương và menu tiện ích.
  - Bố cục 2-3 cột rộng rãi, sắc nét: Hero Countdown đếm ngược, danh sách ngày giỗ, việc cần làm.
- **Trên Điện Thoại (Mobile)**:
  - Tự động thích ứng giao diện Mobile App chuẩn, thanh điều hướng đáy (Bottom Navigation) mượt mà.
  - Hỗ trợ cài đặt PWA (Add to Home Screen).
- **Âm thanh Chuông Đồng Gia Tiên**:
  - Tích hợp tiếng chuông đồng thanh tịnh được tổng hợp bằng Web Audio API (không cần tải file ngoài, ngân nga ấm áp trước khi đọc văn khấn).
- **Kho Văn Khấn Cổ Truyền**:
  - Tự động điền tên Gia chủ, Tín chủ, Địa chỉ, Tên cố nhân và Ngày cúng vào bài khấn.
  - Chế độ đọc toàn màn hình với nút tăng/giảm cỡ chữ cho người lớn tuổi.
- **Xuất Sổ Giỗ & Chia Sẻ Zalo**:
  - Xuất bản in A4 chuẩn như bản sắc phong để dán phòng thờ hoặc lưu file PDF.
  - Nút sao chép văn bản tóm tắt ngày giỗ trong năm để dán nhanh vào nhóm Zalo họ tộc.

### 🌳 Gia phả dòng họ
- Menu **Gia Phả** có trên Web hiện tại và trong mã Flutter cho Android/iOS.
- Thêm, sửa, xóa hồ sơ; ghi tên, giới tính, nhánh nội/ngoại, ngày sinh/mất (có thể chỉ ghi năm), lịch âm/dương, quê quán, nơi an nghỉ và ghi chép.
- Nối cha, mẹ, nhiều vợ/chồng; từ đó xem con, anh chị em và các đời. Có tìm kiếm, lọc nhánh, xem dạng cây hoặc danh sách.
- Dữ liệu gia phả lưu cục bộ trên từng thiết bị; sao lưu JSON ở **Cài Đặt & Dữ Liệu** để chuyển sang thiết bị khác. Gia phả chưa tự đồng bộ giữa các máy.

---

## 2. Cách Khởi Chạy & Sử Dụng

### 🌐 Chạy Web App (Máy tính & Trình duyệt)
- Nhấp đúp vào file `Mo_Ung_Dung_Web.bat` hoặc truy cập địa chỉ:
  ```
  http://localhost:8088/   (trên máy bàn 10.43.130.9)
  hoặc
  http://10.43.130.9:8088/ (từ các máy khác trong mạng nội bộ)
  ```

### 📱 Tải Cài Đặt Lên Điện Thoại Android
- Truy cập `http://10.43.130.9:8088/` từ trình duyệt điện thoại và bấm nút **"Tải App Android"**, hoặc tải trực tiếp tại:
  ```
  http://10.43.130.9:8088/So_Gio_Gia_Toc.apk
  ```

### 🔨 Đóng Gói Lại Bản Cài Đặt (Khi Có Thay Đổi Code Dart)
1. **Biên dịch bản Web**: Chạy file `Build_Web.bat`. Script biên dịch Flutter và đưa giao diện Web độc lập từ `standalone_web/` vào `build/web/`.
2. **Đóng gói file cài đặt APK**: Chạy file `Xuat_File_Apk.bat` (file APK sau khi build sẽ tự động được copy vào `build\web\So_Gio_Gia_Toc.apk`)
3. **Chạy Flutter Dev (Hot Reload)**: Chạy file `Chay_Flutter_Dev.bat`

---

## 3. Cấu Trúc Mã Nguồn

```
so_gio_app/
├── lib/
│   ├── data/
│   │   └── prayers_data.dart         # Kho dữ liệu văn khấn cổ truyền & hàm thay thế thông tin
│   ├── models/
│   │   ├── event_model.dart          # Model Ngày Giỗ, Mâm Cỗ, Thu Chi Đóng Góp
│   │   ├── family_person.dart         # Hồ sơ người thân và quan hệ gia phả
│   │   └── note_model.dart           # Model Ghi Chú & Việc Cần Làm Theo Ngày
│   ├── screens/
│   │   ├── home_screen.dart          # Màn hình Trang Chủ (Hero Countdown, Tìm kiếm, Lọc)
│   │   ├── family_screen.dart        # Gia phả trên Android/iOS/Flutter Web
│   │   ├── calendar_screen.dart      # Màn hình Lịch Tháng Âm - Dương & Chi tiết ngày
│   │   ├── prayers_screen.dart       # Danh mục các bài văn khấn cổ truyền
│   │   ├── prayer_detail_screen.dart # Chi tiết bài khấn & chế độ đọc to chữ
│   │   ├── event_detail_screen.dart  # Quản lý mâm cỗ, thu chi đóng góp con cháu
│   │   ├── add_edit_event_screen.dart# Form thêm/sửa ngày giỗ
│   │   └── settings_screen.dart      # Cài đặt gia chủ, sao lưu & xuất Sổ Giỗ Zalo
│   ├── services/
│   │   ├── event_calculator.dart     # Tính ngày giỗ tiếp theo & đếm ngược
│   │   └── storage_service.dart      # Lưu trữ SharedPreferences & Sao lưu JSON
│   ├── widgets/
│   │   └── add_edit_note_sheet.dart  # Modal ghi chú nhanh
│   ├── lunar_engine.dart             # Thuật toán Âm Lịch, Can Chi, Tiết Khí, Giờ Hoàng Đạo
│   └── main.dart                     # Shell thích ứng đa màn hình Responsive Desktop & Mobile
├── standalone_web/                  # Mã nguồn giao diện Web độc lập
│   ├── index.html                    # Trang chính
│   ├── family.js                     # Quản lý gia phả Web
│   └── family.css                    # Giao diện gia phả Web
├── build/web/                       # Bản Web đang được phục vụ ở cổng 8088
│   └── So_Gio_Gia_Toc.apk            # Bản cài đặt Android
├── Build_Web.bat                     # Script biên dịch Flutter Web
├── Xuat_File_Apk.bat                 # Script đóng gói Android APK
├── Chay_Flutter_Dev.bat              # Script chạy chế độ dev
└── Mo_Ung_Dung_Web.bat               # Script khởi động web server cổng 8088
```
