/// Màn hình Chi tiết Ngày Giỗ & Quản lý Mâm Cỗ, Thu Chi
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/prayers_data.dart';
import '../models/event_model.dart';
import '../services/event_calculator.dart';
import '../services/storage_service.dart';
import 'prayer_detail_screen.dart';
import 'add_edit_event_screen.dart';
import 'offerings_guide_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final EventItem event;
  final UserProfile profile;
  final Function(UserProfile) onProfileUpdated;
  final Function(EventItem) onEventUpdated;
  final VoidCallback onEventDeleted;

  const EventDetailScreen({
    super.key,
    required this.event,
    required this.profile,
    required this.onProfileUpdated,
    required this.onEventUpdated,
    required this.onEventDeleted,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late EventItem _currentEvent;
  final TextEditingController _dishController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final occ = EventCalculator.calculateNextOccurrence(_currentEvent);

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentEvent.title),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFF8B2500),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Chỉnh sửa',
            onPressed: () async {
              final result = await Navigator.push<EventItem>(
                context,
                MaterialPageRoute(
                  builder: (ctx) => AddEditEventScreen(event: _currentEvent),
                ),
              );
              if (result != null) {
                setState(() => _currentEvent = result);
                widget.onEventUpdated(result);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Xóa sự kiện',
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // CARD 1: ĐẾM NGƯỢC & THỜI GIAN
          if (occ != null) _buildCountdownCard(occ, isDark),
          const SizedBox(height: 16),

          // NÚT TẠO VĂN KHẤN (Chỉ hiển thị khi là Ngày Giỗ / Lễ Cúng)
          if (_currentEvent.type == EventType.deathAnniversary) ...[
            _buildPrayerShortcutButton(context, isDark),
            const SizedBox(height: 16),
          ],

          // CARD 2: THÔNG TIN NGƯỜI ĐƯỢC TƯỞNG NHỚ
          if (_currentEvent.type == EventType.deathAnniversary ||
              (_currentEvent.personName?.isNotEmpty ?? false)) ...[
            _buildPersonInfoCard(isDark),
            const SizedBox(height: 16),
          ],

          // CARD 3: DANH SÁCH MÂM CỖ & ĐỒ CẦN SẮM
          _buildDishesCard(isDark),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildCountdownCard(EventOccurrence occ, bool isDark) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final isDeathAnniversary =
        _currentEvent.type == EventType.deathAnniversary;
    String statusText;
    Color statusBg;

    if (occ.daysRemaining == 0) {
      statusText = isDeathAnniversary ? 'Hôm nay · Chính kỵ' : 'Hôm nay';
      statusBg = Colors.red;
    } else if (occ.daysRemaining == 1) {
      statusText = isDeathAnniversary && _currentEvent.remindTienThuong
          ? 'Ngày mai · Hôm nay tiên thường'
          : 'Ngày mai';
      statusBg = Colors.orange;
    } else {
      statusText = 'Còn ${occ.daysRemaining} ngày nữa';
      statusBg = const Color(0xFF8B2500);
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF2A2A2A), const Color(0xFF1E1E1E)]
                : [const Color(0xFFFFF8EE), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (occ.anniversaryCount != null)
                  Text(
                    isDeathAnniversary
                        ? 'Giỗ lần thứ ${occ.anniversaryCount}'
                        : _currentEvent.type == EventType.birthday
                            ? '${occ.anniversaryCount} tuổi'
                            : 'Năm thứ ${occ.anniversaryCount}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.amber : const Color(0xFF8B2500),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isDeathAnniversary ? 'Chính kỵ (Dương lịch):' : 'Ngày diễn ra (Dương lịch):',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        dateFormat.format(occ.nextSolarDate),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                if (isDeathAnniversary && occ.tienThuongSolarDate != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tiên thường (Chiều):', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          dateFormat.format(occ.tienThuongSolarDate!),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey[300] : Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: isDark ? Colors.amber : const Color(0xFF8B2500)),
                const SizedBox(width: 6),
                Flexible(child: Text(
                  _currentEvent.calendar == CalendarType.lunar
                      ? 'Âm lịch: ${occ.adjustedDay}/${_currentEvent.month}${_currentEvent.isLeapMonth ? " (gốc: tháng nhuận)" : ""}${occ.adjustedDay != _currentEvent.day ? " · Tháng thiếu dùng ngày 29" : ""}'
                      : 'Dương lịch: Ngày ${_currentEvent.day}/${_currentEvent.month}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerShortcutButton(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? const Color(0xFF8B2500) : const Color(0xFF8B2500),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
          ),
          icon: const Icon(Icons.auto_stories),
          label: const Text(
            'Tạo Văn Khấn Ngày Giỗ (Tự động điền tên)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          onPressed: () {
            final prayerChinhKy = PrayersData.allPrayers.firstWhere((p) => p.id == 'gio_chinh_ky');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => PrayerDetailScreen(
                  prayer: prayerChinhKy,
                  profile: widget.profile,
                  onProfileUpdated: widget.onProfileUpdated,
                  defaultNguoiMat: _currentEvent.personName ?? _currentEvent.title,
                  defaultQuanHe: _currentEvent.relation ?? 'Cụ',
                  defaultNgayAm: 'Ngày ${_currentEvent.day} tháng ${_currentEvent.month} Âm lịch',
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            side: BorderSide(color: isDark ? Colors.amber : const Color(0xFF8B2500), width: 1.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: Icon(Icons.restaurant_menu, color: isDark ? Colors.amber : const Color(0xFF8B2500)),
          label: Text(
            'Cẩm Nang Sắm Lễ & Mâm Cỗ Truyền Thống',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.amber : const Color(0xFF8B2500),
            ),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => OfferingsGuideScreen(eventTitle: _currentEvent.title),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPersonInfoCard(bool isDark) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.family_restroom, color: Colors.blueGrey),
                SizedBox(width: 8),
                Text('Thông Tin Người Thân', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow('Họ và tên:', _currentEvent.personName ?? 'Chưa rõ'),
            _infoRow('Vai vế / Quan hệ:', _currentEvent.relation ?? 'Chưa rõ'),
            if (_currentEvent.year != null)
              _infoRow(
                _currentEvent.type == EventType.deathAnniversary
                    ? 'Năm mất:'
                    : _currentEvent.type == EventType.birthday
                        ? 'Năm sinh:'
                        : 'Năm gốc:',
                '${_currentEvent.year} ${_currentEvent.type == EventType.deathAnniversary && _currentEvent.ageAtDeath != null ? "(Hưởng thọ ${_currentEvent.ageAtDeath} tuổi)" : ""}',
              ),
            if (_currentEvent.restingPlace != null && _currentEvent.restingPlace!.isNotEmpty)
              _infoRow('Nơi an nghỉ:', _currentEvent.restingPlace!),
            if (_currentEvent.notes != null && _currentEvent.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Ghi chú tục lệ:', style: TextStyle(fontSize: 13, color: Colors.grey)),
              Text(_currentEvent.notes!, style: const TextStyle(fontSize: 14)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildDishesCard(bool isDark) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.restaurant_menu, color: Colors.orange),
                const SizedBox(width: 8),
                const Text('Mâm Cỗ & Đồ Sắm Lễ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${_currentEvent.dishes.length} món', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 10),
            if (_currentEvent.dishes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Chưa có danh sách món ăn mâm cỗ', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
              )
            else
              ..._currentEvent.dishes.map((dish) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        const Icon(Icons.check, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(child: Text(dish, style: const TextStyle(fontSize: 14))),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _currentEvent.dishes.remove(dish);
                            });
                            widget.onEventUpdated(_currentEvent);
                          },
                        ),
                      ],
                    ),
                  )),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _dishController,
                    decoration: const InputDecoration(
                      hintText: 'Thêm món (VD: Nem rán, Gà luộc...)',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final text = _dishController.text.trim();
                    if (text.isNotEmpty) {
                      setState(() {
                        _currentEvent.dishes.add(text);
                        _dishController.clear();
                      });
                      widget.onEventUpdated(_currentEvent);
                    }
                  },
                  child: const Text('Thêm'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa "${_currentEvent.title}" không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onEventDeleted();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
