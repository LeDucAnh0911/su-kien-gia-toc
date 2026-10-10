import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_gio_app/screens/paywall_screen.dart';
import 'package:so_gio_app/services/storage_service.dart';
import 'package:so_gio_app/services/subscription_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Không thể tự kích hoạt Premium khi chưa có thanh toán', () async {
    final storage = StorageService();
    final profile = UserProfile();
    expect(SubscriptionService.paymentsAvailable, isFalse);
    await expectLater(
      SubscriptionService().subscribePlan(
        currentProfile: profile,
        storageService: storage,
      ),
      throwsUnsupportedError,
    );
    await expectLater(
      SubscriptionService().activateFreeTrial(profile, storage),
      throwsUnsupportedError,
    );
    expect((await storage.loadProfile()).isEffectivelyPremium, isFalse);
  });

  testWidgets('Màn hình thử nghiệm không mời mua gói giả', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: PaywallScreen(
        profile: UserProfile(),
        storageService: StorageService(),
        onProfileUpdated: (_) {},
      ),
    ));
    expect(find.text('Bản thử nghiệm miễn phí'), findsOneWidget);
    expect(find.textContaining('10.000 đ'), findsNothing);
    expect(find.textContaining('Google Play hoặc Apple'), findsOneWidget);
  });
}
