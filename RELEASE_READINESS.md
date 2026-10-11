# Kiểm soát phát hành — Sự kiện gia tộc

## Trạng thái bản 1.6.0

- Bản dùng thử miễn phí, ưu tiên lưu trên thiết bị và sao lưu bằng tệp JSON.
- Chưa có đồng bộ đám mây, thanh toán, thông báo khi ứng dụng đóng hoặc chức năng xóa tài khoản đám mây.
- Không bật `ENABLE_CLOUD_SYNC` cho bản công khai cho đến khi Firestore Rules, luồng đăng nhập, xóa tài khoản và thử nghiệm đa thiết bị hoàn tất.
- Mã Android/iOS: `com.leducanh0911.sukiengiatoc`. Bản cũ dùng mã khác; dữ liệu không tự chuyển. Xem hướng dẫn chuyển dữ liệu trong README.
- Các tệp APK/AAB cũ trong thư mục `build` hoặc gốc dự án có thể mang mã ứng dụng cũ hoặc chữ ký debug. Không tải chúng lên kho; chỉ dùng gói mới tạo sau khi cấu hình khóa ký và xác minh định danh.

## Trước khi đưa bản Android vào thử nghiệm qua Play Console

1. Giữ bản sao JSON từ mọi nơi có dữ liệu, đặc biệt Safari và biểu tượng Màn hình chính trên iPhone.
2. Chạy `flutter test`, kiểm tra sao lưu/khôi phục trên ít nhất một Android thật và một iPhone thật. Thử cả trường hợp mở app sau khi cập nhật.
3. Tạo khóa **upload** riêng, lưu khóa và mật khẩu ở nơi an toàn. Sao chép `android/key.properties.example` thành `android/key.properties` rồi điền thông tin thật. Cấu hình Gradle từ chối tác vụ release nếu thiếu tệp này; tuyệt đối không commit khóa/mật khẩu.
4. Xây `flutter build appbundle --release`, kiểm tra gói AAB mang đúng mã ứng dụng và chứng chỉ upload. Mã phiên bản phải tăng ở mỗi lần nộp.
5. Hoàn thiện mô tả, ảnh chụp thật, chính sách quyền riêng tư, khai báo Data safety và thông tin hỗ trợ trong Play Console. Nếu tài khoản cá nhân thuộc diện áp dụng, hoàn thành thử nghiệm kín theo yêu cầu của Google Play trước khi xin phát hành chính thức.

## Trước khi đưa bản iOS vào TestFlight/App Store

1. Dùng máy Mac có Xcode và tài khoản Apple Developer để ký, dựng và thử bản iOS. Dự án chưa được xác nhận chạy trên iPhone thật.
2. Kiểm tra định danh, biểu tượng, màn hình mở đầu, cỡ chữ lớn, sao lưu và khôi phục trong app thật.
3. Hoàn thiện ảnh chụp, mô tả, phân loại tuổi, chính sách quyền riêng tư và khai báo dữ liệu trong App Store Connect.
4. Nếu bật đăng nhập Google sau này, bổ sung lựa chọn đăng nhập tương đương theo quy định Apple, luồng xóa tài khoản và dữ liệu, rồi kiểm thử lại qua TestFlight.

## Trước khi thu phí hoặc bật đồng bộ

- Chọn mô hình giá. Nếu bán tính năng hoặc thuê bao trong app, tích hợp cơ chế mua trong kho tương ứng và xác nhận quyền lợi qua giao dịch thật; không dùng cờ Premium trong dữ liệu cục bộ làm bằng chứng thanh toán.
- Tạo Firestore ở chế độ khóa, triển khai và kiểm thử `firestore.rules`, giới hạn chi phí và dung lượng. Đăng ký lại ứng dụng Android/iOS trong Firebase theo mã mới; thêm SHA chứng chỉ phát hành/Play nếu dùng Google Sign-In trên Android.
- Xây quy trình sao lưu/khôi phục đám mây, xóa tài khoản và dữ liệu, xử lý xung đột giữa thiết bị. Kiểm thử với tài khoản chủ gia tộc và thành viên được mời/thu hồi quyền.
- Thông báo hệ điều hành khi ứng dụng đóng là tính năng chưa có. Chỉ quảng bá sau khi đã triển khai và kiểm thử quyền thông báo, lịch âm và cập nhật sự kiện.
