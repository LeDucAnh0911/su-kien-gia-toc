/// Màn hình Cài Đặt & Sao Lưu / Phục Hồi Dữ Liệu
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/event_model.dart';
import '../models/note_model.dart';
import '../models/family_person.dart';
import 'dart:math';
import '../services/storage_service.dart';
import '../services/backup_file_service.dart';
import '../services/firebase_sync_service.dart';
import '../services/event_reminder_service.dart';
import 'offerings_guide_screen.dart';
import 'paywall_screen.dart';

class SettingsScreen extends StatefulWidget {
  final UserProfile profile;
  final List<EventItem> events;
  final List<DailyNoteItem> notes;
  final List<FamilyPerson> familyPeople;
  final StorageService storageService;
  final Function(UserProfile) onProfileUpdated;
  final Function(List<EventItem>, List<DailyNoteItem>, List<FamilyPerson>) onDataRestored;

  const SettingsScreen({
    super.key,
    required this.profile,
    required this.events,
    required this.notes,
    required this.familyPeople,
    required this.storageService,
    required this.onProfileUpdated,
    required this.onDataRestored,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _giaChuController;
  late TextEditingController _diaChiController;
  late TextEditingController _syncCodeController;

  String? _googleUserEmail;
  String? _googleUserName;
  DateTime? _lastSyncTime;
  bool _isSyncing = false;
  String _userRole = 'admin'; // 'admin' (Trưởng họ) hoặc 'member' (Con cháu)

  bool _remindersEnabled = true;
  int _remindAdvanceDays = 3;
  bool _remindTienThuong = true;
  bool _remindChinhKy = true;

  @override
  void initState() {
    super.initState();
    _giaChuController = TextEditingController(text: widget.profile.giaChu);
    _diaChiController = TextEditingController(text: widget.profile.diaChi);
    _syncCodeController = TextEditingController();
    _loadSyncState();
  }

  Future<void> _loadSyncState() async {
    final code = await widget.storageService.loadFamilySyncCode();
    final lastTime = await widget.storageService.loadLastSyncTime();
    final role = await widget.storageService.loadUserRole();
    final user = FirebaseSyncService().currentUser;
    await EventReminderService().loadSettings();
    final rem = EventReminderService().settings;
    if (mounted) {
      setState(() {
        _syncCodeController.text = (code != null && code.isNotEmpty) ? code : 'LE-GIA-TOC-2026';
        _lastSyncTime = lastTime;
        _userRole = role;
        _remindersEnabled = rem.enabled;
        _remindAdvanceDays = rem.advanceDays;
        _remindTienThuong = rem.remindTienThuong;
        _remindChinhKy = rem.remindChinhKy;
        if (user != null) {
          _googleUserEmail = user.email;
          _googleUserName = user.displayName;
        }
      });
    }
  }

  void _saveReminderSettings() {
    final next = ReminderSettings(
      enabled: _remindersEnabled,
      advanceDays: _remindAdvanceDays,
      remindTienThuong: _remindTienThuong,
      remindChinhKy: _remindChinhKy,
    );
    EventReminderService().saveSettings(next);
  }

  @override
  void dispose() {
    _giaChuController.dispose();
    _diaChiController.dispose();
    _syncCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài Đặt & Dữ Liệu'),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFF8B2500),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // BANNER GIA TỘC VIP (HỘI VIÊN HOÀNG KIM)
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => PaywallScreen(
                    profile: widget.profile,
                    storageService: widget.storageService,
                    onProfileUpdated: widget.onProfileUpdated,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.profile.isEffectivelyPremium
                      ? [const Color(0xFF8B1E0F), const Color(0xFF5D1006)]
                      : [const Color(0xFFD4AF37), const Color(0xFFAA7C11)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    child: Icon(
                      widget.profile.isEffectivelyPremium
                          ? Icons.workspace_premium
                          : Icons.stars_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.profile.isEffectivelyPremium
                              ? 'HỘI VIÊN GIA TỘC VIP'
                              : 'NÂNG CẤP GIA TỘC VIP (10k/Tháng)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.profile.isEffectivelyPremium
                              ? (widget.profile.premiumTier == 'trial'
                                  ? 'Đang dùng thử 14 ngày miễn phí'
                                  : 'Đã mở khóa toàn bộ tính năng cao cấp')
                              : 'Dùng thử 14 ngày • Mở khóa gia phả vô hạn & đám mây',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // MỤC 1: THÔNG TIN GIA CHỦ
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.person_pin, color: Color(0xFF8B2500)),
                      SizedBox(width: 8),
                      Text('Thông Tin Gia Chủ (Tự Điền Văn Khấn)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _giaChuController,
                    decoration: const InputDecoration(
                      labelText: 'Họ tên Gia chủ / Tín chủ',
                      hintText: 'VD: Lê Đức Anh',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => _saveProfileChanges(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _diaChiController,
                    decoration: const InputDecoration(
                      labelText: 'Nơi cư ngụ (Địa chỉ nhà)',
                      hintText: 'VD: Số 12, Đường Trần Phú, TP Hà Tĩnh',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => _saveProfileChanges(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // MỤC 2: XUẤT SỰ KIỆN GIA TỘC (GỬI ZALO / IN ẤN)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.print_outlined, color: Color(0xFF8B1E0F)),
                      SizedBox(width: 8),
                      Text('Xuất Sự Kiện Gia Tộc (Gửi Zalo / In Ấn)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tổng hợp toàn bộ danh sách sự kiện, ngày giỗ, sinh nhật trong năm theo thứ tự tháng Âm lịch, tạo bản tin trang trọng để chia sẻ vào nhóm Zalo dòng họ hoặc in ra lưu giữ.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B1E0F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Xem & Sao Chép Sự Kiện Gửi Zalo', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _showExportFamilyBookDialog,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green.shade800,
                          side: BorderSide(color: Colors.green.shade600),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        icon: const Icon(Icons.table_chart_outlined, size: 16),
                        label: const Text('Xuất Excel Sự Kiện (.CSV)'),
                        onPressed: () async {
                          final ok = await BackupFileService.exportEventsCsv(
                            context: context,
                            events: widget.events,
                          );
                          if (ok && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã xuất danh sách Sự Kiện ra file Excel thành công!'),
                                backgroundColor: Color(0xFF2E7D32),
                              ),
                            );
                          }
                        },
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.teal.shade800,
                          side: BorderSide(color: Colors.teal.shade600),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        icon: const Icon(Icons.people_alt_outlined, size: 16),
                        label: const Text('Xuất Excel Gia Phả (.CSV)'),
                        onPressed: () async {
                          final ok = await BackupFileService.exportFamilyCsv(
                            context: context,
                            people: widget.familyPeople,
                          );
                          if (ok && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã xuất danh sách Gia Phả ra file Excel thành công!'),
                                backgroundColor: Color(0xFF00695C),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // MỤC 2B: CẨM NANG MÂM CỖ & SẮM LỄ
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.restaurant_menu, color: Color(0xFFD4AF37)),
                      SizedBox(width: 8),
                      Text('Cẩm Nang Sắm Lễ & Mâm Cỗ Truyền Thống', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tra cứu danh mục lễ vật dâng hương gia tiên, thực đơn mâm cỗ mặn, mâm cỗ chay thanh tịnh và tạo danh sách đi chợ sắm sửa gửi Zalo.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    icon: const Icon(Icons.menu_book, size: 18),
                    label: const Text('Mở Cẩm Nang & Checklist Sắm Lễ', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => const OfferingsGuideScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // MỤC 2C: CÀI ĐẶT NHẮC NHỞ & THÔNG BÁO TỰ ĐỘNG
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications_active_outlined, color: Colors.deepOrange),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Thông Báo & Nhắc Nhở Tự Động', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      Switch(
                        value: _remindersEnabled,
                        activeColor: const Color(0xFF8B1E0F),
                        onChanged: (val) {
                          setState(() => _remindersEnabled = val);
                          _saveReminderSettings();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tự động báo chuông trước ngày giỗ và ngày sinh nhật để gia đình chủ động chuẩn bị chu đáo.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  if (_remindersEnabled) ...[
                    const Divider(height: 24),
                    const Text('Thời gian nhắc nhở trước:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [1, 3, 7].map((days) {
                        final isSel = _remindAdvanceDays == days;
                        return ChoiceChip(
                          label: Text('Trước $days ngày'),
                          selected: isSel,
                          selectedColor: const Color(0xFF8B1E0F).withOpacity(0.15),
                          labelStyle: TextStyle(
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            color: isSel ? const Color(0xFF8B1E0F) : null,
                          ),
                          onSelected: (_) {
                            setState(() => _remindAdvanceDays = days);
                            _saveReminderSettings();
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: const Color(0xFF8B1E0F),
                      title: const Text('Nhắc chiều trước ngày giỗ (Lễ Tiên Thường)', style: TextStyle(fontSize: 13.5)),
                      subtitle: const Text('Nhắc thắp hương mời tiên tổ chiều hôm trước', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      value: _remindTienThuong,
                      onChanged: (val) {
                        setState(() => _remindTienThuong = val ?? true);
                        _saveReminderSettings();
                      },
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: const Color(0xFF8B1E0F),
                      title: const Text('Nhắc đúng sáng ngày diễn ra (Lễ Chính Kỵ)', style: TextStyle(fontSize: 13.5)),
                      subtitle: const Text('Nhắc làm mâm cúng sáng ngày giỗ / chúc mừng sinh nhật', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      value: _remindChinhKy,
                      onChanged: (val) {
                        setState(() => _remindChinhKy = val ?? true);
                        _saveReminderSettings();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // MỤC 3: SAO LƯU & PHỤC HỒI QUA TỆP (.JSON)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.folder_zip_outlined, color: Colors.teal),
                      SizedBox(width: 8),
                      Text('Sao Lưu & Phục Hồi Dữ Liệu (.json)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hiện có ${widget.events.length} sự kiện, ${widget.notes.length} ghi chú và ${widget.familyPeople.length} người trong gia phả. Xuất ra tệp .json để lưu trữ hoặc nạp sang máy khác nhanh chóng, tiện lợi.',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B5E20),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.file_download_outlined, size: 20),
                          label: const Text('Xuất Tệp .json', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: _exportBackupFile,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D47A1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.file_upload_outlined, size: 20),
                          label: const Text('Chọn Tệp Nạp', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: _importBackupFile,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.code, size: 16, color: Colors.blueGrey),
                      label: const Text('Tùy chọn: Sao chép / Dán mã JSON thủ công', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          builder: (ctx) => SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Sao Lưu / Phục Hồi Bằng Mã Văn Bản', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 12),
                                  ListTile(
                                    leading: const Icon(Icons.copy_all, color: Colors.teal),
                                    title: const Text('Xem & Sao chép mã JSON'),
                                    subtitle: const Text('Dành cho máy không hỗ trợ tải tệp'),
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      _showBackupDialog();
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.paste, color: Colors.blue),
                                    title: const Text('Dán mã JSON để phục hồi'),
                                    subtitle: const Text('Dán nội dung sao lưu từ bộ nhớ tạm'),
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      _showRestoreDialog();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // MỤC 4: ĐỒNG BỘ ĐÁM MÂY (GOOGLE CLOUD & FIREBASE)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cloud_sync, color: Colors.indigo),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Đồng Bộ Đám Mây (Google Cloud)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _googleUserEmail != null
                              ? Colors.green.withOpacity(0.12)
                              : Colors.orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _googleUserEmail != null ? Colors.green : Colors.orange,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          _googleUserEmail != null ? 'Đã liên kết' : 'Ngoại tuyến',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _googleUserEmail != null ? Colors.green.shade800 : Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _googleUserEmail != null
                        ? 'Tài khoản Google: $_googleUserEmail\nĐang đồng bộ cho dòng họ theo Mã kết nối gia đình bên dưới.'
                        : 'Dữ liệu đang được lưu an toàn trên máy. Đăng nhập tài khoản Google để tự động đồng bộ giữa máy tính và điện thoại của vợ/chồng hoặc người thân.',
                    style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
                  ),
                  const SizedBox(height: 14),

                  // Nút Đăng nhập Google hoặc Thông tin tài khoản
                  if (_googleUserEmail == null)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.indigo.shade800,
                        side: BorderSide(color: Colors.indigo.shade300),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.account_circle_outlined, size: 20),
                      label: const Text('Đăng Nhập Bằng Google Để Đồng Bộ', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: _signInWithGoogle,
                    )
                  else
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.indigo.shade100,
                          child: Text(
                            (_googleUserName?.isNotEmpty == true ? _googleUserName![0] : 'G').toUpperCase(),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _googleUserName ?? _googleUserEmail!,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: _signOutGoogle,
                          child: const Text('Đăng Xuất', style: TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                      ],
                    ),

                  const Divider(height: 24),

                  // Mã kết nối gia đình (Family Sync Code)
                  Row(
                    children: const [
                      Icon(Icons.vpn_key_outlined, size: 18, color: Colors.indigo),
                      SizedBox(width: 6),
                      Text('Mã Kết Nối Gia Tộc (Family Sync Code):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Dùng chung mã này trên máy của Vợ/Chồng để cả hai máy cùng kết nối vào một cây gia phả.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _syncCodeController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: 'VD: LE-GIA-TOC-2026',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.copy, size: 18),
                              tooltip: 'Sao chép mã gửi cho Vợ/Chồng',
                              onPressed: () {
                                final code = _syncCodeController.text.trim();
                                if (code.isNotEmpty) {
                                  Clipboard.setData(ClipboardData(text: code));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Đã sao chép mã "$code"! Hãy gửi cho vợ/chồng.')),
                                  );
                                }
                              },
                            ),
                          ),
                          onChanged: (val) {
                            widget.storageService.saveFamilySyncCode(val.trim().toUpperCase());
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _generateRandomSyncCode,
                        child: const Text('Tạo Mã Mới'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF8B1E0F),
                        side: const BorderSide(color: Color(0xFF8B1E0F)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('Sao Chép Lời Mời Gia Tộc Gửi Zalo', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: _shareFamilyInvite,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Phân quyền vai trò trong dòng họ
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.indigo.shade50.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.indigo.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.shield_outlined, size: 18, color: Colors.indigo),
                            const SizedBox(width: 6),
                            const Text('Vai Trò Trong Họ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _userRole == 'admin' ? const Color(0xFF8B1E0F) : Colors.teal,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _userRole == 'admin' ? 'Trưởng họ (Toàn quyền)' : 'Con cháu (Xem an toàn)',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _userRole == 'admin'
                              ? 'Bạn có toàn quyền chỉnh sửa gia phả, thêm sự kiện và tải lên đám mây.'
                              : 'Chế độ xem an toàn giúp bảo vệ dữ liệu gia tộc, tránh vô tình sửa đổi.',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: _userRole == 'admin' ? const Color(0xFF8B1E0F) : null,
                                  foregroundColor: _userRole == 'admin' ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                  side: BorderSide(color: _userRole == 'admin' ? const Color(0xFF8B1E0F) : Colors.grey.shade400),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () {
                                  setState(() => _userRole = 'admin');
                                  widget.storageService.saveUserRole('admin');
                                },
                                child: const Text('Trưởng họ (Admin)'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: _userRole == 'member' ? Colors.teal : null,
                                  foregroundColor: _userRole == 'member' ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                  side: BorderSide(color: _userRole == 'member' ? Colors.teal : Colors.grey.shade400),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () {
                                  setState(() => _userRole = 'member');
                                  widget.storageService.saveUserRole('member');
                                },
                                child: const Text('Con cháu (Thành viên)'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Cấu hình Firebase & Hướng dẫn Google Cloud
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          icon: const Icon(Icons.settings_suggest_outlined, size: 16),
                          label: const Text('Cấu Hình Khóa Firebase Riêng', style: TextStyle(fontSize: 12)),
                          onPressed: _showCustomFirebaseDialog,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.help_outline, size: 16, color: Colors.blue),
                        label: const Text('Hướng Dẫn', style: TextStyle(fontSize: 12, color: Colors.blue)),
                        onPressed: _showFirebaseGuideDialog,
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Hai nút Tải lên & Kéo về đám mây
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: _isSyncing
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.cloud_upload_outlined, size: 18),
                          label: const Text('Tải Lên Đám Mây', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: _isSyncing ? null : _uploadToCloud,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: _isSyncing
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.cloud_download_outlined, size: 18),
                          label: const Text('Kéo Về Từ Đám Mây', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: _isSyncing ? null : _downloadFromCloud,
                        ),
                      ),
                    ],
                  ),

                  if (_lastSyncTime != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Lần đồng bộ gần nhất: ${_lastSyncTime!.hour.toString().padLeft(2, '0')}:${_lastSyncTime!.minute.toString().padLeft(2, '0')} ngày ${_lastSyncTime!.day}/${_lastSyncTime!.month}/${_lastSyncTime!.year}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // MỤC 5: GIỚI THIỆU
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.info_outline, color: Colors.blueGrey),
                      SizedBox(width: 8),
                      Text('Giới Thiệu Ứng Dụng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Sự Kiện Gia Tộc\n'
                    'Phiên bản 1.3.0 (Gia phả & Lịch âm dương)\n\n'
                    '• Thuật toán Âm Lịch Việt Nam chuẩn GMT+7 (TS. Hồ Ngọc Đức)\n'
                    '• Tính Giờ Hoàng Đạo, Can Chi, Tiết Khí 24 tiết\n'
                    '• Bố cục tương thích cả Máy Tính (Desktop) và Điện Thoại (Mobile)\n'
                    '• Tích hợp Ghi Chú & Nhắc Việc theo ngày Âm/Dương trực tiếp trên lịch\n'
                    '• Tự động xử lý Tháng thiếu 29 ngày & Tháng nhuận\n'
                    '• Nhắc nhở Lễ Tiên Thường (chiều trước) và Lễ Chính Kỵ (đúng ngày)\n'
                    '• Kho Văn Khấn Cổ Truyền tự điền tên Gia chủ, Tín chủ, Địa chỉ\n'
                    '• Gia phả nội ngoại và quan hệ các thế hệ',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExportFamilyBookDialog() {
    final sortedEvents = List<EventItem>.from(widget.events)
      ..sort((a, b) {
        if (a.month != b.month) return a.month.compareTo(b.month);
        return a.day.compareTo(b.day);
      });

    final buffer = StringBuffer();
    buffer.writeln('====================================');
    buffer.writeln('       SỰ KIỆN GIA TỘC VIỆT NAM');
    if (widget.profile.giaChu.isNotEmpty) {
      buffer.writeln('  Gia chủ: ${widget.profile.giaChu}');
    }
    if (widget.profile.diaChi.isNotEmpty) {
      buffer.writeln('  Địa chỉ: ${widget.profile.diaChi}');
    }
    buffer.writeln('====================================\n');

    for (int i = 0; i < sortedEvents.length; i++) {
      final ev = sortedEvents[i];
      buffer.writeln('${i + 1}. ${ev.title}');
      buffer.writeln('   • Ngày Âm lịch: Ngày ${ev.day} tháng ${ev.month} Âm');
      if (ev.personName != null && ev.personName!.isNotEmpty) {
        buffer.writeln('   • Người được tưởng nhớ: ${ev.personName} (${ev.relation ?? ""})');
      }
      if (ev.year != null) {
        buffer.writeln('   • Năm: ${ev.year}');
      }
      if (ev.restingPlace != null && ev.restingPlace!.isNotEmpty) {
        buffer.writeln('   • Nơi an nghỉ: ${ev.restingPlace}');
      }
      if (ev.notes != null && ev.notes!.isNotEmpty) {
        buffer.writeln('   • Ghi chú: ${ev.notes}');
      }
      buffer.writeln('');
    }
    buffer.writeln('\"Uống nước nhớ nguồn - Chim có tổ người có tông\"');

    final text = buffer.toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sự Kiện Gia Tộc Trong Năm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nội dung tổng hợp có thể sao chép để gửi vào nhóm Zalo gia đình:'),
            const SizedBox(height: 10),
            Container(
              height: 220,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black12),
              ),
              child: SingleChildScrollView(
                child: SelectableText(text, style: const TextStyle(fontSize: 12, height: 1.4)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Sao Chép Bản Tin Zalo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B1E0F),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã sao chép Sự Kiện Gia Tộc! Bạn có thể dán vào Zalo ngay.')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _saveProfileChanges() {
    final updated = UserProfile(
      giaChu: _giaChuController.text.trim(),
      diaChi: _diaChiController.text.trim(),
      prayerFontSize: widget.profile.prayerFontSize,
      isDarkMode: widget.profile.isDarkMode,
    );
    widget.onProfileUpdated(updated);
  }

  void _showBackupDialog() async {
    final jsonStr = await widget.storageService.exportBackupData(
      widget.events,
      widget.notes,
      widget.profile,
      widget.familyPeople,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sao Lưu Dữ Liệu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bản sao lưu JSON gồm sự kiện, ghi chú và gia phả:'),
            const SizedBox(height: 10),
            Container(
              height: 160,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: SelectableText(jsonStr, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Sao Chép Tất Cả'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonStr));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã sao chép dữ liệu sao lưu vào bộ nhớ tạm!')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showRestoreDialog() {
    final restoreController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Phục Hồi Dữ Liệu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Dán mã dữ liệu sao lưu JSON của bạn vào đây:'),
            const SizedBox(height: 10),
            TextField(
              controller: restoreController,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Dán nội dung JSON sao lưu vào đây...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              final text = restoreController.text.trim();
              if (text.isNotEmpty) {
                try {
                  final data = widget.storageService.parseBackupData(text);
                  final List<EventItem> restoredEvents = data['events'] ?? [];
                  final List<DailyNoteItem> restoredNotes = data['notes'] ?? [];
                  final List<FamilyPerson> restoredFamily = data['hasFamilyPeople'] == true
                      ? (data['familyPeople'] as List<FamilyPerson>) : widget.familyPeople;

                  await widget.storageService.saveEvents(restoredEvents);
                  await widget.storageService.saveNotes(restoredNotes);
                  if (data['hasFamilyPeople'] == true) {
                    await widget.storageService.saveFamilyPeople(restoredFamily);
                  }

                  widget.onDataRestored(restoredEvents, restoredNotes, restoredFamily);
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Đã phục hồi ${restoredEvents.length} sự kiện, ${restoredNotes.length} ghi chú và ${restoredFamily.length} người trong gia phả!',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mã sao lưu không hợp lệ! Vui lòng kiểm tra lại.')),
                    );
                  }
                }
              }
            },
            child: const Text('Bắt Đầu Phục Hồi'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackupFile() async {
    try {
      final jsonStr = await widget.storageService.exportBackupData(
        widget.events,
        widget.notes,
        widget.profile,
        widget.familyPeople,
      );

      if (!mounted) return;

      final success = await BackupFileService.exportBackupFile(
        context: context,
        jsonContent: jsonStr,
      );

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF1B5E20),
            content: Text('Đã xuất tệp sao lưu .json thành công!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade800,
            content: Text('Lỗi khi xuất tệp: $e'),
          ),
        );
      }
    }
  }

  Future<void> _importBackupFile() async {
    try {
      final jsonStr = await BackupFileService.pickAndReadBackupFile();
      if (!mounted || jsonStr == null || jsonStr.trim().isEmpty) return;

      final data = widget.storageService.parseBackupData(jsonStr);
      final List<EventItem> restoredEvents = data['events'] ?? [];
      final List<DailyNoteItem> restoredNotes = data['notes'] ?? [];
      final List<FamilyPerson> restoredFamily = data['hasFamilyPeople'] == true
          ? (data['familyPeople'] as List<FamilyPerson>)
          : widget.familyPeople;
      final UserProfile? restoredProfile = data['profile'];

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.file_upload, color: Color(0xFF0D47A1)),
              SizedBox(width: 8),
              Text('Xác Nhận Nạp Tệp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tệp sao lưu hợp lệ! Dữ liệu đọc được gồm:'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• 📅 Sự kiện / Ngày giỗ: ${restoredEvents.length} mục', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('• 📝 Ghi chú: ${restoredNotes.length} mục', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('• 🌳 Thành viên gia phả: ${restoredFamily.length} người', style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (restoredProfile != null && restoredProfile.giaChu.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('• 👤 Gia chủ: ${restoredProfile.giaChu}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Lưu ý: Dữ liệu hiện tại trên thiết bị sẽ được cập nhật đồng bộ theo tệp sao lưu này.',
                style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await widget.storageService.saveEvents(restoredEvents);
                await widget.storageService.saveNotes(restoredNotes);
                if (data['hasFamilyPeople'] == true) {
                  await widget.storageService.saveFamilyPeople(restoredFamily);
                }
                if (restoredProfile != null) {
                  await widget.storageService.saveProfile(restoredProfile);
                  widget.onProfileUpdated(restoredProfile);
                  _giaChuController.text = restoredProfile.giaChu;
                  _diaChiController.text = restoredProfile.diaChi;
                }

                widget.onDataRestored(restoredEvents, restoredNotes, restoredFamily);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF1B5E20),
                      content: Text(
                        'Đã nạp thành công ${restoredEvents.length} sự kiện, ${restoredNotes.length} ghi chú và ${restoredFamily.length} người gia phả!',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Đồng Ý Nạp'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade800,
            content: Text('Lỗi: Tệp sao lưu không đúng định dạng! ($e)'),
          ),
        );
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final user = await FirebaseSyncService().signInWithGoogle();
      if (user != null && mounted) {
        setState(() {
          _googleUserEmail = user.email;
          _googleUserName = user.displayName;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.indigo.shade800,
            content: Text('Đã kết nối tài khoản Google: ${user.email}'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      // Nếu Firebase chưa được trỏ Google Client ID trên Cloud (môi trường local/offline)
      // Cho phép người dùng chuyển sang chế độ Thử nghiệm tài khoản
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.info_outline, color: Colors.indigo),
              SizedBox(width: 8),
              Text('Kết Nối Google Cloud', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ứng dụng đã sẵn sàng kiến trúc Firebase Authentication & Cloud Firestore.\n\n'
                '• Khi triển khai Web/App chính thức: Cần cấu hình OAuth 2.0 Client ID trên Google Cloud Console.\n'
                '• Bạn có muốn kích hoạt chế độ Tài khoản Mẫu để thử nghiệm đồng bộ ngay không?',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Chi tiết kỹ thuật: $e',
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.blueGrey),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  _googleUserEmail = 'leducanh.vnpost@gmail.com';
                  _googleUserName = widget.profile.giaChu.isNotEmpty ? widget.profile.giaChu : 'Lê Đức Anh';
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.indigo,
                    content: Text('Đã kết nối tài khoản Google: leducanh.vnpost@gmail.com (Chế độ sẵn sàng)'),
                  ),
                );
              },
              child: const Text('Bật Chế Độ Thử Nghiệm', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _signOutGoogle() async {
    await FirebaseSyncService().signOut();
    if (mounted) {
      setState(() {
        _googleUserEmail = null;
        _googleUserName = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã đăng xuất tài khoản Google.')),
      );
    }
  }

  void _generateRandomSyncCode() {
    final rand = Random().nextInt(9000) + 1000;
    final code = 'LE-GIA-TOC-$rand';
    setState(() {
      _syncCodeController.text = code;
    });
    widget.storageService.saveFamilySyncCode(code);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã tạo mã kết nối mới: $code')),
    );
  }

  Future<void> _uploadToCloud() async {
    final code = _syncCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập Mã kết nối gia đình trước khi tải lên.')),
      );
      return;
    }

    setState(() => _isSyncing = true);

    final res = await FirebaseSyncService().uploadFamilyData(
      familySyncCode: code,
      events: widget.events,
      notes: widget.notes,
      familyPeople: widget.familyPeople,
      profile: widget.profile,
    );

    if (mounted) {
      setState(() {
        _isSyncing = false;
        if (res.success) {
          _lastSyncTime = DateTime.now();
        }
      });

      if (res.success) {
        await widget.storageService.saveLastSyncTime(_lastSyncTime!);
        await widget.storageService.saveFamilySyncCode(code);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.indigo.shade800,
            content: Text('Đã đồng bộ lên đám mây thành công cho mã "$code"!'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.orange.shade900,
            content: Text(res.message),
          ),
        );
      }
    }
  }

  Future<void> _downloadFromCloud() async {
    final code = _syncCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập Mã kết nối gia đình cần kéo dữ liệu.')),
      );
      return;
    }

    setState(() => _isSyncing = true);

    final res = await FirebaseSyncService().downloadFamilyData(code);

    if (!mounted) return;

    setState(() => _isSyncing = false);

    if (!res.success || res.data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange.shade900,
          content: Text(res.message),
        ),
      );
      return;
    }

    final data = res.data!;
    final List<EventItem> restoredEvents = data['events'] ?? [];
    final List<DailyNoteItem> restoredNotes = data['notes'] ?? [];
    final List<FamilyPerson> restoredFamily = data['familyPeople'] ?? [];
    final UserProfile? restoredProfile = data['profile'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.cloud_download, color: Colors.teal),
            SizedBox(width: 8),
            Text('Đồng Bộ Từ Đám Mây', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Đã tìm thấy dữ liệu đám mây cho mã "$code":'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• 📅 Sự kiện / Ngày giỗ: ${restoredEvents.length} mục', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('• 📝 Ghi chú: ${restoredNotes.length} mục', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('• 🌳 Thành viên gia phả: ${restoredFamily.length} người', style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (restoredProfile != null && restoredProfile.giaChu.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('• 👤 Gia chủ: ${restoredProfile.giaChu}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Cập nhật dữ liệu thiết bị theo bản ghi mới nhất từ người thân trên đám mây?',
              style: TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await widget.storageService.saveEvents(restoredEvents);
              await widget.storageService.saveNotes(restoredNotes);
              await widget.storageService.saveFamilyPeople(restoredFamily);
              if (restoredProfile != null) {
                await widget.storageService.saveProfile(restoredProfile);
                widget.onProfileUpdated(restoredProfile);
                _giaChuController.text = restoredProfile.giaChu;
                _diaChiController.text = restoredProfile.diaChi;
              }

              _lastSyncTime = DateTime.now();
              await widget.storageService.saveLastSyncTime(_lastSyncTime!);
              await widget.storageService.saveFamilySyncCode(code);

              widget.onDataRestored(restoredEvents, restoredNotes, restoredFamily);

              if (mounted) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF1B5E20),
                    content: Text(
                      'Đã cập nhật ${restoredEvents.length} sự kiện và ${restoredFamily.length} người gia phả từ đám mây!',
                    ),
                  ),
                );
              }
            },
            child: const Text('Đồng Ý Kéo Về'),
          ),
        ],
      ),
    );
  }

  void _shareFamilyInvite() {
    final code = _syncCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập Mã kết nối gia tộc trước khi chia sẻ.')),
      );
      return;
    }
    final inviteText = 'Kính gửi bà con dòng họ!\n\n'
        'Mời mọi người cùng tham gia xem Cây Gia Phả & Lịch Giỗ trực tuyến của dòng họ ta:\n'
        '👉 Mở ứng dụng ngay: https://leducanh0911.github.io/su-kien-gia-toc/?family=$code\n'
        '🔑 Mã kết nối gia tộc: $code\n\n'
        'Bà con chỉ cần bấm vào liên kết trên để xem toàn bộ phả hệ các đời và nhận thông báo các ngày giỗ trong năm!';
    Clipboard.setData(ClipboardData(text: inviteText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép Lời Mời Gia Tộc kèm link! Hãy dán vào nhóm Zalo dòng họ.'),
        backgroundColor: Color(0xFF8B1E0F),
      ),
    );
  }

  void _showCustomFirebaseDialog() async {
    final currentConfig = await widget.storageService.loadCustomFirebaseConfig();
    final apiKeyCtrl = TextEditingController(text: currentConfig?['apiKey'] ?? '');
    final projectIdCtrl = TextEditingController(text: currentConfig?['projectId'] ?? '');
    final appIdCtrl = TextEditingController(text: currentConfig?['appId'] ?? '');

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.cloud_circle_outlined, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Cấu Hình Firebase Riêng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nhập thông số dự án Firebase / Google Cloud của bạn để đồng bộ dữ liệu vào đám mây riêng của gia đình:',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: apiKeyCtrl,
                decoration: const InputDecoration(
                  labelText: 'API Key (apiKey)',
                  hintText: 'VD: AIzaSy...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: projectIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'Project ID (projectId)',
                  hintText: 'VD: su-kien-gia-toc',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: appIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'App ID (appId - Tùy chọn)',
                  hintText: 'VD: 1:123456789:web:...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            onPressed: () async {
              final apiKey = apiKeyCtrl.text.trim();
              final projectId = projectIdCtrl.text.trim();
              if (apiKey.isEmpty || projectId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập tối thiểu API Key và Project ID.')),
                );
                return;
              }
              Navigator.pop(ctx);
              final cfg = {
                'apiKey': apiKey,
                'projectId': projectId,
                'appId': appIdCtrl.text.trim(),
              };
              await FirebaseSyncService().reinitializeWithCustomConfig(cfg);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã cập nhật cấu hình Firebase dự án của bạn thành công!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Lưu & Áp Dụng'),
          ),
        ],
      ),
    );
  }

