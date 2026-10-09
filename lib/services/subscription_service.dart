import 'package:flutter/foundation.dart';
import 'storage_service.dart';

/// Thông tin về một gói đăng ký
class SubscriptionPlan {
  final String id;
  final String title;
  final String priceString;
  final int priceVnd;
  final String periodString;
  final String? badge;
  final String description;
  final bool hasTrial;
  final int trialDays;

  const SubscriptionPlan({
    required this.id,
    required this.title,
    required this.priceString,
    required this.priceVnd,
    required this.periodString,
    this.badge,
    required this.description,
    this.hasTrial = false,
    this.trialDays = 0,
  });
}

/// Dịch vụ Quản lý Đăng ký & Gói cước Gia Tộc VIP (In-App Purchase / Subscription)
class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  /// Danh mục các gói cước chuẩn Store
  static const List<SubscriptionPlan> availablePlans = [
    SubscriptionPlan(
      id: 'sogio_monthly_10k',
      title: 'Gói Tháng (Linh Hoạt)',
      priceString: '10.000 đ',
      priceVnd: 10000,
      periodString: '/ tháng',
      description: 'Chỉ 330 đ/ngày. Tự động gia hạn mỗi tháng. Hủy bất cứ lúc nào.',
      hasTrial: true,
      trialDays: 14,
      badge: 'DÙNG THỬ 14 NGÀY',
    ),
    SubscriptionPlan(
      id: 'sogio_yearly_99k',
      title: 'Gói Năm (Phổ Biến Nhất)',
      priceString: '99.000 đ',
      priceVnd: 99000,
      periodString: '/ năm',
      badge: 'TIẾT KIỆM 17%',
      description: 'Chỉ ~8.250 đ/tháng. Trọn gói cho cả 4 mùa giỗ chạp trong năm.',
      hasTrial: true,
      trialDays: 14,
    ),
    SubscriptionPlan(
      id: 'sogio_lifetime_249k',
      title: 'Gói Gia Tộc Vĩnh Viễn',
      priceString: '249.000 đ',
      priceVnd: 249000,
      periodString: '1 lần duy nhất',
      badge: 'TRỌN ĐỜI',
      description: 'Thanh toán 1 lần dùng mãi mãi. Lưu truyền dữ liệu gia phả đời đời.',
      hasTrial: false,
    ),
  ];

  /// Giới hạn của bản Miễn Phí (Free Tier)
  static const int freeEventsLimit = 10;
  static const int freeFamilyGenerationsLimit = 2;

  /// Kích hoạt gói Dùng thử 14 ngày (Free Trial)
  Future<UserProfile> activateFreeTrial(UserProfile currentProfile, StorageService storageService) async {
    final expire = DateTime.now().add(const Duration(days: 14));
    final updated = UserProfile(
      giaChu: currentProfile.giaChu,
      diaChi: currentProfile.diaChi,
      prayerFontSize: currentProfile.prayerFontSize,
      isDarkMode: currentProfile.isDarkMode,
      isPremium: true,
      premiumExpireDate: expire,
      premiumTier: 'trial',
    );
    await storageService.saveProfile(updated);
    debugPrint('Đã kích hoạt 14 ngày dùng thử miễn phí đến: $expire');
    return updated;
  }

  /// Nâng cấp gói cước
  Future<UserProfile> subscribePlan({
    required SubscriptionPlan plan,
    required UserProfile currentProfile,
    required StorageService storageService,
  }) async {
    DateTime? expire;
    if (plan.id == 'sogio_monthly_10k') {
      expire = DateTime.now().add(const Duration(days: 30));
    } else if (plan.id == 'sogio_yearly_99k') {
      expire = DateTime.now().add(const Duration(days: 365));
    } else {
      expire = null; // Lifetime
    }

    final updated = UserProfile(
      giaChu: currentProfile.giaChu,
      diaChi: currentProfile.diaChi,
      prayerFontSize: currentProfile.prayerFontSize,
      isDarkMode: currentProfile.isDarkMode,
      isPremium: true,
      premiumExpireDate: expire,
      premiumTier: plan.id,
    );

    await storageService.saveProfile(updated);
    debugPrint('Nâng cấp thành công gói: ${plan.title}');
    return updated;
  }

  /// Khôi phục giao dịch đã mua (Restore Purchases)
  Future<UserProfile> restorePurchases(UserProfile currentProfile, StorageService storageService) async {
    // Sẵn sàng kết nối với StoreKit / Google Play Billing
    return currentProfile;
  }

  /// Hủy gói cước / Quay về bản Free
  Future<UserProfile> cancelSubscription(UserProfile currentProfile, StorageService storageService) async {
    final updated = UserProfile(
      giaChu: currentProfile.giaChu,
      diaChi: currentProfile.diaChi,
      prayerFontSize: currentProfile.prayerFontSize,
      isDarkMode: currentProfile.isDarkMode,
      isPremium: false,
      premiumExpireDate: null,
      premiumTier: 'free',
    );
    await storageService.saveProfile(updated);
    return updated;
  }
}
