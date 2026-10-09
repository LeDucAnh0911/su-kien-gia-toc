import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/subscription_service.dart';

/// Màn hình Giới thiệu & Nâng cấp Gói Gia Tộc VIP (Paywall Screen)
class PaywallScreen extends StatefulWidget {
  final UserProfile profile;
  final StorageService storageService;
  final Function(UserProfile) onProfileUpdated;

  const PaywallScreen({
    super.key,
    required this.profile,
    required this.storageService,
    required this.onProfileUpdated,
  });

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  int _selectedPlanIndex = 1; // Mặc định chọn Gói Năm (Phổ biến nhất)
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isVip = widget.profile.isEffectivelyPremium;
    final plans = SubscriptionService.availablePlans;
    final selectedPlan = plans[_selectedPlanIndex];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFAF6F0),
      appBar: AppBar(
        title: const Text('Gia Tộc Hoàng Kim VIP'),
        backgroundColor: const Color(0xFF8B1E0F),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _restorePurchases,
            child: const Text('Khôi phục', style: TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HEADER VÀNG ÁNH KIM & ĐỎ TRẦM TRUYỀN THỐNG
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF8B1E0F), Color(0xFF5D1006)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFD700).withOpacity(0.18),
                      border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                    ),
                    child: const Icon(
                      Icons.workspace_premium,
                      color: Color(0xFFFFD700),
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'SỰ KIỆN & GIA TỘC HOÀNG KIM',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Uống Nước Nhớ Nguồn • Lưu Truyền Đạo Hiếu Muôn Đời',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  if (isVip)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.profile.premiumTier == 'trial'
                            ? 'Đang Trong Thời Gian Dùng Thử Miễn Phí'
                            : 'Tài Khoản Của Bạn Đã Là Thành Viên VIP',
                        style: const TextStyle(color: Color(0xFF5D1006), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)),
                      ),
                      child: const Text(
                        '✨ DÙNG THỬ 14 NGÀY HOÀN TOÀN MIỄN PHÍ ✨',
                        style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // SO SÁNH QUYỀN LỢI FREE VS VIP
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 1.5,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.stars_rounded, color: Color(0xFFD4AF37)),
                          SizedBox(width: 8),
                          Text('Đặc Quyền Hội Viên Gia Tộc VIP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildBenefitRow(
                        title: 'Cây Gia Phả Dòng Họ',
                        freeDesc: 'Tối đa 2 đời cơ bản',
                        vipDesc: 'Vô hạn thế hệ (Cụ, Kỵ, Nội, Ngoại, Vợ)',
                        icon: Icons.account_tree_outlined,
                      ),
                      const Divider(height: 20),
                      _buildBenefitRow(
                        title: 'Ngày Giỗ & Sự Kiện Âm Lịch',
                        freeDesc: 'Tối đa 10 ngày giỗ',
                        vipDesc: 'Không giới hạn ngày giỗ & sinh nhật',
                        icon: Icons.calendar_month_outlined,
                      ),
                      const Divider(height: 20),
                      _buildBenefitRow(
                        title: 'Đồng Bộ Đám Mây Gia Đình',
                        freeDesc: 'Chỉ lưu trên 1 máy này',
                        vipDesc: 'Đồng bộ tự động 24/7 cho cả dòng họ',
                        icon: Icons.cloud_sync_outlined,
                      ),
                      const Divider(height: 20),
                      _buildBenefitRow(
                        title: 'Xuất Sự Kiện & Bản Tin Zalo',
                        freeDesc: 'Văn bản thường',
                        vipDesc: 'Bản tin sự kiện trang trọng in ấn & gửi Zalo họ',
                        icon: Icons.print_outlined,
                      ),
                      const Divider(height: 20),
                      _buildBenefitRow(
                        title: 'Nhắc Nhở Văn Hóa Tâm Linh',
                        freeDesc: 'Đúng ngày giỗ',
                        vipDesc: 'Nhắc trước 3-7 ngày & Lễ Tiên Thường',
                        icon: Icons.notifications_active_outlined,
                      ),
                      const Divider(height: 20),
                      _buildBenefitRow(
                        title: 'Trải Nghiệm Thuần Khiết',
                        freeDesc: 'Bản cơ bản',
                        vipDesc: '100% Không có bất kỳ quảng cáo nào',
                        icon: Icons.block,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // DANH SÁCH CÁC GÓI ĐĂNG KÝ
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Chọn Gói Phù Hợp Cho Gia Đình:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  for (int i = 0; i < plans.length; i++)
                    _buildPlanCard(plans[i], i == _selectedPlanIndex, () {
                      setState(() => _selectedPlanIndex = i);
                    }),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // NÚT HÀNH ĐỘNG CHÍNH
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B1E0F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                  ),
                  onPressed: _isLoading ? null : _handleSubscribe,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          selectedPlan.hasTrial
                              ? 'BẮT ĐẦU DÙNG THỬ 14 NGÀY MIỄN PHÍ'
                              : 'NÂNG CẤP GIA TỘC VIP (${selectedPlan.priceString})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Nút Kích hoạt Dùng thử Trực tiếp (Dành cho kiểm thử & trải nghiệm ngay)
            TextButton.icon(
              icon: const Icon(Icons.flash_on, size: 16, color: Color(0xFFD4AF37)),
              label: Text(
                isVip ? 'Gia hạn thêm 14 ngày dùng thử (Test)' : 'Kích hoạt nhanh 14 ngày dùng thử ngay bây giờ',
                style: const TextStyle(fontSize: 12, color: Color(0xFF8B1E0F), fontWeight: FontWeight.w600),
              ),
              onPressed: _activateTrialImmediately,
            ),

            if (isVip)
              TextButton(
                onPressed: _cancelVip,
                child: const Text('Hủy Gói VIP / Trở Về Bản Miễn Phí', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),

            const SizedBox(height: 16),

            // ĐIỀU KHOẢN VÀ BẢO ĐẢM STORE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '• Gói tháng (10.000 đ) và Gói năm (99.000 đ) đi kèm 14 ngày dùng thử miễn phí.\n'
                '• Bạn có thể hủy gói bất kỳ lúc nào trong Cài đặt tài khoản Google Play / Apple ID trước khi kết thúc thời gian dùng thử mà không bị trừ tiền.\n'
                '• Dữ liệu gia phả luôn được bảo toàn trọn vẹn và an toàn.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitRow({
    required String title,
    required String freeDesc,
    required String vipDesc,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF8B1E0F).withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF8B1E0F), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('VIP: ', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 12)),
                  Expanded(
                    child: Text(vipDesc, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF2E7D32))),
                  ),
                ],
              ),
              Text('Miễn phí: $freeDesc', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B1E0F).withOpacity(0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF8B1E0F) : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? const Color(0xFF8B1E0F) : Colors.grey,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(plan.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      if (plan.badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            plan.badge!,
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(plan.description, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  plan.priceString,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF8B1E0F)),
                ),
                Text(plan.periodString, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubscribe() async {
    final plans = SubscriptionService.availablePlans;
    final selectedPlan = plans[_selectedPlanIndex];

    setState(() => _isLoading = true);

    try {
      final updated = await SubscriptionService().subscribePlan(
        plan: selectedPlan,
        currentProfile: widget.profile,
        storageService: widget.storageService,
      );

      widget.onProfileUpdated(updated);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1B5E20),
            content: Text('Chúc mừng bạn đã kích hoạt ${selectedPlan.title}!'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi kích hoạt: $e')),
        );
      }
    }
  }

  Future<void> _activateTrialImmediately() async {
    setState(() => _isLoading = true);
    final updated = await SubscriptionService().activateFreeTrial(
      widget.profile,
      widget.storageService,
    );
    widget.onProfileUpdated(updated);
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF1B5E20),
          content: Text('Đã kích hoạt 14 ngày dùng thử Gia Tộc VIP miễn phí!'),
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _cancelVip() async {
    final updated = await SubscriptionService().cancelSubscription(
      widget.profile,
      widget.storageService,
    );
    widget.onProfileUpdated(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã trở về tài khoản Miễn phí.')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);
    final updated = await SubscriptionService().restorePurchases(
      widget.profile,
      widget.storageService,
    );
    widget.onProfileUpdated(updated);
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã kiểm tra và đồng bộ trạng thái gói mua từ Store.')),
      );
    }
  }
}
