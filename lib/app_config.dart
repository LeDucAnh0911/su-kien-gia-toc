/// Các tính năng chỉ bật sau khi dịch vụ thật đã được triển khai và kiểm thử.
/// Bản phát hành thử dùng dữ liệu trên máy và sao lưu bằng tệp.
class AppConfig {
  /// Cập nhật cùng `version` trong pubspec.yaml; bài kiểm thử chặn sai lệch.
  static const String appVersion = '1.6.0';

  static const bool cloudSyncEnabled = bool.fromEnvironment(
    'ENABLE_CLOUD_SYNC',
    defaultValue: false,
  );
}
