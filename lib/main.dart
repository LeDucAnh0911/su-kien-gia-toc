/// Ứng dụng Sổ Giỗ & Kỷ Niệm (Lịch Gia Tộc & Ghi Chú)
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'lunar_engine.dart';
import 'models/event_model.dart';
import 'models/note_model.dart';
import 'models/family_person.dart';
import 'screens/calendar_screen.dart';
import 'screens/home_screen.dart';
import 'screens/prayers_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/family_screen.dart';
import 'services/storage_service.dart';
import 'services/firebase_sync_service.dart';
import 'services/event_reminder_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeDateFormatting('vi_VN', null);
  } catch (_) {}
  try {
    await EventReminderService().loadSettings();
  } catch (_) {}
  runApp(const SoGioApp());

  // Kết nối Firebase ngầm, tuyệt đối không chặn khởi chạy giao diện
  FirebaseSyncService().initialize().catchError((_) => false);
}

class SoGioApp extends StatefulWidget {
  const SoGioApp({super.key});

  @override
  State<SoGioApp> createState() => _SoGioAppState();
}

class _SoGioAppState extends State<SoGioApp> {
  final StorageService _storageService = StorageService();
  List<EventItem> _events = [];
  List<DailyNoteItem> _notes = [];
  List<FamilyPerson> _familyPeople = [];
  UserProfile _profile = UserProfile();
  bool _isLoading = true;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final loadedEvents = await _storageService.loadEvents();
    final loadedNotes = await _storageService.loadNotes();
    final loadedProfile = await _storageService.loadProfile();
    final loadedFamily = await _storageService.loadFamilyPeople();
    setState(() {
      _events = loadedEvents;
      _notes = loadedNotes;
      _profile = loadedProfile;
      _familyPeople = loadedFamily;
      _isLoading = false;
    });
  }

  // --- QUẢN LÝ SỰ KIỆN GIỖ ---
  void _onEventAdded(EventItem event) {
    setState(() => _events.add(event));
    _storageService.saveEvents(_events);
  }

  void _onEventUpdated(EventItem updatedEvent) {
    setState(() {
      final index = _events.indexWhere((e) => e.id == updatedEvent.id);
      if (index != -1) _events[index] = updatedEvent;
    });
    _storageService.saveEvents(_events);
  }

  void _onEventDeleted(String eventId) {
    setState(() => _events.removeWhere((e) => e.id == eventId));
    _storageService.saveEvents(_events);
  }

  // --- QUẢN LÝ GHI CHÚ THEO NGÀY ---
  void _onNoteAdded(DailyNoteItem note) {
    setState(() => _notes.add(note));
    _storageService.saveNotes(_notes);
  }

  void _onNoteUpdated(DailyNoteItem updatedNote) {
    setState(() {
      final index = _notes.indexWhere((n) => n.id == updatedNote.id);
      if (index != -1) _notes[index] = updatedNote;
    });
    _storageService.saveNotes(_notes);
  }

  void _onNoteDeleted(String noteId) {
    setState(() => _notes.removeWhere((n) => n.id == noteId));
    _storageService.saveNotes(_notes);
  }

  void _onFamilySaved(FamilyPerson person) {
    setState(() {
      final next = _familyPeople.where((p) => p.id != person.id).toList()..add(person);
      _familyPeople = next.map((p) {
        if (p.id == person.id) return p;
        final spouses = p.spouseIds.where((id) => id != person.id).toList();
        if (person.spouseIds.contains(p.id)) spouses.add(person.id);
        return p.copyWith(spouseIds: spouses);
      }).toList();
    });
    _storageService.saveFamilyPeople(_familyPeople);
  }

  void _onFamilyDeleted(String id) {
    setState(() {
      _familyPeople = _familyPeople.where((p) => p.id != id).map((p) => p.copyWith(
        fatherId: p.fatherId == id ? '' : p.fatherId,
        motherId: p.motherId == id ? '' : p.motherId,
        spouseIds: p.spouseIds.where((spouse) => spouse != id).toList(),
      )).toList();
    });
    _storageService.saveFamilyPeople(_familyPeople);
  }

  // --- PROFILE & RESTORE ---
  void _onProfileUpdated(UserProfile newProfile) {
    setState(() => _profile = newProfile);
    _storageService.saveProfile(newProfile);
  }

  void _onDataRestored(List<EventItem> newEvents, List<DailyNoteItem> newNotes, List<FamilyPerson> newFamily) {
    setState(() {
      _events = newEvents;
      _notes = newNotes;
      _familyPeople = newFamily;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryRed = const Color(0xFF8B1E0F); // Đỏ Chu Sa hoàng gia
    final goldColor = const Color(0xFFD4AF37); // Vàng Hoàng Kim
    final isDark = _profile.isDarkMode;

    final lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryRed,
        brightness: Brightness.light,
        primary: primaryRed,
        secondary: goldColor,
        surface: const Color(0xFFFDFBF7),
      ),
      scaffoldBackgroundColor: const Color(0xFFF7F2E8),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFEADFCF), width: 0.8),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
    );

    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryRed,
        brightness: Brightness.dark,
        primary: const Color(0xFFB83A28),
        secondary: goldColor,
        surface: const Color(0xFF241D1A),
      ),
      scaffoldBackgroundColor: const Color(0xFF191412),
      cardTheme: CardThemeData(
        color: const Color(0xFF241D1A),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF3D312B), width: 0.8),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1715),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
    );

    return MaterialApp(
      title: 'Sự Kiện Gia Tộc',
      debugShowCheckedModeBanner: false,
      theme: isDark ? darkTheme : lightTheme,
      home: _isLoading
          ? Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: primaryRed),
                    const SizedBox(height: 18),
                    const Text(
                      'SỰ KIỆN GIA TỘC',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Color(0xFF8B1E0F),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Hiếu Đạo Tiên Tổ • Gìn Giữ Cội Nguồn',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final isWideScreen = constraints.maxWidth >= 820;

                final screens = [
                  // TAB 0: TRANG CHỦ
                  HomeScreen(
                    events: _events,
                    notes: _notes,
                    profile: _profile,
                    onProfileUpdated: _onProfileUpdated,
                    onEventAdded: _onEventAdded,
                    onEventUpdated: _onEventUpdated,
                    onEventDeleted: _onEventDeleted,
                    onNoteAdded: _onNoteAdded,
                    onNoteUpdated: _onNoteUpdated,
                    onNoteDeleted: _onNoteDeleted,
                    onNavigateTab: (idx) => setState(() => _currentTabIndex = idx),
                  ),

                  // TAB 1: LỊCH THÁNG ÂM - DƯƠNG & GHI CHÚ
                  CalendarScreen(
                    events: _events,
                    notes: _notes,
                    profile: _profile,
                    onProfileUpdated: _onProfileUpdated,
                    onEventAdded: _onEventAdded,
                    onEventUpdated: _onEventUpdated,
                    onEventDeleted: _onEventDeleted,
                    onNoteAdded: _onNoteAdded,
                    onNoteUpdated: _onNoteUpdated,
                    onNoteDeleted: _onNoteDeleted,
                  ),

                  // TAB 2: KHO VĂN KHẤN CỔ TRUYỀN
                  PrayersScreen(
                    profile: _profile,
                    onProfileUpdated: _onProfileUpdated,
                  ),

                  // TAB 3: GIA PHẢ DÒNG HỌ
                  FamilyScreen(
                    people: _familyPeople,
                    onSaved: _onFamilySaved,
                    onDeleted: _onFamilyDeleted,
                    giaChuName: _profile.giaChu,
                    profile: _profile,
                    onProfileUpdated: _onProfileUpdated,
                  ),

                  // TAB 4: CÀI ĐẶT & SAO LƯU
                  SettingsScreen(
                    profile: _profile,
                    events: _events,
                    notes: _notes,
                    familyPeople: _familyPeople,
                    storageService: _storageService,
                    onProfileUpdated: _onProfileUpdated,
                    onDataRestored: _onDataRestored,
                  ),
                ];

                if (!isWideScreen) {
                  // GIAO DIỆN DI ĐỘNG (MOBILE LAYOUT)
                  return Scaffold(
                    body: IndexedStack(
                      index: _currentTabIndex,
                      children: screens,
                    ),
                    bottomNavigationBar: NavigationBar(
                      selectedIndex: _currentTabIndex,
                      indicatorColor: goldColor.withOpacity(0.25),
                      height: 64,
                      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                      onDestinationSelected: (index) => setState(() => _currentTabIndex = index),
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.home_outlined),
                          selectedIcon: Icon(Icons.home, color: Color(0xFF8B1E0F)),
                          label: 'Trang Chủ',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.calendar_month_outlined),
                          selectedIcon: Icon(Icons.calendar_month, color: Color(0xFF8B1E0F)),
                          label: 'Lịch Âm',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.auto_stories_outlined),
                          selectedIcon: Icon(Icons.auto_stories, color: Color(0xFF8B1E0F)),
                          label: 'Văn Khấn',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.account_tree_outlined),
                          selectedIcon: Icon(Icons.account_tree, color: Color(0xFF8B1E0F)),
                          label: 'Gia Phả',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.settings_outlined),
                          selectedIcon: Icon(Icons.settings, color: Color(0xFF8B1E0F)),
                          label: 'Cài Đặt',
                        ),
                      ],
                    ),
                  );
                }

                // GIAO DIỆN MÁY TÍNH / MÀN HÌNH RỘNG (DESKTOP WIDESCREEN DASHBOARD)
                final now = DateTime.now();
                final todayLunar = VietnameseLunarEngine.solarToLunar(now.day, now.month, now.year);
                final canChiYear = VietnameseLunarEngine.getCanChiYear(todayLunar.year);
                final canChiDay = VietnameseLunarEngine.getCanChiDay(todayLunar.jd);

                return Scaffold(
                  body: Row(
                    children: [
                      // SIDEBAR TRÁI HOÀNG GIA CHO MÁY TÍNH
                      Container(
                        width: 270,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1715) : const Color(0xFF7A180B),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(2, 0),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Header Logo Cung Đình
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: goldColor.withOpacity(0.3), width: 1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: goldColor.withOpacity(0.2),
                                      border: Border.all(color: goldColor, width: 1.5),
                                    ),
                                    child: Icon(Icons.temple_buddhist, color: goldColor, size: 26),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'SỰ KIỆN GIA TỘC',
                                          style: TextStyle(
                                            color: goldColor,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14.5,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'Lịch Âm • Lễ Nghi • Hiếu Nghĩa',
                                          style: TextStyle(color: Colors.white70, fontSize: 10.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Widget Ngày Giờ Âm Dương Hôm Nay
                            Container(
                              margin: const EdgeInsets.all(14),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: goldColor.withOpacity(0.25)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.brightness_medium, color: goldColor, size: 14),
                                      const SizedBox(width: 6),
                                      Text(
                                        'HÔM NAY',
                                        style: TextStyle(
                                          color: goldColor,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Ngày ${todayLunar.day} Tháng ${todayLunar.month}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Năm $canChiYear • Ngày $canChiDay',
                                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Dương lịch: ${now.day}/${now.month}/${now.year}',
                                    style: TextStyle(color: goldColor.withOpacity(0.9), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),

                            // Danh Sách Menu Sidebar
                            Expanded(
                              child: ListView(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                children: [
                                  _sidebarItem(
                                    icon: Icons.home,
                                    title: 'Trang Chủ Sự Kiện',
                                    badge: '${_events.length}',
                                    isSelected: _currentTabIndex == 0,
                                    onTap: () => setState(() => _currentTabIndex = 0),
                                    goldColor: goldColor,
                                  ),
                                  _sidebarItem(
                                    icon: Icons.calendar_month,
                                    title: 'Lịch Âm Dương & Ghi Chú',
                                    isSelected: _currentTabIndex == 1,
                                    onTap: () => setState(() => _currentTabIndex = 1),
                                    goldColor: goldColor,
                                  ),
                                  _sidebarItem(
                                    icon: Icons.auto_stories,
                                    title: 'Kho Văn Khấn Cổ Truyền',
                                    isSelected: _currentTabIndex == 2,
                                    onTap: () => setState(() => _currentTabIndex = 2),
                                    goldColor: goldColor,
                                  ),
                                  _sidebarItem(
                                    icon: Icons.account_tree,
                                    title: 'Gia Phả Dòng Họ',
                                    badge: '${_familyPeople.length}',
                                    isSelected: _currentTabIndex == 3,
                                    onTap: () => setState(() => _currentTabIndex = 3),
                                    goldColor: goldColor,
                                  ),
                                  _sidebarItem(
                                    icon: Icons.settings,
                                    title: 'Cài Đặt & Dữ Liệu',
                                    isSelected: _currentTabIndex == 4,
                                    onTap: () => setState(() => _currentTabIndex = 4),
                                    goldColor: goldColor,
                                  ),
                                ],
                              ),
                            ),

                            // Footer: Dark Mode Toggle & Gia Chủ
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Colors.white.withOpacity(0.1)),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _profile.giaChu.isNotEmpty ? 'Gia chủ: ${_profile.giaChu}' : 'Gia tộc Việt',
                                      style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      isDark ? Icons.light_mode : Icons.dark_mode,
                                      color: goldColor,
                                      size: 18,
                                    ),
                                    tooltip: isDark ? 'Bật chế độ Sáng' : 'Bật chế độ Tối',
                                    onPressed: () {
                                      final updated = UserProfile(
                                        giaChu: _profile.giaChu,
                                        diaChi: _profile.diaChi,
                                        prayerFontSize: _profile.prayerFontSize,
                                        isDarkMode: !isDark,
                                      );
                                      _onProfileUpdated(updated);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // NỘI DUNG CHÍNH (EXPANDED TO FULL SCREEN)
                      Expanded(
                        child: IndexedStack(
                          index: _currentTabIndex,
                          children: screens,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _sidebarItem({
    required IconData icon,
    required String title,
    String? badge,
    required bool isSelected,
    required VoidCallback onTap,
    required Color goldColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.18) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isSelected ? Border.all(color: goldColor.withOpacity(0.6), width: 1) : null,
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: isSelected ? goldColor : Colors.white70, size: 20),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? goldColor : Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF7A180B) : Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
