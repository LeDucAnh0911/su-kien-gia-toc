/// Màn hình Lịch Tháng Âm - Dương & Ghi Chú Theo Ngày (Hoàng Gia & Đa Nền Tảng)
import 'package:flutter/material.dart';
import '../lunar_engine.dart';
import '../models/event_model.dart';
import '../models/note_model.dart';
import '../services/event_calculator.dart';
import '../services/storage_service.dart';
import '../widgets/add_edit_note_sheet.dart';
import 'event_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
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

  const CalendarScreen({
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
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _displayedMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryRed = const Color(0xFF8B1E0F);
    final goldColor = const Color(0xFFD4AF37);

    // Tính toán các sự kiện giỗ
    final occurrences = EventCalculator.getSortedOccurrences(
      widget.events,
      DateTime(_displayedMonth.year, _displayedMonth.month, 1),
    );
    final selectedDayEvents = occurrences.where((occ) {
      final d = occ.nextSolarDate;
      return d.year == _selectedDate.year && d.month == _selectedDate.month && d.day == _selectedDate.day;
    }).toList();

    // Các ghi chú của ngày được chọn
    final selectedDayNotes = widget.notes.where((n) {
      return n.date.year == _selectedDate.year &&
          n.date.month == _selectedDate.month &&
          n.date.day == _selectedDate.day;
    }).toList();

    // Thông tin âm lịch của ngày được chọn
    final selectedLunar = VietnameseLunarEngine.solarToLunar(
      _selectedDate.day,
      _selectedDate.month,
      _selectedDate.year,
    );
    final canChiYear = VietnameseLunarEngine.getCanChiYear(selectedLunar.year);
    final canChiDay = VietnameseLunarEngine.getCanChiDay(selectedLunar.jd);
    final solarTerm = VietnameseLunarEngine.getSolarTerm(_selectedDate.day, _selectedDate.month, _selectedDate.year);
    final isHoangDao = VietnameseLunarEngine.isHoangDaoDay(selectedLunar.jd, selectedLunar.month);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Âm Dương Vạn Niên', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: isDark ? const Color(0xFF1E1715) : primaryRed,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.today_rounded),
            tooltip: 'Trở về Hôm nay',
            onPressed: () {
              final now = DateTime.now();
              setState(() {
                _displayedMonth = DateTime(now.year, now.month, 1);
                _selectedDate = DateTime(now.year, now.month, now.day);
              });
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 768;

          final monthControls = _buildMonthControls(isDark, primaryRed, goldColor);
          final weekdayHeaders = _buildWeekdayHeaders(isDark);
          final monthGrid = _buildMonthGrid(occurrences, widget.notes, isDark, primaryRed, goldColor);
          final selectedDayPane = _buildSelectedDayPane(
            selectedLunar: selectedLunar,
            canChiYear: canChiYear,
            canChiDay: canChiDay,
            solarTerm: solarTerm,
            isHoangDao: isHoangDao,
            selectedDayEvents: selectedDayEvents,
            selectedDayNotes: selectedDayNotes,
            isDark: isDark,
            primaryRed: primaryRed,
            goldColor: goldColor,
          );

          if (isWide) {
            // MÀN HÌNH RỘNG (2 CỘT SONG SONG)
            return Row(
              children: [
                // Cột trái: Lịch tháng
                Expanded(
                  flex: 6,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2C9B0)),
                      ),
                    ),
                    child: Column(
                      children: [
                        monthControls,
                        weekdayHeaders,
                        Expanded(child: monthGrid),
                      ],
                    ),
                  ),
                ),
                // Cột phải: Chi tiết ngày
                Expanded(
                  flex: 5,
                  child: selectedDayPane,
                ),
              ],
            );
          }

          // MÀN HÌNH DI ĐỘNG (XẾP DỌC)
          return Column(
            children: [
              monthControls,
              weekdayHeaders,
              Expanded(
                flex: 5,
                child: monthGrid,
              ),
              const Divider(height: 1, thickness: 1),
              Expanded(
                flex: 5,
                child: selectedDayPane,
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
        tooltip: 'Thêm ghi chú cho ngày đang chọn',
        onPressed: () => _openAddNoteSheet(context),
        child: const Icon(Icons.note_add_rounded),
      ),
    );
  }

  // THANH CHUYỂN THÁNG
  Widget _buildMonthControls(bool isDark, Color primaryRed, Color goldColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF241D1A) : const Color(0xFFFBF4EB),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white12 : const Color(0xFFEADBCE),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 24),
            tooltip: 'Tháng trước',
            onPressed: () {
              setState(() {
                _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
                _selectedDate = _displayedMonth;
              });
            },
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Tháng ${_displayedMonth.month} năm ${_displayedMonth.year}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? goldColor : primaryRed,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Âm Lịch & Dương Lịch Song Hành',
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 24),
            tooltip: 'Tháng sau',
            onPressed: () {
              setState(() {
                _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
                _selectedDate = _displayedMonth;
              });
            },
          ),
        ],
      ),
    );
  }

  // TIÊU ĐỀ THỨ
  Widget _buildWeekdayHeaders(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1C1614) : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'].map((w) {
          final isWeekend = w == 'CN' || w == 'T7';
          return Expanded(
            child: Center(
              child: Text(
                w,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                  color: isWeekend ? Colors.red[700] : (isDark ? Colors.grey[400] : const Color(0xFF5D4037)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // LƯỚI THÁNG
  Widget _buildMonthGrid(
    List<EventOccurrence> occurrences,
    List<DailyNoteItem> notes,
    bool isDark,
    Color primaryRed,
    Color goldColor,
  ) {
    final year = _displayedMonth.year;
    final month = _displayedMonth.month;

    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = firstDayOfMonth.weekday; // 1..7 (Monday..Sunday)
    final totalCells = 42;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.08,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        final dayOffset = index - (firstWeekday - 1);
        if (dayOffset < 0 || dayOffset >= daysInMonth) {
          return const SizedBox.shrink();
        }

        final cellDate = DateTime(year, month, dayOffset + 1);
        final isToday = cellDate.isAtSameMomentAs(today);
        final isSelected = cellDate.year == _selectedDate.year &&
            cellDate.month == _selectedDate.month &&
            cellDate.day == _selectedDate.day;

        // Tính ngày âm
        final lunar = VietnameseLunarEngine.solarToLunar(cellDate.day, cellDate.month, cellDate.year);
        final isRamOrMung1 = lunar.day == 1 || lunar.day == 15;
        final lunarText = lunar.day == 1 ? '${lunar.day}/${lunar.month}' : '${lunar.day}';

        // Kiểm tra xem ngày này có sự kiện giỗ không
        final dayEvents = occurrences.where((occ) {
          final d = occ.nextSolarDate;
          return d.year == cellDate.year && d.month == cellDate.month && d.day == cellDate.day;
        }).toList();
        final hasEvent = dayEvents.isNotEmpty;

        // Kiểm tra xem ngày này có ghi chú không
        final dayNotes = notes.where((n) {
          return n.date.year == cellDate.year && n.date.month == cellDate.month && n.date.day == cellDate.day;
        }).toList();
        final hasNotes = dayNotes.isNotEmpty;

        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            setState(() => _selectedDate = cellDate);
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? goldColor.withOpacity(0.25) : const Color(0xFFFFE0B2))
                  : (isToday ? (isDark ? Colors.teal.withOpacity(0.2) : const Color(0xFFE8F5E9)) : null),
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: primaryRed, width: 1.8)
                  : (isToday ? Border.all(color: Colors.green, width: 1.2) : null),
            ),
            child: LayoutBuilder(builder: (context, cellSize) {
              final isWide = cellSize.maxWidth >= 100 && cellSize.maxHeight >= 75;
              final showTitles = cellSize.maxWidth >= 75 && cellSize.maxHeight >= 60;
              final solarFontSize = isWide ? 25.0 : (showTitles ? 20.0 : 16.5);
              final lunarFontSize = isWide ? 13.5 : (showTitles ? 11.5 : 10.0);

              Widget marker(Color color, String? title) => Row(children: [
                Container(
                  width: isWide ? 6 : 5,
                  height: isWide ? 6 : 5,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                if (title != null) ...[
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isWide ? 11.5 : 10,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ]);

              return Padding(
                padding: EdgeInsets.all(isWide ? 6 : 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${cellDate.day}',
                      style: TextStyle(
                        fontSize: solarFontSize,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        color: cellDate.weekday == DateTime.sunday ? Colors.red[700] : null,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      lunarText,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: TextStyle(
                        fontSize: lunarFontSize,
                        height: 1.1,
                        fontWeight: isRamOrMung1 ? FontWeight.bold : FontWeight.w600,
                        color: isRamOrMung1
                            ? Colors.red[800]
                            : (isDark ? Colors.amber[200] : primaryRed),
                      ),
                    ),
                    const Spacer(),
                    if (showTitles) ...[
                      if (hasEvent) marker(primaryRed, dayEvents.first.event.title),
                      if (hasNotes) marker(Colors.teal, dayNotes.first.title),
                    ] else if (hasEvent || hasNotes)
                      Row(children: [
                        if (hasEvent) marker(primaryRed, null),
                        if (hasEvent && hasNotes) const SizedBox(width: 4),
                        if (hasNotes) marker(Colors.teal, null),
                      ]),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }

  // KHỐI CHI TIẾT NGÀY ĐANG CHỌN
  Widget _buildSelectedDayPane({
    required LunarDate selectedLunar,
    required String canChiYear,
    required String canChiDay,
    required String solarTerm,
    required bool isHoangDao,
    required List<EventOccurrence> selectedDayEvents,
    required List<DailyNoteItem> selectedDayNotes,
    required bool isDark,
    required Color primaryRed,
    required Color goldColor,
  }) {
    return Container(
      color: isDark ? const Color(0xFF1E1715) : const Color(0xFFFDFBF7),
      child: Column(
        children: [
          // Header ngày được chọn
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF28201D) : const Color(0xFFF8EFE4),
              border: Border(bottom: BorderSide(color: goldColor.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Text(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryRed,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Âm: ${selectedLunar.day}/${selectedLunar.month}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            isHoangDao ? '• Hoàng Đạo' : '• Hắc Đạo',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isHoangDao ? Colors.green[800] : Colors.orange[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Năm $canChiYear • Ngày $canChiDay • $solarTerm',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? Colors.grey[300] : const Color(0xFF6D4C41),
                        ),
                      ),
                    ],
                  ),
                ),
                // Nút thêm Ghi Chú
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add, size: 15),
                  label: const Text('Ghi Chú', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: () => _openAddNoteSheet(context),
                ),
              ],
            ),
          ),

          // Danh sách sự kiện & ghi chú
          Expanded(
            child: (selectedDayNotes.isEmpty && selectedDayEvents.isEmpty)
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_calendar_outlined, size: 36, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'Chưa có sự kiện hay việc cần nhớ cho ngày này',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.note_add, size: 15),
                          label: const Text('Thêm việc cần nhớ ngay', style: TextStyle(fontSize: 12)),
                          onPressed: () => _openAddNoteSheet(context),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      // SỰ KIỆN GIỖ
                      if (selectedDayEvents.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(Icons.local_fire_department, size: 16, color: primaryRed),
                            const SizedBox(width: 6),
                            Text(
                              'SỰ KIỆN GIỖ TRONG NGÀY (${selectedDayEvents.length})',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: primaryRed,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ...selectedDayEvents.map((occ) => _buildEventCard(occ, isDark, primaryRed, goldColor)),
                        const SizedBox(height: 12),
                      ],

                      // GHI CHÚ
                      if (selectedDayNotes.isNotEmpty) ...[
                        Row(
                          children: const [
                            Icon(Icons.checklist, size: 16, color: Colors.teal),
                            SizedBox(width: 6),
                            Text(
                              'GHI CHÚ & VIỆC CẦN LÀM',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ...selectedDayNotes.map((note) => _buildNoteCard(note, isDark)),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(EventOccurrence occ, bool isDark, Color primaryRed, Color goldColor) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: goldColor.withOpacity(0.5)),
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF352622) : const Color(0xFFFBE9E7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.local_fire_department, color: primaryRed, size: 20),
        ),
        title: Text(occ.event.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(
          occ.event.calendar == CalendarType.lunar
              ? 'Chính kỵ Âm: Ngày ${occ.adjustedDay}/${occ.event.month} Âm'
              : 'Dương lịch: Ngày ${occ.event.day}/${occ.event.month}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => EventDetailScreen(
                event: occ.event,
                profile: widget.profile,
                onProfileUpdated: widget.onProfileUpdated,
                onEventUpdated: widget.onEventUpdated,
                onEventDeleted: () => widget.onEventDeleted(occ.event.id),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoteCard(DailyNoteItem note, bool isDark) {
    Color catColor = Colors.teal;
    String catLabel = 'Việc cần làm';

    switch (note.category) {
      case NoteCategory.offering:
        catColor = const Color(0xFF8B1E0F);
        catLabel = 'Đồ lễ cúng';
        break;
      case NoteCategory.family:
        catColor = Colors.indigo;
        catLabel = 'Gia tộc';
        break;
      case NoteCategory.general:
        catColor = Colors.orange[800]!;
        catLabel = 'Ghi nhớ';
        break;
      case NoteCategory.todo:
        catColor = Colors.teal;
        catLabel = 'Cần làm';
        break;
    }

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Checkbox(
              value: note.isCompleted,
              activeColor: Colors.teal,
              onChanged: (val) {
                note.isCompleted = val ?? false;
                widget.onNoteUpdated(note);
              },
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                      if (note.time != null) ...[
                        const SizedBox(width: 6),
                        Text('• ${note.time}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    note.title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      decoration: note.isCompleted ? TextDecoration.lineThrough : null,
                      color: note.isCompleted ? Colors.grey : null,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
              onPressed: () => widget.onNoteDeleted(note.id),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddNoteSheet(BuildContext context) async {
    final newNote = await showModalBottomSheet<DailyNoteItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddEditNoteSheet(initialDate: _selectedDate),
    );

    if (newNote != null) {
      widget.onNoteAdded(newNote);
    }
  }
}
