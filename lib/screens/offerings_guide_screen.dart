import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/traditional_offerings_data.dart';

/// Màn hình Cẩm nang Gợi ý Mâm cỗ & Đồ lễ truyền thống
class OfferingsGuideScreen extends StatefulWidget {
  final String? eventTitle;

  const OfferingsGuideScreen({super.key, this.eventTitle});

  @override
  State<OfferingsGuideScreen> createState() => _OfferingsGuideScreenState();
}

class _OfferingsGuideScreenState extends State<OfferingsGuideScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _checkedItems = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _shareShoppingList() {
    final buffer = StringBuffer();
    buffer.writeln('📋 DANH SÁCH SẮM LỄ & MÂM CỖ CÚNG GIỖ');
    if (widget.eventTitle != null && widget.eventTitle!.isNotEmpty) {
      buffer.writeln('Sự kiện: ${widget.eventTitle}');
    }
    buffer.writeln('------------------------------------');

    if (_checkedItems.isEmpty) {
      buffer.writeln('• Lễ vật cốt lõi:');
      for (final item in TraditionalOfferingsData.essentialOfferings) {
        buffer.writeln('  - [ ] ${item.name}');
      }
      buffer.writeln('• Mâm cỗ truyền thống:');
      for (final item in TraditionalOfferingsData.traditionalMeatFeast.take(5)) {
        buffer.writeln('  - [ ] ${item.name}');
      }
    } else {
      buffer.writeln('Các món đã chọn chuẩn bị:');
      for (final name in _checkedItems) {
        buffer.writeln('  - [x] $name');
      }
    }
    buffer.writeln('------------------------------------');
    buffer.writeln('Kính chúc buổi lễ chu đáo, gia đạo bình an!');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép danh sách sắm lễ! Bạn có thể dán vào Zalo ngay.'),
        backgroundColor: Color(0xFF8B1E0F),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryRed = Color(0xFF8B1E0F);
    const goldColor = Color(0xFFD4AF37);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.eventTitle != null ? 'Sắm Lễ: ${widget.eventTitle}' : 'Cẩm Nang Mâm Cỗ & Sắm Lễ',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5),
        ),
        backgroundColor: isDark ? const Color(0xFF1E1715) : primaryRed,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Sao chép danh sách sắm lễ gửi Zalo',
            onPressed: _shareShoppingList,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: goldColor,
          labelColor: goldColor,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.temple_buddhist, size: 18), text: 'Lễ Gia Tiên'),
            Tab(icon: Icon(Icons.restaurant, size: 18), text: 'Mâm Cỗ Mặn'),
            Tab(icon: Icon(Icons.eco, size: 18), text: 'Mâm Cỗ Chay'),
            Tab(icon: Icon(Icons.menu_book, size: 18), text: 'Phong Tục'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOfferingsList(TraditionalOfferingsData.essentialOfferings, isDark, primaryRed, goldColor),
          _buildOfferingsList(TraditionalOfferingsData.traditionalMeatFeast, isDark, primaryRed, goldColor),
          _buildOfferingsList(TraditionalOfferingsData.traditionalVegetarianFeast, isDark, primaryRed, goldColor),
          _buildCustomsKnowledgeView(isDark, goldColor),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF221A18) : const Color(0xFFFAF5ED),
          border: Border(top: BorderSide(color: isDark ? Colors.white12 : Colors.black12)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _checkedItems.isEmpty
                    ? 'Tích chọn các món để tạo danh sách đi chợ'
                    : 'Đã chọn ${_checkedItems.length} món chuẩn bị',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[300] : Colors.grey[800],
                ),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Gửi Zalo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              onPressed: _shareShoppingList,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferingsList(
    List<OfferingItem> items,
    bool isDark,
    Color primaryRed,
    Color goldColor,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isChecked = _checkedItems.contains(item.name);

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isChecked
                  ? goldColor
                  : (item.isEssential ? primaryRed.withOpacity(0.3) : Colors.black12),
              width: isChecked ? 1.5 : (item.isEssential ? 1 : 0.6),
            ),
          ),
          child: CheckboxListTile(
            activeColor: primaryRed,
            checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            value: isChecked,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  _checkedItems.add(item.name);
                } else {
                  _checkedItems.remove(item.name);
                }
              });
            },
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      decoration: isChecked ? TextDecoration.lineThrough : null,
                      color: isChecked
                          ? Colors.grey
                          : (isDark ? Colors.white : const Color(0xFF2C1810)),
                    ),
                  ),
                ),
                if (item.isEssential)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: primaryRed.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Cốt lõi',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: primaryRed,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                item.description,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  height: 1.3,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomsKnowledgeView(bool isDark, Color goldColor) {
    final entries = TraditionalOfferingsData.customsKnowledge.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: goldColor.withOpacity(0.4), width: 0.8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_stories, color: goldColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B1E0F),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 18),
                Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: isDark ? Colors.grey[300] : const Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
