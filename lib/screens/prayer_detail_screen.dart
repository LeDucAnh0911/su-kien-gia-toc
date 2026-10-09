/// Màn hình Chi tiết Văn Khấn & Hướng Dẫn Sắm Lễ
import 'package:flutter/material.dart';
import '../data/prayers_data.dart';
import '../lunar_engine.dart';
import '../services/storage_service.dart';

class PrayerDetailScreen extends StatefulWidget {
  final PrayerItem prayer;
  final UserProfile profile;
  final Function(UserProfile) onProfileUpdated;
  final String? defaultNguoiMat; // Nếu mở từ một ngày giỗ cụ thể
  final String? defaultQuanHe;
  final String? defaultNgayAm;

  const PrayerDetailScreen({
    super.key,
    required this.prayer,
    required this.profile,
    required this.onProfileUpdated,
    this.defaultNguoiMat,
    this.defaultQuanHe,
    this.defaultNgayAm,
  });

  @override
  State<PrayerDetailScreen> createState() => _PrayerDetailScreenState();
}

class _PrayerDetailScreenState extends State<PrayerDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late double _fontSize;
  late String _giaChu;
  late String _diaChi;
  late String _nguoiMat;
  late String _quanHe;

  // Ngày âm tự động tính theo hôm nay
  late String _todayLunarStr;
  late String _todayYearCanChi;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fontSize = widget.profile.prayerFontSize;
    _giaChu = widget.profile.giaChu;
    _diaChi = widget.profile.diaChi;
    _nguoiMat = widget.defaultNguoiMat ?? '';
    _quanHe = widget.defaultQuanHe ?? '';

    // Tính ngày âm hiện tại
    final now = DateTime.now();
    final lunar = VietnameseLunarEngine.solarToLunar(now.day, now.month, now.year);
    final canChiYear = VietnameseLunarEngine.getCanChiYear(lunar.year);
    final canChiDay = VietnameseLunarEngine.getCanChiDay(lunar.jd);

    _todayLunarStr = widget.defaultNgayAm ?? 'Ngày ${lunar.day} tháng ${lunar.month} năm $canChiYear ($canChiDay)';
    _todayYearCanChi = canChiYear;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final formattedContent = PrayersData.formatPrayerContent(
      template: widget.prayer.content,
      giaChu: _giaChu,
      diaChi: _diaChi,
      ngayAm: _todayLunarStr,
      namAm: _todayYearCanChi,
      ngayTienThuong: _todayLunarStr,
      ngayChinhKy: _todayLunarStr,
      thangAm: '${DateTime.now().month}',
      nguoiMat: _nguoiMat,
      quanHe: _quanHe,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.prayer.title),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFF8B2500),
        foregroundColor: Colors.white,
        actions: [
          // Nút giảm cỡ chữ
          IconButton(
            icon: const Icon(Icons.text_decrease),
            tooltip: 'Giảm cỡ chữ',
            onPressed: () {
              if (_fontSize > 14.0) {
                setState(() => _fontSize -= 2.0);
                _saveFontSize();
              }
            },
          ),
          // Nút tăng cỡ chữ
          IconButton(
            icon: const Icon(Icons.text_increase),
            tooltip: 'Tăng cỡ chữ',
            onPressed: () {
              if (_fontSize < 32.0) {
                setState(() => _fontSize += 2.0);
                _saveFontSize();
              }
            },
          ),
          // Nút điền nhanh thông tin
          IconButton(
            icon: const Icon(Icons.edit_note),
            tooltip: 'Điền thông tin vào bài khấn',
            onPressed: _showFillInfoDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.menu_book), text: 'Bài Văn Khấn'),
            Tab(icon: Icon(Icons.inventory_2), text: 'Sắm Lễ Vật'),
            Tab(icon: Icon(Icons.info_outline), text: 'Lưu Ý & Ý Nghĩa'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: BÀI VĂN KHẤN
          _buildPrayerTab(formattedContent, isDark),

          // TAB 2: SẮM LỄ VẬT
          _buildOfferingsTab(isDark),

          // TAB 3: Ý NGHĨA & LƯU Ý
          _buildNotesTab(isDark),
        ],
      ),
    );
  }

  Widget _buildPrayerTab(String content, bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF121212) : const Color(0xFFFFFBF0),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Banner thông tin đã điền
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5E6D3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? Colors.amber.withOpacity(0.3) : const Color(0xFFD4AF37),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.person, color: isDark ? Colors.amber : const Color(0xFF8B2500), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _giaChu.isNotEmpty
                        ? 'Tín chủ: $_giaChu • $_diaChi'
                        : 'Chưa điền tên gia chủ (Bấm nút cây bút ở góc trên để điền nhanh)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[300] : const Color(0xFF4A3525),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _showFillInfoDialog,
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  child: const Text('Sửa'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Nội dung văn khấn
          SelectableText(
            content,
            style: TextStyle(
              fontSize: _fontSize,
              height: 1.7,
              fontWeight: FontWeight.w500,
              fontFamily: 'serif',
              color: isDark ? const Color(0xFFF0E6D2) : const Color(0xFF2C1810),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildOfferingsTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFDF6E2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              const Icon(Icons.tips_and_updates, color: Colors.amber, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Lễ vật tùy tâm và tùy theo phong tục từng vùng miền. Quan trọng nhất là sự thanh tịnh và lòng thành kính.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[300] : const Color(0xFF4A3525),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Danh mục Lễ vật chuẩn bị:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...widget.prayer.offerings.map((offering) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: ListTile(
              leading: const Icon(Icons.check_circle_outline, color: Colors.green),
              title: Text(
                offering,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNotesTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.schedule, color: Colors.deepOrange),
                    SizedBox(width: 8),
                    Text(
                      'Thời điểm & Ý nghĩa',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  widget.prayer.occasion,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber),
                    SizedBox(width: 8),
                    Text(
                      'Phong tục & Kiêng kỵ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  widget.prayer.notes,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _saveFontSize() {
    final updated = UserProfile(
      giaChu: widget.profile.giaChu,
      diaChi: widget.profile.diaChi,
      prayerFontSize: _fontSize,
      isDarkMode: widget.profile.isDarkMode,
    );
    widget.onProfileUpdated(updated);
  }

  void _showFillInfoDialog() {
    final giaChuController = TextEditingController(text: _giaChu);
    final diaChiController = TextEditingController(text: _diaChi);
    final nguoiMatController = TextEditingController(text: _nguoiMat);
    final quanHeController = TextEditingController(text: _quanHe);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Điền thông tin vào bài khấn'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: giaChuController,
                decoration: const InputDecoration(
                  labelText: 'Tên Tín chủ / Gia chủ',
                  hintText: 'VD: Lê Đức Anh',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: diaChiController,
                decoration: const InputDecoration(
                  labelText: 'Nơi cư ngụ (Địa chỉ)',
                  hintText: 'VD: Khối phố 3, P. Trần Phú, TP Hà Tĩnh',
                ),
              ),
              if (widget.prayer.category == 'gio') ...[
                const SizedBox(height: 8),
                TextField(
                  controller: quanHeController,
                  decoration: const InputDecoration(
                    labelText: 'Quan hệ / Vai vế',
                    hintText: 'VD: Cụ Ông, Cụ Bà, Bác ruột...',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nguoiMatController,
                  decoration: const InputDecoration(
                    labelText: 'Tên người mất',
                    hintText: 'VD: Lê Văn Phúc',
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _giaChu = giaChuController.text.trim();
                _diaChi = diaChiController.text.trim();
                _nguoiMat = nguoiMatController.text.trim();
                _quanHe = quanHeController.text.trim();
              });
              final updated = UserProfile(
                giaChu: _giaChu,
                diaChi: _diaChi,
                prayerFontSize: _fontSize,
                isDarkMode: widget.profile.isDarkMode,
              );
              widget.onProfileUpdated(updated);
              Navigator.pop(ctx);
            },
            child: const Text('Áp dụng'),
          ),
        ],
      ),
    );
  }
}
