import 'storage_service.dart';

/// Thanh toán chưa được tích hợp. Không cấp quyền trả phí từ trạng thái cục bộ.
class SubscriptionService {
  static const bool paymentsAvailable = false;

  Future<UserProfile> subscribePlan({
    required UserProfile currentProfile,
    required StorageService storageService,
  }) async {
    throw UnsupportedError('Ứng dụng chưa hỗ trợ thanh toán.');
  }

  Future<UserProfile> activateFreeTrial(
    UserProfile currentProfile,
    StorageService storageService,
  ) async {
    throw UnsupportedError('Ứng dụng đang mở miễn phí trong giai đoạn thử nghiệm.');
  }
}
