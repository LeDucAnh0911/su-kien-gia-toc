/// Các tính năng chỉ bật sau khi dịch vụ thật đã được triển khai và kiểm thử.
/// Bản phát hành thử dùng dữ liệu trên máy và sao lưu bằng tệp.
class AppConfig {
  static const bool cloudSyncEnabled = bool.fromEnvironment(
    'ENABLE_CLOUD_SYNC',
    defaultValue: false,
  );
}
