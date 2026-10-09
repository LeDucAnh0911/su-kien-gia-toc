/// Màn hình Danh mục Văn Khấn Cổ Truyền
import 'package:flutter/material.dart';
import '../data/prayers_data.dart';
import '../services/storage_service.dart';
import 'prayer_detail_screen.dart';

class PrayersScreen extends StatefulWidget {
  final UserProfile profile;
  final Function(UserProfile) onProfileUpdated;

  const PrayersScreen({
    super.key,
    required this.profile,
    required this.onProfileUpdated,
  });

  @override
  State<PrayersScreen> createState() => _PrayersScreenState();
}

class _PrayersScreenState extends State<PrayersScreen> {
  String _selectedCategory = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final Map<String, String> _categoryLabels = {
    'all': 'Tất cả',
    'gio': 'Ngày Giỗ',
    'tet': 'Tết Nguyên Đán',
    'ram_mung_mot': 'Rằm & Mùng 1',
    'le_tiet': 'Lễ Tiết Trong Năm',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Lọc danh sách bài cúng
    final filteredPrayers = PrayersData.allPrayers.where((item) {
      final matchCategory = _selectedCategory == 'all' || item.category == _selectedCategory;
      final matchSearch = _searchQuery.isEmpty ||
          item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.occasion.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCategory && matchSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kho Văn Khấn Cổ Truyền'),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFF8B2500),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_pin_outlined),
            tooltip: 'Cài đặt thông tin Gia chủ',
            onPressed: () => _showProfileDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header giới thiệu & Ô tìm kiếm
          Container(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFFAF0E6),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_stories, color: isDark ? Colors.amber : const Color(0xFF8B2500), size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Các bài văn khấn truyền thống theo phong tục Việt Nam, kèm gợi ý sắm lễ vật chu đáo.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[300] : const Color(0xFF4A3525),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm bài cúng: Tất niên, Ông Táo, Giỗ, Rằm...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ],
            ),
          ),

          // Bộ chọn danh mục (Chips)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: _categoryLabels.entries.map((entry) {
                final isSelected = _selectedCategory == entry.key;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    selectedColor: isDark ? Colors.amber.withOpacity(0.3) : const Color(0xFFFFDAB9),
                    checkmarkColor: isDark ? Colors.amber : const Color(0xFF8B2500),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? (isDark ? Colors.amber : const Color(0xFF8B2500))
                          : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = entry.key);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // Danh sách bài văn khấn
          Expanded(
            child: filteredPrayers.isEmpty
                ? Center(
                    child: Text(
                      'Không tìm thấy bài văn khấn phù hợp',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredPrayers.length,
                    itemBuilder: (context, index) {
                      final item = filteredPrayers[index];
                      return _buildPrayerCard(context, item, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerCard(BuildContext context, PrayerItem item, bool isDark) {
    Color badgeColor;
    String badgeText;

    switch (item.category) {
      case 'gio':
        badgeColor = Colors.deepOrange;
        badgeText = 'Hiếu Đạo';
        break;
      case 'tet':
        badgeColor = Colors.red;
        badgeText = 'Tết Cổ Truyền';
        break;
      case 'ram_mung_mot':
        badgeColor = Colors.teal;
        badgeText = 'Sóc Vọng';
        break;
      case 'le_tiet':
      default:
        badgeColor = Colors.indigo;
        badgeText = 'Lễ Tiết';
        break;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => PrayerDetailScreen(
                prayer: item,
                profile: widget.profile,
                onProfileUpdated: widget.onProfileUpdated,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 11,
                        color: badgeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.occasion,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 14, color: isDark ? Colors.amber : Colors.orange[800]),
                  const SizedBox(width: 4),
                  Text(
                    '${item.offerings.length} món lễ vật gợi ý',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.amber : Colors.orange[900],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileDialog(BuildContext context) {
    final giaChuController = TextEditingController(text: widget.profile.giaChu);
    final diaChiController = TextEditingController(text: widget.profile.diaChi);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thông tin Tín Chủ (Gia Chủ)'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Lưu tên chủ nhà và địa chỉ để văn khấn tự động điền sẵn mỗi khi mở đọc.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: giaChuController,
                decoration: const InputDecoration(
                  labelText: 'Họ tên Gia chủ / Tín chủ',
                  hintText: 'VD: Lê Đức Anh',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: diaChiController,
                decoration: const InputDecoration(
                  labelText: 'Nơi cư ngụ (Địa chỉ nhà)',
                  hintText: 'VD: Số 12, Đường Trần Phú, TP Hà Tĩnh',
                  border: OutlineInputBorder(),
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
            onPressed: () {
              final newProfile = UserProfile(
                giaChu: giaChuController.text.trim(),
                diaChi: diaChiController.text.trim(),
                prayerFontSize: widget.profile.prayerFontSize,
                isDarkMode: widget.profile.isDarkMode,
              );
              widget.onProfileUpdated(newProfile);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã cập nhật thông tin gia chủ!')),
              );
            },
            child: const Text('Lưu thông tin'),
          ),
        ],
      ),
    );
  }
}
