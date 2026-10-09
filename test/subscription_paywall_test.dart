import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_gio_app/services/storage_service.dart';
import 'package:so_gio_app/services/subscription_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Subscription & Paywall Logic Tests', () {
    late StorageService storageService;
    late SubscriptionService subscriptionService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storageService = StorageService();
      subscriptionService = SubscriptionService();
    });

    test('Mặc định tài khoản ban đầu là Free (isEffectivelyPremium = false)', () {
      final profile = UserProfile();
      expect(profile.isPremium, isFalse);
      expect(profile.isEffectivelyPremium, isFalse);
      expect(profile.premiumTier, equals('free'));
    });

    test('Kích hoạt gói Dùng thử 14 ngày (Free Trial) thành công', () async {
      final initial = UserProfile();
      final updated = await subscriptionService.activateFreeTrial(initial, storageService);

      expect(updated.isPremium, isTrue);
      expect(updated.isEffectivelyPremium, isTrue);
      expect(updated.premiumTier, equals('trial'));
      expect(updated.premiumExpireDate, isNotNull);
      expect(updated.premiumExpireDate!.isAfter(DateTime.now().add(const Duration(days: 13))), isTrue);

      // Kiểm tra lưu trữ SharedPreferences
      final savedProfile = await storageService.loadProfile();
      expect(savedProfile.isEffectivelyPremium, isTrue);
      expect(savedProfile.premiumTier, equals('trial'));
    });

    test('Nâng cấp Gói Tháng 10k/tháng (30 ngày)', () async {
      final initial = UserProfile();
      final monthlyPlan = SubscriptionService.availablePlans.firstWhere((p) => p.id == 'sogio_monthly_10k');
      final updated = await subscriptionService.subscribePlan(
        plan: monthlyPlan,
        currentProfile: initial,
        storageService: storageService,
      );

      expect(updated.isPremium, isTrue);
      expect(updated.isEffectivelyPremium, isTrue);
      expect(updated.premiumTier, equals('sogio_monthly_10k'));
      expect(updated.premiumExpireDate, isNotNull);
    });

    test('Nâng cấp Gói Năm 99k/năm (365 ngày)', () async {
      final initial = UserProfile();
      final yearlyPlan = SubscriptionService.availablePlans.firstWhere((p) => p.id == 'sogio_yearly_99k');
      final updated = await subscriptionService.subscribePlan(
        plan: yearlyPlan,
        currentProfile: initial,
        storageService: storageService,
      );

      expect(updated.isPremium, isTrue);
      expect(updated.isEffectivelyPremium, isTrue);
      expect(updated.premiumTier, equals('sogio_yearly_99k'));
    });

    test('Nâng cấp Gói Trọn Đời (Lifetime)', () async {
      final initial = UserProfile();
      final lifetimePlan = SubscriptionService.availablePlans.firstWhere((p) => p.id == 'sogio_lifetime_249k');
      final updated = await subscriptionService.subscribePlan(
        plan: lifetimePlan,
        currentProfile: initial,
        storageService: storageService,
      );

      expect(updated.isPremium, isTrue);
      expect(updated.isEffectivelyPremium, isTrue);
      expect(updated.premiumTier, equals('sogio_lifetime_249k'));
      expect(updated.premiumExpireDate, isNull);
    });

    test('Hết hạn gói đăng ký (quá hạn) thì isEffectivelyPremium tự động về false', () {
      final expiredProfile = UserProfile(
        isPremium: true,
        premiumExpireDate: DateTime.now().subtract(const Duration(days: 2)),
        premiumTier: 'sogio_monthly_10k',
      );

      expect(expiredProfile.isEffectivelyPremium, isFalse);
    });

    test('Hủy gói VIP đưa tài khoản trở về Free', () async {
      final vipProfile = UserProfile(isPremium: true, premiumTier: 'sogio_monthly_10k');
      final updated = await subscriptionService.cancelSubscription(vipProfile, storageService);

      expect(updated.isPremium, isFalse);
      expect(updated.isEffectivelyPremium, isFalse);
      expect(updated.premiumTier, equals('free'));
    });
  });
}