  void _showFirebaseGuideDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.menu_book_outlined, color: Color(0xFF8B1E0F)),
            SizedBox(width: 8),
            Text('Hướng Dẫn Google Cloud', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '3 Bước Đơn Giản Để Đám Mây Hoạt Động Vĩnh Viễn Không Bị Hết Hạn:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF8B1E0F)),
              ),
              SizedBox(height: 12),
              Text(
                '1️⃣ Chuyển OAuth sang "In Production":\n'
                '• Vào Google Cloud Console -> APIs & Services -> OAuth consent screen.\n'
                '• Tại mục "Publishing status", bấm nút "Publish App" -> Chọn "Confirm".\n'
                '• Token đăng nhập sẽ dùng vĩnh viễn không bao giờ hết hạn.',
                style: TextStyle(fontSize: 12.5, height: 1.4),
              ),
              SizedBox(height: 10),
              Text(
                '2️⃣ Mở Firestore Database vĩnh viễn:\n'
                '• Vào Firebase Console -> Firestore Database -> Thẻ "Rules".\n'
                '• Thay quy tắc thành: "allow read, write: if true;" để không bị tự khóa sau 30 ngày dùng thử.\n'
                '• Bấm "Publish".',
                style: TextStyle(fontSize: 12.5, height: 1.4),
              ),
              SizedBox(height: 10),
              Text(
                '3️⃣ Lấy API Key & Project ID:\n'
                '• Vào Firebase Console -> Project Settings (biểu tượng bánh răng) -> Cuộn xuống mục Your apps -> Web app.\n'
                '• Copy apiKey và projectId dán vào nút "Cấu Hình Khóa Firebase Riêng".',
                style: TextStyle(fontSize: 12.5, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B1E0F), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đã Hiểu'),
          ),
        ],
      ),
    );
  }
}
