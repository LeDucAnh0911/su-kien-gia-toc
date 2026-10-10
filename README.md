# Sự Kiện Gia Tộc

Ứng dụng Flutter cá nhân để ghi ngày giỗ, sự kiện, ghi chú, văn khấn và quan hệ gia phả. Bản web: https://leducanh0911.github.io/su-kien-gia-toc/

## Trạng thái hiện tại

- Dữ liệu sự kiện, ghi chú, gia phả và hồ sơ được lưu trong Sembast (IndexedDB trên web). Bản cũ trong `shared_preferences` được chuyển một lần bằng giao dịch; bản cũ được giữ để khôi phục cho đến khi người dùng chủ động xóa dữ liệu trên thiết bị.
- Sao lưu và phục hồi qua tệp JSON. Tệp JSON là văn bản chưa mã hóa, cần giữ riêng tư.
- Ngày âm lịch, tháng nhuận và ngày nhập không hợp lệ được kiểm tra trước khi lưu. Khi năm tới không có tháng nhuận tương ứng, sự kiện gốc tháng nhuận dùng cùng ngày ở tháng thường.
- Lời nhắc hiện khi mở ứng dụng; chưa có thông báo hệ điều hành khi ứng dụng đã đóng.
- Google Sign-In đã được cấu hình cho dự án Firebase `so-gio-gia-toc`. Đăng nhập không tự đồng bộ.
- Đồng bộ Firestore là thao tác thủ công. Cloud Firestore và `firestore.rules` phải được triển khai an toàn trước khi sử dụng dữ liệu thật. Hiện chưa công bố tính năng này là đã hoạt động.
- Chủ gia tộc có thể cấp và thu hồi quyền xem theo email. Dữ liệu tải về máy người khác trước khi thu hồi vẫn còn trên máy họ. Ứng dụng chặn bản tải lên quá lớn cho một tài liệu Firestore; cần chuyển sang nhiều tài liệu trước khi gia phả lớn được đồng bộ.
- Không có thanh toán hoặc gói VIP đang bán. Bản thử nghiệm được dùng miễn phí.

## Phát triển

```powershell
C:\src\flutter\bin\flutter.bat pub get
C:\src\flutter\bin\flutter.bat test
C:\src\flutter\bin\flutter.bat build web --release --no-wasm-dry-run
Copy-Item web\flutter_service_worker.js build\web\flutter_service_worker.js -Force
```

`Build_Web.bat` tạo bản Flutter và chép Service Worker riêng vào `build/web`; script không chép giao diện `standalone_web` đè lên ứng dụng nữa. Nhánh `main` chứa mã nguồn, nhánh `gh-pages` chứa bản web đã biên dịch. Kiểm tra hai nhánh trước khi phát hành.

## Thiết kế quyền đám mây

1. Chủ gia tộc đăng nhập Google, tạo mã `FAM-` ngẫu nhiên và tải bộ dữ liệu đầu tiên lên. Tài khoản tạo dữ liệu là chủ sở hữu.
2. Chủ gia tộc thêm email Google đã xác minh của từng người thân. Người được mời dùng đúng email đó để đọc dữ liệu; mã mời một mình không cấp quyền.
3. Chỉ chủ sở hữu tải lên. Mỗi bản ghi có số phiên bản; nếu một thiết bị khác đã cập nhật, bản tải lên cũ bị từ chối. Trước khi kéo dữ liệu về, ứng dụng xuất một bản sao lưu cục bộ.
4. Quyền phải được kiểm tra trong `firestore.rules` trên máy chủ. Không dùng quy tắc công khai hay chỉ kiểm tra `request.auth != null`.

**Chưa triển khai Firestore:** Khi tạo database, chọn chế độ khóa mặc định, kiểm thử và phát hành `firestore.rules` trước khi cho người dùng tải dữ liệu. Chạy `firebase deploy --only firestore:rules --project so-gio-gia-toc` từ thư mục này sau khi CLI đăng nhập đúng tài khoản quản trị. Quy tắc chưa được áp dụng chỉ vì tệp có mặt trong Git.

Các tài liệu gia tộc theo định dạng mã cũ không tự được nhận quyền sở hữu. Hãy giữ bản sao lưu tại thiết bị, tạo mã mới và tải lại sau khi xác nhận Firestore đã an toàn.

## Quyền riêng tư

Ứng dụng không tự đăng hồ sơ lên internet. Dữ liệu có thể chứa thông tin người thân và trẻ em; chỉ tải lên khi có quyền chia sẻ. Mã nguồn và bản web công khai chỉ nên chứa dữ liệu ví dụ hư cấu. Dữ liệu đã được đưa lên lịch sử Git trước đây cần được xem xét riêng vì xóa trong bản hiện tại không xóa các commit cũ.
