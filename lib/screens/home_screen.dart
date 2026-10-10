/// Màn hình Trang Chủ (Home Dashboard) nâng cấp: Hoàng Gia, Công Nghệ & Bản Sắc Cổ Truyền
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../lunar_engine.dart';
import '../models/event_model.dart';
import '../models/note_model.dart';
import '../services/event_calculator.dart';
import '../services/storage_service.dart';
import '../widgets/add_edit_note_sheet.dart';
import 'add_edit_event_screen.dart';
import 'event_detail_screen.dart';
import 'prayer_detail_screen.dart';
import '../data/prayers_data.dart';
import 'paywall_screen.dart';
import 'offerings_guide_screen.dart';
import '../services/event_reminder_service.dart';

class HomeScreen extends StatefulWidget {
  final List<EventItem> events;
  final List<DailyNoteItem> notes;
  final UserProfile profile;
  final Function(UserProfile) onProfileUpdated;
  final Function(EventItem) onEventAdded;
  final Function(EventItem) onEventUpdated;
  final Function(String) onEventDeleted;
  final Function(DailyNoteItem) onNoteAdded;
  final Function(DailyNoteItem) onNoteUpdated;
  final Function(String) onNoteDeleted;
  final Function(int) onNavigateTab;

  const HomeScreen({
    super.key,
    required this.events,
    required this.notes,
    required this.profile,
    required this.onProfileUpdated,
    required this.onEventAdded,
    required this.onEventUpdated,
    required this.onEventDeleted,
    required this.onNoteAdded,
    required this.onNoteUpdated,
    required this.onNoteDeleted,
    required this.onNavigateTab,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _activeTab = 'events'; // 'events' hoặc 'notes'
  String _searchQuery = '';
  String _filterType = 'all'; // 'all', 'upcoming_30', 'this_month'
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    EventReminderService().loadSettings().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryRed = const Color(0xFF8B1E0F);
    final goldColor = const Color(0xFFD4AF37);

    final now = DateTime.now();
    final todayLunar = VietnameseLunarEngine.solarToLunar(now.day, now.month, now.year);
    final canChiYear = VietnameseLunarEngine.getCanChiYear(todayLunar.year);
    final canChiDay = VietnameseLunarEngine.getCanChiDay(todayLunar.jd);
    final solarTerm = VietnameseLunarEngine.getSolarTerm(now.day, now.month, now.year);
    final isHoangDao = VietnameseLunarEngine.isHoangDaoDay(todayLunar.jd, todayLunar.month);

    // Tính toán và lọc sự kiện
    final allOccurrences = EventCalculator.getSortedOccurrences(widget.events);
    final nextUpcoming = allOccurrences.isNotEmpty ? allOccurrences.first : null;
    final reminderAlerts = EventReminderService().getUpcomingAlerts(widget.events);

    final filteredOccurrences = allOccurrences.where((occ) {
      final ev = occ.event;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchTitle = ev.title.toLowerCase().contains(query);
        final matchName = ev.personName?.toLowerCase().contains(query) ?? false;
        final matchRelation = ev.relation?.toLowerCase().contains(query) ?? false;
        if (!matchTitle && !matchName && !matchRelation) return false;
      }
      if (_filterType == 'upcoming_7') {
        return occ.daysRemaining <= 7;
      } else if (_filterType == 'upcoming_30') {
        return occ.daysRemaining <= 30;
      } else if (_filterType == 'death') {
        return ev.type == EventType.deathAnniversary;
      } else if (_filterType == 'birthday') {
        return ev.type == EventType.birthday;
      } else if (_filterType == 'this_month') {
        return occ.nextSolarDate.month == now.month && occ.nextSolarDate.year == now.year;
      }
      return true;
    }).toList();

    // Ghi chú
    final pendingNotes = widget.notes.where((n) => !n.isCompleted).toList();
    final completedNotes = widget.notes.where((n) => n.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: goldColor, width: 1.2),
              ),
              child: Icon(Icons.temple_buddhist, color: goldColor, size: 16),
            ),
            const SizedBox(width: 8),
            const Text(
              'SỰ KIỆN GIA TỘC',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8, fontSize: 17),
            ),
          ],
        ),
        backgroundColor: isDark ? const Color(0xFF1E1715) : primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: goldColor),
            tooltip: 'Thông tin bản thử nghiệm miễn phí',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => PaywallScreen(
                    profile: widget.profile,
                    storageService: StorageService(),
                    onProfileUpdated: widget.onProfileUpdated,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.restaurant_menu_rounded),
            tooltip: 'Cẩm Nang Mâm Cỗ & Sắm Lễ',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const OfferingsGuideScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Đổi Lịch Âm - Dương',
            onPressed: () => _openQuickConverter(context),
          ),
          IconButton(
            icon: const Icon(Icons.auto_stories),
            tooltip: 'Kho Văn Khấn Cổ Truyền',
            onPressed: () => widget.onNavigateTab(2),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        color: primaryRed,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // 1. HEADER HOÀNG GIA: HÔM NAY (TIẾT KHÍ, CAN CHI, HOÀNG ĐẠO)
            _buildTodayHeaderCard(
              now: now,
              lunar: todayLunar,
              canChiYear: canChiYear,
              canChiDay: canChiDay,
              solarTerm: solarTerm,
              isHoangDao: isHoangDao,
              isDark: isDark,
              primaryRed: primaryRed,
              goldColor: goldColor,
            ),
            const SizedBox(height: 14),

            // 1B. BANNER NHẮC NHỞ GIA TỘC (NẾU CÓ CẢNH BÁO)
            if (reminderAlerts.isNotEmpty) ...[
              _buildReminderAlertsBanner(
                alerts: reminderAlerts,
                isDark: isDark,
                primaryRed: primaryRed,
                goldColor: goldColor,
              ),
              const SizedBox(height: 14),
            ],

            // 2. HERO COUNTDOWN CARD: NGÀY GIỖ GẦN NHẤT
            if (nextUpcoming != null) ...[
              _buildUpcomingFeatureCard(nextUpcoming, isDark, primaryRed, goldColor),
              const SizedBox(height: 16),
            ],

            // 3. THANH TÌM KIẾM & BỘ LỌC THÔNG MINH
            _buildSearchAndFilterBar(isDark, primaryRed, goldColor),
            const SizedBox(height: 14),

            // 4. THANH CHUYỂN TAB: [NGÀY GIỖ] HOẶC [VIỆC CẦN LÀM]
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF28201D) : const Color(0xFFEFE7DB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: goldColor.withOpacity(0.2)),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: _tabButton(
                      title: 'Sự Kiện (${widget.events.length})',
                      isSelected: _activeTab == 'events',
                      icon: Icons.event_note_rounded,
                      onTap: () => setState(() => _activeTab = 'events'),
                      primaryRed: primaryRed,
                      goldColor: goldColor,
                    ),
                  ),
                  Expanded(
                    child: _tabButton(
                      title: 'Việc Cần Nhớ (${pendingNotes.length})',
                      isSelected: _activeTab == 'notes',
                      icon: Icons.checklist_rtl_rounded,
                      onTap: () => setState(() => _activeTab = 'notes'),
                      primaryRed: primaryRed,
                      goldColor: goldColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 5. DANH SÁCH THEO TAB
            if (_activeTab == 'events') ...[
              _buildEventsSection(filteredOccurrences, isDark, primaryRed, goldColor),
            ] else ...[
              _buildNotesSection(pendingNotes, completedNotes, isDark, primaryRed),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
        icon: Icon(_activeTab == 'events' ? Icons.add_circle_outline : Icons.note_add),
        label: Text(
          _activeTab == 'events' ? 'Thêm sự kiện' : 'Thêm ghi chú',
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        onPressed: () {
          if (_activeTab == 'events') {
            _navigateToAddEvent();
          } else {
            _openAddNoteSheet(context);
          }
        },
      ),
    );
  }

  Widget _tabButton({
    required String title,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
    required Color primaryRed,
    required Color goldColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? primaryRed : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [const BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: isSelected ? goldColor : Colors.grey[700]),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[800],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatFullDateVietnamese(DateTime date) {
    const weekdays = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];
    final wd = weekdays[date.weekday - 1];
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$wd, $d/$m/${date.year}';
  }

  // 1. HEADER CARD HÔM NAY
  Widget _buildTodayHeaderCard({
    required DateTime now,
    required LunarDate lunar,
    required String canChiYear,
    required String canChiDay,
    required String solarTerm,
    required bool isHoangDao,
    required bool isDark,
    required Color primaryRed,
    required Color goldColor,
  }) {
    final fullDateText = _formatFullDateVietnamese(now);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF241D1A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: goldColor.withOpacity(0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dòng trên: Thứ ngày dương lịch & nút Giờ Hoàng Đạo
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 14, color: isDark ? goldColor : primaryRed),
              const SizedBox(width: 6),
              Text(
                fullDateText,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[300] : const Color(0xFF5D4037),
                ),
              ),
              const Spacer(),
              // Huy hiệu ngày Hoàng đạo / Hắc đạo
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isHoangDao ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isHoangDao ? Colors.green.withOpacity(0.4) : Colors.orange.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isHoangDao ? Icons.stars_rounded : Icons.info_outline,
                      size: 12,
                      color: isHoangDao ? Colors.green[800] : Colors.orange[900],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isHoangDao ? 'Ngày Hoàng Đạo' : 'Ngày Hắc Đạo',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: isHoangDao ? Colors.green[800] : Colors.orange[900],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Khối trung tâm: Ngày Âm lịch to rõ
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [goldColor, const Color(0xFF996515)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(color: goldColor.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${lunar.day}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tháng ${lunar.month} Âm lịch ${lunar.isLeap ? "(Nhuận)" : ""}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? goldColor : primaryRed,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Năm $canChiYear • Ngày $canChiDay',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.grey[300] : Colors.grey[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Tiết khí: $solarTerm',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? goldColor.withOpacity(0.8) : const Color(0xFF8B2500),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Colors.black12),
          const SizedBox(height: 10),

          // Dòng dưới: Tiện ích xem giờ hoàng đạo & chuyển sang Lịch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => _showHoangDaoHoursModal(context, lunar.jd),
                child: Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 15, color: goldColor),
                    const SizedBox(width: 5),
                    Text(
                      'Xem Giờ Hoàng Đạo cúng',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? goldColor : primaryRed,
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 16, color: isDark ? goldColor : primaryRed),
                  ],
                ),
              ),
              InkWell(
                onTap: () => widget.onNavigateTab(1),
                child: Row(
                  children: [
                    Text(
                      'Mở Lịch Tháng',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.grey[700]),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 1B. BANNER NHẮC NHỞ GIA TỘC THÔNG MINH
  Widget _buildReminderAlertsBanner({
    required List<ReminderAlert> alerts,
    required bool isDark,
    required Color primaryRed,
    required Color goldColor,
  }) {
    if (alerts.isEmpty) return const SizedBox.shrink();

    final hasUrgent = alerts.any((a) => a.alertType == 'today' || a.alertType == 'tien_thuong');

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2B1C19) : const Color(0xFFFFF9EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasUrgent ? Colors.redAccent.withOpacity(0.8) : goldColor.withOpacity(0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (hasUrgent ? Colors.red : goldColor).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_active_rounded,
                  color: hasUrgent ? Colors.redAccent : goldColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'NHẮC NHỞ GIA TỘC QUAN TRỌNG (${alerts.length})',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: isDark ? goldColor : primaryRed,
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (ctx) => const OfferingsGuideScreen()),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.restaurant_menu_rounded, size: 14, color: goldColor),
                    const SizedBox(width: 3),
                    Text(
                      'Sắm Lễ',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? goldColor : primaryRed,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...alerts.take(3).map((alert) {
            final isUrgent = alert.alertType == 'today' || alert.alertType == 'tien_thuong';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => EventDetailScreen(
                        event: alert.event,
                        profile: widget.profile,
                        onEventUpdated: widget.onEventUpdated,
                        onEventDeleted: () => widget.onEventDeleted(alert.event.id),
                        onProfileUpdated: widget.onProfileUpdated,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F1715) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isUrgent ? Colors.red.withOpacity(0.3) : goldColor.withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isUrgent ? Icons.error_outline_rounded : Icons.schedule_rounded,
                        size: 16,
                        color: isUrgent ? Colors.redAccent : goldColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alert.title,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF3E2723),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              alert.message,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey[400] : Colors.grey[700],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // 2. HERO CARD NGÀY GIỖ GẦN NHẤT
  Widget _buildUpcomingFeatureCard(
    EventOccurrence occ,
    bool isDark,
    Color primaryRed,
    Color goldColor,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final ev = occ.event;

    String countdownBadge;
    Color badgeColor;
    if (occ.daysRemaining == 0) {
      countdownBadge = 'HÔM NAY - CHÍNH KỴ';
      badgeColor = Colors.redAccent;
    } else if (occ.daysRemaining == 1) {
      countdownBadge = 'NGÀY MAI (CHIỀU NAY TIÊN THƯỜNG)';
      badgeColor = Colors.orangeAccent;
    } else {
      countdownBadge = 'Còn ${occ.daysRemaining} ngày nữa';
      badgeColor = goldColor;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF421208), const Color(0xFF1E1412)]
              : [const Color(0xFF8B1E0F), const Color(0xFF5B0F04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: goldColor.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B1E0F).withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dòng nhãn
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: goldColor.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.alarm_on, color: goldColor, size: 13),
                    const SizedBox(width: 5),
                    Text(
                      'SỰ KIỆN GẦN NHẤT',
                      style: TextStyle(color: goldColor, fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 0.6),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeColor, width: 1),
                ),
                child: Text(
                  countdownBadge,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Tên sự kiện
          Text(
            ev.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
          if (ev.personName != null && ev.personName!.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              '${ev.type == EventType.deathAnniversary ? "Cố nhân" : "Người thân"}: ${ev.personName!} ${ev.relation != null && ev.relation!.isNotEmpty ? "• (${ev.relation!})" : ""}',
              style: const TextStyle(color: Colors.white70, fontSize: 13.5),
            ),
          ],
          if (ev.restingPlace != null && ev.restingPlace!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.place_outlined, color: Colors.white54, size: 13),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'An nghỉ: ${ev.restingPlace!}',
                    style: const TextStyle(color: Colors.white60, fontSize: 11.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ev.type == EventType.deathAnniversary
                            ? 'Chính kỵ Âm lịch: Ngày ${occ.adjustedDay}/${ev.month} Âm'
                            : (ev.calendar == CalendarType.lunar
                                ? 'Ngày Âm lịch: ${occ.adjustedDay}/${ev.month} Âm'
                                : 'Ngày Dương lịch: ${ev.day}/${ev.month}'),
                        style: TextStyle(color: goldColor, fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Dương lịch: ${dateFormat.format(occ.nextSolarDate)}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (occ.anniversaryCount != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: goldColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ev.type == EventType.deathAnniversary
                          ? 'Giỗ năm thứ ${occ.anniversaryCount}'
                          : (ev.type == EventType.birthday
                              ? 'Sinh nhật thứ ${occ.anniversaryCount}'
                              : 'Kỷ niệm lần thứ ${occ.anniversaryCount}'),
                      style: const TextStyle(
                        color: Color(0xFF5B0F04),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 14),
          // Nút tác vụ nhanh
          Row(
            children: [
              if (ev.type == EventType.deathAnniversary) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.menu_book, size: 15, color: goldColor),
                    label: const Text('Tạo Văn Khấn', style: TextStyle(color: Colors.white, fontSize: 12.5)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: goldColor.withOpacity(0.7)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                    ),
                    onPressed: () => _openPrayerForEvent(context, ev, occ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_forward, size: 15),
                  label: const Text('Xem Chi Tiết', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: goldColor,
                    foregroundColor: const Color(0xFF5B0F04),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                  ),
                  onPressed: () => _navigateToEventDetail(ev),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. THANH TÌM KIẾM & BỘ LỌC
  Widget _buildSearchAndFilterBar(bool isDark, Color primaryRed, Color goldColor) {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm tên người thân, sự kiện, ngày giỗ...',
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            filled: true,
            fillColor: isDark ? const Color(0xFF241D1A) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
            ),
          ),
          onChanged: (val) => setState(() => _searchQuery = val.trim()),
        ),
        const SizedBox(height: 8),
        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip('Tất cả', 'all', isDark, primaryRed),
              const SizedBox(width: 8),
              _filterChip('7 ngày tới 🔥', 'upcoming_7', isDark, primaryRed),
              const SizedBox(width: 8),
              _filterChip('30 ngày tới', 'upcoming_30', isDark, primaryRed),
              const SizedBox(width: 8),
              _filterChip('Ngày Giỗ 🕯️', 'death', isDark, primaryRed),
              const SizedBox(width: 8),
              _filterChip('Sinh Nhật 🎂', 'birthday', isDark, primaryRed),
              const SizedBox(width: 8),
              _filterChip('Trong tháng này', 'this_month', isDark, primaryRed),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, String value, bool isDark, Color primaryRed) {
    final isSelected = _filterType == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: primaryRed.withOpacity(0.15),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? primaryRed : (isDark ? Colors.grey[400] : Colors.grey[700]),
      ),
      onSelected: (_) => setState(() => _filterType = value),
    );
  }

  // 4. DANH SÁCH SỰ KIỆN
  Widget _buildEventsSection(
    List<EventOccurrence> occurrences,
    bool isDark,
    Color primaryRed,
    Color goldColor,
  ) {
    if (occurrences.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.event_note_rounded, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                _searchQuery.isNotEmpty ? 'Không tìm thấy sự kiện phù hợp' : 'Chưa có sự kiện nào',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Thêm sự kiện mới'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryRed,
                  foregroundColor: Colors.white,
                ),
                onPressed: _navigateToAddEvent,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: occurrences.map((occ) => _buildEventItemCard(occ, isDark, primaryRed, goldColor)).toList(),
    );
  }

  Widget _buildEventItemCard(
    EventOccurrence occ,
    bool isDark,
    Color primaryRed,
    Color goldColor,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final ev = occ.event;

    Color badgeColor = Colors.grey;
    String badgeText = 'Còn ${occ.daysRemaining} ngày';

    if (occ.daysRemaining == 0) {
      badgeColor = Colors.red;
      badgeText = ev.type == EventType.birthday ? 'HÔM NAY (Sinh nhật 🎂)' : 'HÔM NAY (Chính lễ 🕯️)';
    } else if (occ.daysRemaining == 1) {
      badgeColor = Colors.orange;
      badgeText = 'NGÀY MAI';
    } else if (occ.daysRemaining <= 7) {
      badgeColor = const Color(0xFFD4AF37);
      badgeText = 'Còn ${occ.daysRemaining} ngày 🔥';
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 11),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: (occ.daysRemaining <= 3) ? goldColor.withOpacity(0.6) : Colors.black12,
          width: (occ.daysRemaining <= 3) ? 1.2 : 0.6,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToEventDetail(ev),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon theo loại sự kiện
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF352622) : const Color(0xFFFBE9E7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: goldColor.withOpacity(0.3)),
                ),
                child: Center(
                  child: Icon(
                    ev.type == EventType.birthday
                        ? Icons.cake_outlined
                        : (ev.type == EventType.memorial
                            ? Icons.celebration_outlined
                            : Icons.local_fire_department),
                    color: ev.type == EventType.birthday
                        ? Colors.pink
                        : (isDark ? goldColor : primaryRed),
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Nội dung chính
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ev.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      ev.calendar == CalendarType.lunar
                          ? 'Âm lịch: Ngày ${occ.adjustedDay}/${ev.month} Âm'
                          : 'Dương lịch: Ngày ${ev.day}/${ev.month}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? goldColor : primaryRed,
                      ),
                    ),
                    Text(
                      'Dương: ${dateFormat.format(occ.nextSolarDate)}${ev.personName != null && ev.personName!.isNotEmpty ? " • ${ev.personName}" : ""}',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Badge đếm ngược
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: badgeColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ),
                  if (occ.anniversaryCount != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Lần ${occ.anniversaryCount}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 5. DANH SÁCH GHI CHÚ
  Widget _buildNotesSection(
    List<DailyNoteItem> pending,
    List<DailyNoteItem> completed,
    bool isDark,
    Color primaryRed,
  ) {
    if (pending.isEmpty && completed.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.checklist_rtl_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              const Text('Chưa có việc cần nhớ hoặc ghi chú nào', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.note_add),
                label: const Text('Thêm ghi chú ngay'),
                style: ElevatedButton.styleFrom(backgroundColor: primaryRed, foregroundColor: Colors.white),
                onPressed: () => _openAddNoteSheet(context),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pending.isNotEmpty) ...[
          const Text('CẦN THỰC HIỆN:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal)),
          const SizedBox(height: 8),
          ...pending.map((n) => _buildNoteItemCard(n, isDark)),
          const SizedBox(height: 14),
        ],
        if (completed.isNotEmpty) ...[
          const Text('ĐÃ HOÀN THÀNH:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          ...completed.map((n) => _buildNoteItemCard(n, isDark)),
        ],
      ],
    );
  }

  Widget _buildNoteItemCard(DailyNoteItem note, bool isDark) {
    Color catColor = Colors.teal;
    String catLabel = 'Việc cần làm';

    if (note.category == NoteCategory.offering) {
      catColor = const Color(0xFF8B1E0F);
      catLabel = 'Đồ cúng giỗ';
    } else if (note.category == NoteCategory.family) {
      catColor = Colors.indigo;
      catLabel = 'Gia đình';
    } else if (note.category == NoteCategory.general) {
      catColor = Colors.orange[800]!;
      catLabel = 'Ghi nhớ';
    }

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Checkbox(
          value: note.isCompleted,
          activeColor: Colors.teal,
          onChanged: (val) {
            note.isCompleted = val ?? false;
            widget.onNoteUpdated(note);
          },
        ),
        title: Text(
          note.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            decoration: note.isCompleted ? TextDecoration.lineThrough : null,
            color: note.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: catColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                catLabel,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: catColor),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${note.date.day}/${note.date.month} (Âm ${note.lunarDay}/${note.lunarMonth})',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            if (note.time != null) ...[
              const SizedBox(width: 6),
              Text('• ${note.time}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
          onPressed: () => widget.onNoteDeleted(note.id),
        ),
      ),
    );
  }

  // MODAL XEM GIỜ HOÀNG ĐẠO
  void _showHoangDaoHoursModal(BuildContext context, int jd) {
    final hours = VietnameseLunarEngine.getHoangDaoHours(jd);
    final goldColor = const Color(0xFFD4AF37);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.stars_rounded, color: goldColor, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'CÁC GIỜ HOÀNG ĐẠO HÔM NAY',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF8B1E0F)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Nên chọn các khung giờ này để làm lễ cúng, thắp hương, nghinh phúc:',
                style: TextStyle(fontSize: 12.5, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: hours.map((h) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBF8F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: goldColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      h,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B1E0F), fontSize: 13),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // MODAL ĐỔI LỊCH NHANH
  void _openQuickConverter(BuildContext context) {
    int selectedDay = DateTime.now().day;
    int selectedMonth = DateTime.now().month;
    int selectedYear = DateTime.now().year;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final lunar = VietnameseLunarEngine.solarToLunar(selectedDay, selectedMonth, selectedYear);
            final canChiY = VietnameseLunarEngine.getCanChiYear(lunar.year);
            final canChiD = VietnameseLunarEngine.getCanChiDay(lunar.jd);

            return AlertDialog(
              title: const Text('Tra Cứu & Đổi Lịch Âm - Dương', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      DropdownButton<int>(
                        value: selectedDay,
                        items: List.generate(31, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}'))),
                        onChanged: (v) => setDialogState(() => selectedDay = v ?? selectedDay),
                      ),
                      const Text('/'),
                      DropdownButton<int>(
                        value: selectedMonth,
                        items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text('T.${i + 1}'))),
                        onChanged: (v) => setDialogState(() => selectedMonth = v ?? selectedMonth),
                      ),
                      const Text('/'),
                      DropdownButton<int>(
                        value: selectedYear,
                        items: [2024, 2025, 2026, 2027, 2028].map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                        onChanged: (v) => setDialogState(() => selectedYear = v ?? selectedYear),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBE9E7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'ÂM LỊCH: Ngày ${lunar.day} Tháng ${lunar.month}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF8B1E0F)),
                        ),
                        const SizedBox(height: 4),
                        Text('Năm $canChiY • Ngày $canChiD', style: const TextStyle(fontSize: 12.5)),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Đóng'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openPrayerForEvent(BuildContext context, EventItem ev, EventOccurrence occ) {
    // Tìm bài cúng phù hợp
    final prayer = PrayersData.allPrayers.firstWhere(
      (p) => p.id == 'gio_chinh_ky',
      orElse: () => PrayersData.allPrayers.first,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => PrayerDetailScreen(
          prayer: prayer,
          profile: widget.profile,
          onProfileUpdated: widget.onProfileUpdated,
          defaultNguoiMat: ev.personName ?? ev.title,
          defaultQuanHe: ev.relation,
          defaultNgayAm: 'Ngày ${occ.adjustedDay} tháng ${ev.month} Âm lịch',
        ),
      ),
    );
  }

  void _navigateToAddEvent() async {
    final result = await Navigator.push<EventItem>(
      context,
      MaterialPageRoute(builder: (ctx) => const AddEditEventScreen()),
    );
    if (result != null) {
      widget.onEventAdded(result);
    }
  }

  void _navigateToEventDetail(EventItem ev) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => EventDetailScreen(
          event: ev,
          profile: widget.profile,
          onProfileUpdated: widget.onProfileUpdated,
          onEventUpdated: widget.onEventUpdated,
          onEventDeleted: () => widget.onEventDeleted(ev.id),
        ),
      ),
    );
  }

  void _openAddNoteSheet(BuildContext context) async {
    final newNote = await showModalBottomSheet<DailyNoteItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddEditNoteSheet(initialDate: DateTime.now()),
    );
    if (newNote != null) {
      widget.onNoteAdded(newNote);
    }
  }
}
