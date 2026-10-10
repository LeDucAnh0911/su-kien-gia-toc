import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as image;
import '../models/family_person.dart';
import '../services/family_tree_builder.dart';
import '../services/kinship_service.dart';
import '../services/storage_service.dart';
import '../widgets/family_tree_canvas.dart';
import 'paywall_screen.dart';

Uint8List _prepareAvatar(Uint8List bytes) {
  final decoded = image.decodeImage(bytes);
  if (decoded == null) throw const FormatException('Không đọc được ảnh đã chọn.');
  final upright = image.bakeOrientation(decoded);
  final longestSide = upright.width > upright.height ? upright.width : upright.height;
  final resized = longestSide > 512
      ? image.copyResize(
          upright,
          width: upright.width >= upright.height ? 512 : null,
          height: upright.height > upright.width ? 512 : null,
        )
      : upright;
  return Uint8List.fromList(image.encodeJpg(resized, quality: 78));
}

class FamilyScreen extends StatefulWidget {
  final List<FamilyPerson> people;
  final ValueChanged<FamilyPerson> onSaved;
  final ValueChanged<String> onDeleted;
  final String? giaChuName;
  final UserProfile? profile;
  final Function(UserProfile)? onProfileUpdated;

  const FamilyScreen({
    super.key,
    required this.people,
    required this.onSaved,
    required this.onDeleted,
    this.giaChuName,
    this.profile,
    this.onProfileUpdated,
  });

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  // Chế độ xem: 'noi' (Bên nội), 'ngoai' (Bên ngoại), 'all' (Toàn cảnh), 'list' (Danh sách)
  String _viewMode = 'noi';
  String _query = '';
  String _filterBranch = 'all';
  String? _focusPersonId;

  @override
  void initState() {
    super.initState();
    _loadFocusPerson();
  }

  Future<void> _loadFocusPerson() async {
    final savedId = await StorageService().loadFocusPersonId();
    if (savedId != null && savedId.isNotEmpty && mounted) {
      final exists = widget.people.any((p) => p.id == savedId);
      if (exists) {
        setState(() => _focusPersonId = savedId);
      }
    }
  }

  FamilyPerson? _person(String id) {
    for (final p in widget.people) {
      if (p.id == id) return p;
    }
    return null;
  }

  FamilyPerson? get _focusPerson {
    if (widget.people.isEmpty) return null;
    if (_focusPersonId != null) {
      final p = _person(_focusPersonId!);
      if (p != null) return p;
    }
    final name = (widget.giaChuName != null && widget.giaChuName!.trim().isNotEmpty)
        ? widget.giaChuName!
        : '';
    return KinshipService.findDefaultFocusPerson(widget.people, name);
  }

  String _branchLabel(String value) => switch (value) {
    'noi' => 'Bên nội',
    'ngoai' => 'Bên ngoại',
    'vo' => 'Bên vợ',
    'con_chau' => 'Con cháu',
    _ => 'Khác',
  };

  Color _branchColor(String value) => switch (value) {
    'noi' => const Color(0xFF8B1E0F),
    'ngoai' => const Color(0xFF7B1FA2),
    'vo' => const Color(0xFF1976D2),
    'con_chau' => const Color(0xFF00796B),
    _ => const Color(0xFF5D4037),
  };

  List<FamilyPerson> get _filteredList {
    final text = _query.trim().toLowerCase();
    final result = widget.people.where((p) =>
      (_filterBranch == 'all' || p.branch == _filterBranch) &&
      (text.isEmpty ||
       p.name.toLowerCase().contains(text) ||
       p.hometown.toLowerCase().contains(text) ||
       p.notes.toLowerCase().contains(text))).toList();
    result.sort((a, b) {
      final ay = _year(a.birthDate), by = _year(b.birthDate);
      if (ay != by) return ay.compareTo(by);
      return a.name.compareTo(b.name);
    });
    return result;
  }

  int _year(String date) => int.tryParse(date.split('/').last) ?? 9999;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryRed = const Color(0xFF8B1E0F);
    final focus = _focusPerson;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gia Phả Dòng Họ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Color(0xFFFFD700)),
            tooltip: 'Thông tin bản thử nghiệm miễn phí',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => PaywallScreen(
                    profile: widget.profile ?? UserProfile(),
                    storageService: StorageService(),
                    onProfileUpdated: widget.onProfileUpdated ?? (_) {},
                  ),
                ),
              );
            },
          ),
          if (focus != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFF3E5AB),
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
                icon: const Icon(Icons.stars_rounded, size: 16, color: Color(0xFFF3E5AB)),
                label: Text(
                  'Tôi: ${focus.name}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _chooseFocusPersonDialog(),
              ),
            ),
        ],
      ),
      floatingActionButton: widget.people.isEmpty ? null : FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Thêm người'),
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 1. THANH CHUYỂN ĐỔI CHẾ ĐỘ XEM
          _buildViewModeBar(isDark),

          // 2. NỘI DUNG CHÍNH (CÂY PHẢ HỆ HOẶC DANH SÁCH)
          Expanded(
            child: widget.people.isEmpty
                ? _buildEmptyState(
                    title: 'Gia phả chưa có ai',
                    message: 'Bắt đầu từ bản thân hoặc một người lớn tuổi trong gia đình, rồi nối cha mẹ và con cháu.',
                    action: 'Thêm người đầu tiên',
                    onAction: () => _edit(),
                  )
                : _viewMode == 'list'
                    ? _buildListView(isDark, focus)
                    : _buildTreeView(isDark, focus),
          ),
        ],
      ),
    );
  }

  /// Thanh chuyển đổi chế độ xem thích ứng (Bên Nội / Bên Ngoại / Bên Vợ / Toàn Cảnh / Danh Sách)
  Widget _buildViewModeBar(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final countNoi = widget.people.where((p) => p.branch == 'noi').length;
        final countNgoai = widget.people.where((p) => p.branch == 'ngoai').length;
        final countVo = widget.people.where((p) => p.branch == 'vo').length;
        final isFemale = _focusPerson?.gender == 'female';
        final spouseTabLabel = isFemale ? 'Bên Chồng' : 'Bên Vợ';
        final spouseSub = isFemale ? 'Họ Chồng' : 'Họ Vợ';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF221A18) : const Color(0xFFFAF5ED),
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white12 : const Color(0xFFE5D7C5),
                width: 1,
              ),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildModeSegment(
                  mode: 'noi',
                  icon: Icons.park_outlined,
                  label: 'Bên Nội',
                  subtitle: 'Họ Cha',
                  count: countNoi,
                ),
                const SizedBox(width: 8),
                _buildModeSegment(
                  mode: 'ngoai',
                  icon: Icons.filter_vintage_outlined,
                  label: 'Bên Ngoại',
                  subtitle: 'Họ Mẹ',
                  count: countNgoai,
                ),
                const SizedBox(width: 8),
                _buildModeSegment(
                  mode: 'vo',
                  icon: Icons.favorite_border,
                  label: spouseTabLabel,
                  subtitle: spouseSub,
                  count: countVo,
                ),
                const SizedBox(width: 8),
                _buildModeSegment(
                  mode: 'all',
                  icon: Icons.account_tree_outlined,
                  label: 'Toàn Cảnh',
                  subtitle: 'Hợp nhất 3 bên',
                  count: widget.people.length,
                ),
                const SizedBox(width: 8),
                _buildModeSegment(
                  mode: 'list',
                  icon: Icons.format_list_bulleted_rounded,
                  label: 'Danh Sách',
                  subtitle: 'Tìm & lọc',
                  count: widget.people.length,
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildModeSegment({
    required String mode,
    required IconData icon,
    required String label,
    required String subtitle,
    required int count,
  }) {
    final isSelected = _viewMode == mode;
    const activeColor = Color(0xFF8B1E0F);
    const activeBg = Color(0xFFF5E4D8);

    return InkWell(
      onTap: () => setState(() => _viewMode = mode),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFDAC7B2),
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: activeColor.withValues(alpha: 0.15), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? activeColor : Colors.grey[700]),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? activeColor : const Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected ? activeColor : Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected ? activeColor.withValues(alpha: 0.8) : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Khung hiển thị Cây Phả Hệ phân cấp từ trên xuống
  Widget _buildTreeView(bool isDark, FamilyPerson? focus) {
    if (focus == null) {
      return const Center(child: Text('Vui lòng thêm ít nhất một người thân'));
    }

    final roots = FamilyTreeBuilder.buildTree(
      people: widget.people,
      focusPerson: focus,
      mode: _viewMode,
    );

    if (roots.isEmpty) {
      final isFemale = focus.gender == 'female';
      final spouseLabel = isFemale ? 'bên chồng' : 'bên vợ';
      return _buildEmptyState(
        title: _viewMode == 'vo'
            ? 'Chưa có thông tin dòng họ $spouseLabel'
            : 'Chưa có thông tin cho nhánh này',
        message: _viewMode == 'vo'
            ? 'Bạn có thể thêm hồ sơ người thân $spouseLabel hoặc bấm vào thẻ Vợ/Chồng để kết nối cha mẹ.'
            : 'Bạn có thể thêm người thân hoặc chuyển sang xem Bên Nội / Bên Ngoại / Bên Vợ / Toàn Cảnh.',
        action: 'Thêm người thân',
        onAction: () => _edit(initialBranch: _viewMode == 'ngoai' ? 'ngoai' : (_viewMode == 'vo' ? 'vo' : 'noi')),
      );
    }

    return Column(
      children: [
        // Thanh gợi ý nhỏ
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: isDark ? const Color(0xFF1E1816) : const Color(0xFFFFFDF8),
          child: Row(
            children: [
              const Icon(Icons.touch_app_outlined, size: 14, color: Color(0xFF8B1E0F)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Kéo vuốt tự do • Chụm 2 ngón phóng to/thu nhỏ • Chạm thẻ xem hồ sơ',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : const Color(0xFF6B5848),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        // Canvas cây phân cấp
        Expanded(
          child: FamilyTreeCanvas(
            roots: roots,
            focusPerson: focus,
            onPersonTap: (p) => _detail(p),
          ),
        ),
      ],
    );
  }

  /// Khung danh sách tìm kiếm và lọc
  Widget _buildListView(bool isDark, FamilyPerson? focus) {
    final people = _filteredList;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        // Tìm kiếm
        TextField(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: 'Tìm theo tên, quê quán, ghi chú...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 10),

        // Lọc theo nhánh
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final entry in [
                ('all', 'Tất cả (${widget.people.length})'),
                ('noi', 'Bên nội (${widget.people.where((p) => p.branch == 'noi').length})'),
                ('ngoai', 'Bên ngoại (${widget.people.where((p) => p.branch == 'ngoai').length})'),
                ('vo', 'Bên vợ (${widget.people.where((p) => p.branch == 'vo').length})'),
                ('con_chau', 'Con cháu (${widget.people.where((p) => p.branch == 'con_chau').length})'),
                ('khac', 'Khác (${widget.people.where((p) => p.branch == 'khac').length})'),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(entry.$2, style: const TextStyle(fontSize: 12)),
                    selected: _filterBranch == entry.$1,
                    onSelected: (_) => setState(() => _filterBranch = entry.$1),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Text(
          'Kết quả: ${people.length} người',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B1E0F)),
        ),
        const SizedBox(height: 8),

        if (people.isEmpty)
          _buildEmptyState(
            title: 'Không tìm thấy người phù hợp',
            message: 'Thử đổi nhánh hoặc từ khóa tìm kiếm.',
            action: null,
            onAction: null,
          )
        else
          ...people.map((p) => _buildPersonListCard(p, isDark, focus)),
      ],
    );
  }

  Widget _buildPersonListCard(FamilyPerson p, bool isDark, FamilyPerson? focus) {
    final kinship = focus != null
        ? KinshipService.getKinshipTitle(p, focus, widget.people)
        : '';
    final isMe = focus != null && p.id == focus.id;
    final isFemale = p.gender == 'female';
    final branchColor = _branchColor(p.branch);

    final spouses = p.spouseIds.map(_person).whereType<FamilyPerson>().toList();
    final children = widget.people.where((c) => c.fatherId == p.id || c.motherId == p.id).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isMe ? const Color(0xFFD4AF37) : (isDark ? Colors.white12 : const Color(0xFFE8DDCF)),
          width: isMe ? 2.0 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: () => _detail(p),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: isMe
                    ? const Color(0xFFFFE082)
                    : (isFemale ? const Color(0xFFFCE4EC) : const Color(0xFFE3F2FD)),
                backgroundImage: (p.avatarBase64 != null && p.avatarBase64!.isNotEmpty)
                    ? MemoryImage(base64Decode(p.avatarBase64!))
                    : null,
                child: (p.avatarBase64 == null || p.avatarBase64!.isEmpty)
                    ? Icon(
                        isFemale ? Icons.face_3 : Icons.person,
                        color: isFemale ? const Color(0xFFD81B60) : const Color(0xFF1976D2),
                        size: 24,
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // Thông tin
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            p.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (kinship.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isMe ? const Color(0xFFD4AF37) : branchColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isMe ? '⭐ $kinship' : kinship,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: isMe ? Colors.black87 : branchColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Ngày sinh / mất & quê quán
                    Wrap(
                      spacing: 8,
                      children: [
                        if (p.birthDate.isNotEmpty)
                          Text('Sinh: ${p.birthDate}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        if (p.deathDate.isNotEmpty)
                          Text('Mất: ${p.deathDate}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        if (p.hometown.isNotEmpty)
                          Text('Quê: ${p.hometown}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Vợ chồng & con cái
                    Wrap(
                      spacing: 8,
                      children: [
                        if (spouses.isNotEmpty)
                          Text(
                            '⚭ ${spouses.map((s) => s.name).join(', ')}',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF8B2500), fontWeight: FontWeight.w600),
                          ),
                        if (children.isNotEmpty)
                          Text(
                            '${children.length} con',
                            style: const TextStyle(fontSize: 11.5, color: Colors.teal, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String message,
    required String? action,
    required VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.family_restroom_rounded, size: 54, color: Color(0xFF8B1E0F)),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, height: 1.4)),
            if (action != null && onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.group_add),
                label: Text(action),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B1E0F)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Dialog chọn người làm mốc danh xưng ("Tôi / Bản thân")
  void _chooseFocusPersonDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.stars_rounded, color: Color(0xFFD4AF37)),
            SizedBox(width: 8),
            Text('Chọn người làm mốc (Tôi)', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Danh xưng (Ông, Bà, Bố, Mẹ, Chú, Bác, Vợ, Con...) sẽ được tính toán theo góc nhìn của người này.',
                style: TextStyle(fontSize: 12.5, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView(
                  shrinkWrap: true,
                  children: widget.people.map((p) {
                    final isSelected = p.id == _focusPerson?.id;
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        p.gender == 'female' ? Icons.face_3 : Icons.person,
                        color: p.gender == 'female' ? const Color(0xFFD81B60) : const Color(0xFF1976D2),
                      ),
                      title: Text(p.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      subtitle: Text(_branchLabel(p.branch)),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF8B1E0F)) : null,
                      onTap: () {
                        setState(() => _focusPersonId = p.id);
                        StorageService().saveFocusPersonId(p.id);
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );
  }

  /// Chi tiết một người trong BottomSheet
  void _detail(FamilyPerson p) {
    final focus = _focusPerson;
    final kinship = focus != null ? KinshipService.getKinshipTitle(p, focus, widget.people) : '';
    final isMe = focus != null && p.id == focus.id;

    final children = widget.people.where((c) => c.fatherId == p.id || c.motherId == p.id).toList();
    final siblings = widget.people.where((s) => s.id != p.id &&
      ((p.fatherId.isNotEmpty && s.fatherId == p.fatherId) ||
       (p.motherId.isNotEmpty && s.motherId == p.motherId))).toList();
    final parents = [p.fatherId, p.motherId].map(_person).whereType<FamilyPerson>().toList();
    final spouses = p.spouseIds.map(_person).whereType<FamilyPerson>().toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.88,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              // Tiêu đề & Vai vế
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: isMe
                        ? const Color(0xFFFFE082)
                        : (p.gender == 'female' ? const Color(0xFFFCE4EC) : const Color(0xFFE3F2FD)),
                    backgroundImage: (p.avatarBase64 != null && p.avatarBase64!.isNotEmpty)
                        ? MemoryImage(base64Decode(p.avatarBase64!))
                        : null,
                    child: (p.avatarBase64 == null || p.avatarBase64!.isEmpty)
                        ? Icon(
                            p.gender == 'female' ? Icons.face_3 : Icons.person,
                            size: 32,
                            color: p.gender == 'female' ? const Color(0xFFD81B60) : const Color(0xFF1976D2),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          children: [
                            if (kinship.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isMe ? const Color(0xFFD4AF37) : const Color(0xFF8B1E0F),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isMe ? '⭐ $kinship' : kinship,
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _branchColor(p.branch).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _branchLabel(p.branch),
                                style: TextStyle(
                                  color: _branchColor(p.branch),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Nút thao tác nhanh
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (!isMe)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFB8860B),
                          side: const BorderSide(color: Color(0xFFB8860B)),
                        ),
                        icon: const Icon(Icons.stars_rounded, size: 16),
                        label: const Text('Đặt làm Tôi (Mốc)'),
                        onPressed: () {
                          setState(() => _focusPersonId = p.id);
                          StorageService().saveFocusPersonId(p.id);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Đã chọn ${p.name} làm mốc tính danh xưng.')),
                          );
                        },
                      ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.add_circle_outline, size: 16),
                      label: const Text('Thêm con'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _edit(
                          initialFatherId: p.gender == 'male' ? p.id : (p.spouseIds.firstOrNull ?? ''),
                          initialMotherId: p.gender == 'female' ? p.id : (p.spouseIds.firstOrNull ?? ''),
                          initialBranch: p.branch == 'noi' ? 'noi' : 'con_chau',
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.favorite_border, size: 16),
                      label: const Text('Thêm vợ/chồng'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _edit(
                          initialSpouseId: p.id,
                          initialGender: p.gender == 'male' ? 'female' : 'male',
                          initialBranch: p.branch == 'noi' ? 'vo' : p.branch,
                        );
                      },
                    ),
                  ],
                ),
              ),

              const Divider(height: 28),

              // Thông tin sinh mất & quê quán
              _infoRow('Sinh', p.birthDate.isEmpty ? 'Chưa rõ' : '${p.birthDate} (${p.birthCalendar == 'lunar' ? 'âm lịch' : 'dương lịch'})'),
              _infoRow('Mất', p.deathDate.isEmpty ? 'Còn sống / Chưa ghi nhận' : '${p.deathDate} (${p.deathCalendar == 'lunar' ? 'âm lịch' : 'dương lịch'})'),
              if (p.hometown.isNotEmpty) _infoRow('Quê quán', p.hometown),
              if (p.restingPlace.isNotEmpty) _infoRow('Nơi an nghỉ', p.restingPlace),
              if (p.notes.isNotEmpty) ...[
                const SizedBox(height: 6),
                _infoRow('Ghi chép', p.notes),
              ],

              const Divider(height: 28),

              // Quan hệ gia đình trực tiếp
              _relativeGroup('Cha & Mẹ', parents),
              _relativeGroup('Vợ / Chồng', spouses),
              _relativeGroup('Con cái (${children.length})', children),
              _relativeGroup('Anh chị em ruột (${siblings.length})', siblings),

              const SizedBox(height: 24),

              // Sửa / Xóa
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red[700]),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _delete(p);
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Xóa người này'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B1E0F)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _edit(current: p);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Sửa hồ sơ'),
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

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 110, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
      ],
    ),
  );

  Widget _relativeGroup(String label, List<FamilyPerson> group) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF8B1E0F))),
        const SizedBox(height: 4),
        if (group.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 2),
            child: Text('Chưa ghi nhận', style: TextStyle(color: Colors.grey, fontSize: 12)),
          )
        else
          ...group.map((item) => ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              item.gender == 'female' ? Icons.face_3 : Icons.person,
              size: 18,
              color: item.gender == 'female' ? const Color(0xFFD81B60) : const Color(0xFF1976D2),
            ),
            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
            subtitle: Text(
              '${_branchLabel(item.branch)}${item.birthDate.isNotEmpty ? ' • Sinh ${item.birthDate}' : ''}',
              style: const TextStyle(fontSize: 11),
            ),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () {
              Navigator.pop(context);
              _detail(item);
            },
          )),
      ],
    ),
  );

  Future<void> _delete(FamilyPerson p) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xóa ${p.name}?'),
        content: const Text(
          'Các liên kết cha mẹ, vợ chồng đến người này sẽ được gỡ bỏ an toàn. '
          'Hồ sơ của những người thân khác vẫn được giữ nguyên vẹn.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red[800]),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa hồ sơ'),
          ),
        ],
      ),
    );
    if (yes == true) {
      widget.onDeleted(p.id);
      if (_focusPersonId == p.id) {
        setState(() => _focusPersonId = null);
      }
    }
  }

  /// Form thêm / sửa hồ sơ với tính năng TỰ ĐỘNG GỢI Ý CHA MẸ THÔNG MINH
  Future<void> _edit({
    FamilyPerson? current,
    String? initialFatherId,
    String? initialMotherId,
    String? initialSpouseId,
    String? initialBranch,
    String? initialGender,
  }) async {
    final form = GlobalKey<FormState>();
    final name = TextEditingController(text: current?.name ?? '');
    final birth = TextEditingController(text: current?.birthDate ?? '');
    final death = TextEditingController(text: current?.deathDate ?? '');
    final hometown = TextEditingController(text: current?.hometown ?? '');
    final resting = TextEditingController(text: current?.restingPlace ?? '');
    final notes = TextEditingController(text: current?.notes ?? '');

    var gender = current?.gender ?? (initialGender ?? 'other');
    var branch = current?.branch ?? (initialBranch ?? (_viewMode == 'all' || _viewMode == 'list' ? 'noi' : _viewMode));
    var fatherId = current?.fatherId ?? (initialFatherId ?? '');
    var motherId = current?.motherId ?? (initialMotherId ?? '');
    var birthCalendar = current?.birthCalendar ?? 'solar';
    var deathCalendar = current?.deathCalendar ?? 'solar';
    var birthOrder = current?.birthOrder ?? 0;
    var avatarBase64 = current?.avatarBase64;

    final spouseIds = <String>{...current?.spouseIds ?? []};
    if (initialSpouseId != null && initialSpouseId.isNotEmpty) {
      spouseIds.add(initialSpouseId);
    }

    // Tự động suy ra mẹ nếu đã có fatherId ban đầu mà motherId rỗng
    if (fatherId.isNotEmpty && motherId.isEmpty) {
      final f = _person(fatherId);
      if (f != null && f.spouseIds.isNotEmpty) {
        motherId = f.spouseIds.first;
      }
    }
    // Hoặc ngược lại
    if (motherId.isNotEmpty && fatherId.isEmpty) {
      final m = _person(motherId);
      if (m != null && m.spouseIds.isNotEmpty) {
        fatherId = m.spouseIds.first;
      }
    }

    final others = widget.people.where((p) => p.id != current?.id).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    String? validDate(String? value, String calendar) {
      final v = value?.trim() ?? '';
      if (v.isEmpty) return null;
      final year = RegExp(r'^\d{1,4}$');
      if (year.hasMatch(v)) return int.parse(v) > 0 ? null : 'Năm không hợp lệ';
      final match = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{1,4})$').firstMatch(v);
      if (match == null) return 'Nhập năm (VD: 1961) hoặc ngày (12/08/1961)';
      final day = int.parse(match[1]!);
      final month = int.parse(match[2]!);
      final y = int.parse(match[3]!);
      if (y < 1 || month < 1 || month > 12 || day < 1 || day > (calendar == 'lunar' ? 30 : 31)) {
        return 'Ngày không hợp lệ';
      }
      if (calendar == 'solar' && DateTime(y, month, day).month != month) {
        return 'Ngày không hợp lệ';
      }
      return null;
    }

    try {
      final saved = await showDialog<FamilyPerson>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, refresh) {
            // HÀM TỰ ĐỘNG GỢI Ý MẸ KHI CHỌN CHA
            void onFatherSelected(String selectedFId) {
              refresh(() {
                fatherId = selectedFId;
                if (selectedFId.isNotEmpty) {
                  final f = _person(selectedFId);
                  if (f != null) {
                    // Tìm bạn đời của cha
                    String? foundMother;
                    if (f.spouseIds.isNotEmpty) {
                      foundMother = f.spouseIds.first;
                    } else {
                      final sp = widget.people.where((p) => p.spouseIds.contains(f.id)).firstOrNull;
                      if (sp != null) foundMother = sp.id;
                    }
                    if (foundMother != null && foundMother.isNotEmpty) {
                      motherId = foundMother;
                    }
                  }
                }
              });
            }

            // HÀM TỰ ĐỘNG GỢI Ý CHA KHI CHỌN MẸ
            void onMotherSelected(String selectedMId) {
              refresh(() {
                motherId = selectedMId;
                if (selectedMId.isNotEmpty) {
                  final m = _person(selectedMId);
                  if (m != null) {
                    // Tìm bạn đời của mẹ
                    String? foundFather;
                    if (m.spouseIds.isNotEmpty) {
                      foundFather = m.spouseIds.first;
                    } else {
                      final sp = widget.people.where((p) => p.spouseIds.contains(m.id)).firstOrNull;
                      if (sp != null) foundFather = sp.id;
                    }
                    if (foundFather != null && foundFather.isNotEmpty) {
                      fatherId = foundFather;
                    }
                  }
                }
              });
            }

            return Dialog(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640, maxHeight: 820),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tiêu đề dialog
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 12, 10),
                      child: Row(
                        children: [
                          Icon(
                            current == null ? Icons.person_add_alt_1 : Icons.edit,
                            color: const Color(0xFF8B1E0F),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              current == null ? 'Thêm người thân' : 'Sửa hồ sơ người thân',
                              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Nội dung form cuộn
                    Expanded(
                      child: Form(
                        key: form,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                            // 0. Ảnh chân dung đại diện (Avatar)
                            Center(
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 36,
                                    backgroundColor: (gender == 'female' ? Colors.pink : Colors.blue).withValues(alpha: 0.15),
                                    backgroundImage: (avatarBase64 != null && avatarBase64!.isNotEmpty)
                                        ? MemoryImage(base64Decode(avatarBase64!))
                                        : null,
                                    child: (avatarBase64 == null || avatarBase64!.isEmpty)
                                        ? Icon(
                                            gender == 'female' ? Icons.face_3 : Icons.person,
                                            size: 38,
                                            color: gender == 'female' ? Colors.pink : Colors.blue,
                                          )
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Tooltip(
                                      message: 'Chọn ảnh từ thiết bị',
                                      child: InkWell(
                                      onTap: () async {
                                        try {
                                          final files = await FilePicker.pickFiles(
                                            type: FileType.image,
                                          );
                                          if (files.isNotEmpty) {
                                            final bytes = await files.first.xFile.readAsBytes();
                                            if (bytes.length > 15 * 1024 * 1024) {
                                              throw const FormatException('Ảnh vượt quá 15 MB.');
                                            }
                                            final optimized = await compute(_prepareAvatar, bytes);
                                            refresh(() => avatarBase64 = base64Encode(optimized));
                                          }
                                        } catch (error) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Không thêm được ảnh: $error')),
                                            );
                                          }
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF8B1E0F),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 15),
                                      ),
                                      ),
                                    ),
                                  ),
                                  if (avatarBase64 != null && avatarBase64!.isNotEmpty)
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Tooltip(
                                        message: 'Xóa ảnh đại diện',
                                        child: InkWell(
                                        onTap: () => refresh(() => avatarBase64 = null),
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close, color: Colors.white, size: 13),
                                        ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Center(
                              child: Text(
                                'Chọn ảnh chân dung từ thiết bị',
                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // 1. Họ và tên
                            TextFormField(
                              controller: name,
                              decoration: const InputDecoration(
                                labelText: 'Họ và tên *',
                                hintText: 'VD: Nguyễn Văn An',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (v) => (v?.trim().isEmpty ?? true) ? 'Vui lòng nhập họ và tên' : null,
                            ),
                            const SizedBox(height: 14),

                            // 2. Giới tính & Nhánh gia đình
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                  DropdownButtonFormField<String>(
                                    value: gender,
                                    isExpanded: true,
                                    decoration: const InputDecoration(labelText: 'Giới tính', border: OutlineInputBorder()),
                                    items: const [
                                      DropdownMenuItem(value: 'other', child: Text('Chưa rõ')),
                                      DropdownMenuItem(value: 'male', child: Text('Nam')),
                                      DropdownMenuItem(value: 'female', child: Text('Nữ')),
                                    ],
                                    onChanged: (v) => refresh(() => gender = v ?? 'other'),
                                  ),
                                const SizedBox(height: 10),
                                  DropdownButtonFormField<String>(
                                    value: branch,
                                    isExpanded: true,
                                    decoration: const InputDecoration(labelText: 'Nhánh gia đình', border: OutlineInputBorder()),
                                    items: const [
                                      DropdownMenuItem(value: 'noi', child: Text('Bên nội (Họ cha)')),
                                      DropdownMenuItem(value: 'ngoai', child: Text('Bên ngoại (Họ mẹ)')),
                                      DropdownMenuItem(value: 'vo', child: Text('Bên vợ / Thông gia')),
                                      DropdownMenuItem(value: 'con_chau', child: Text('Con cháu / Hậu duệ')),
                                      DropdownMenuItem(value: 'khac', child: Text('Khác')),
                                    ],
                                    onChanged: (v) => refresh(() => branch = v ?? 'noi'),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            ExpansionTile(
                              initiallyExpanded: current != null || others.isNotEmpty,
                              tilePadding: EdgeInsets.zero,
                              childrenPadding: EdgeInsets.zero,
                              title: const Text('Ngày tháng, quan hệ và thông tin thêm'),
                              subtitle: const Text('Có thể bổ sung sau khi lưu hồ sơ'),
                              children: [

                            // 3. Ngày sinh & Ngày mất
                            const Text('Ngày tháng sinh & mất', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                            const SizedBox(height: 4),
                            const Text('Có thể nhập năm (VD: 1961) hoặc ngày đầy đủ (VD: 12/08/1961).', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                            const SizedBox(height: 10),

                            // Ngày sinh
                            TextFormField(
                              controller: birth,
                              keyboardType: TextInputType.datetime,
                              decoration: const InputDecoration(
                                labelText: 'Ngày / Năm sinh',
                                hintText: 'VD: 1961 hoặc 12/08/1961',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => validDate(v, birthCalendar),
                            ),
                            const SizedBox(height: 6),
                            _calendarChoice('Lịch sinh', birthCalendar, (v) => refresh(() => birthCalendar = v)),
                            const SizedBox(height: 14),

                            // Ngày mất
                            TextFormField(
                              controller: death,
                              keyboardType: TextInputType.datetime,
                              decoration: const InputDecoration(
                                labelText: 'Ngày / Năm mất (nếu có)',
                                hintText: 'VD: 2020 hoặc 15/03/2020',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => validDate(v, deathCalendar),
                            ),
                            const SizedBox(height: 6),
                            _calendarChoice('Lịch mất', deathCalendar, (v) => refresh(() => deathCalendar = v)),
                            const SizedBox(height: 18),

                            // 4. QUAN HỆ CHA MẸ (TỰ ĐỘNG GỢI Ý)
                            Row(
                              children: const [
                                Icon(Icons.family_restroom, size: 18, color: Color(0xFF8B1E0F)),
                                SizedBox(width: 6),
                                Text('Quan hệ Cha Mẹ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF8E7),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFFD54F)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.auto_awesome, size: 16, color: Color(0xFFF57F17)),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Mẹo: Khi chọn Cha, hệ thống tự động tìm và gợi ý Mẹ (vợ của cha) và ngược lại.',
                                      style: TextStyle(fontSize: 11.5, color: Color(0xFF5D4037)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Dropdown chọn Cha
                            DropdownButtonFormField<String>(
                              value: others.any((p) => p.id == fatherId) ? fatherId : '',
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Cha',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person, color: Color(0xFF1976D2)),
                              ),
                              items: [
                                const DropdownMenuItem(value: '', child: Text('Chưa rõ')),
                                ...others.map((p) => DropdownMenuItem(
                                  value: p.id,
                                  child: Text('${p.name} (${_branchLabel(p.branch)})', overflow: TextOverflow.ellipsis),
                                )),
                              ],
                              onChanged: (v) => onFatherSelected(v ?? ''),
                            ),
                            const SizedBox(height: 10),

                            // Dropdown chọn Mẹ
                            DropdownButtonFormField<String>(
                              value: others.any((p) => p.id == motherId) ? motherId : '',
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Mẹ',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.face_3, color: Color(0xFFD81B60)),
                              ),
                              items: [
                                const DropdownMenuItem(value: '', child: Text('Chưa rõ')),
                                ...others.map((p) => DropdownMenuItem(
                                  value: p.id,
                                  child: Text('${p.name} (${_branchLabel(p.branch)})', overflow: TextOverflow.ellipsis),
                                )),
                              ],
                              onChanged: (v) => onMotherSelected(v ?? ''),
                            ),
                            const SizedBox(height: 12),

                            // Dropdown chọn Thứ tự con trong gia đình
                            DropdownButtonFormField<int>(
                              value: birthOrder,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Thứ tự con trong gia đình',
                                helperText: 'Con 1 ở bên trái, các con sau (Con 2, 3...) tiếp sang bên phải',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.format_list_numbered, color: Color(0xFFD4AF37)),
                              ),
                              items: const [
                                DropdownMenuItem(value: 0, child: Text('Tự động theo năm sinh')),
                                DropdownMenuItem(value: 1, child: Text('Con 1 (Con cả / Trưởng)')),
                                DropdownMenuItem(value: 2, child: Text('Con 2 (Con thứ hai)')),
                                DropdownMenuItem(value: 3, child: Text('Con 3 (Con thứ ba)')),
                                DropdownMenuItem(value: 4, child: Text('Con 4 (Con thứ tư)')),
                                DropdownMenuItem(value: 5, child: Text('Con 5')),
                                DropdownMenuItem(value: 6, child: Text('Con 6')),
                                DropdownMenuItem(value: 7, child: Text('Con 7')),
                                DropdownMenuItem(value: 8, child: Text('Con 8')),
                              ],
                              onChanged: (v) => refresh(() => birthOrder = v ?? 0),
                            ),
                            const SizedBox(height: 20),

                            // 5. VỢ / CHỒNG
                            const Text('Vợ / Chồng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                            const SizedBox(height: 4),
                            if (others.isEmpty)
                              const Text('Chưa có thành viên khác để kết nối quan hệ vợ/chồng.', style: TextStyle(fontSize: 12, color: Colors.grey))
                            else
                              Card(
                                elevation: 0,
                                color: Colors.grey.withValues(alpha: 0.08),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                child: Column(
                                  children: others.map((p) => CheckboxListTile(
                                    dense: true,
                                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text(_branchLabel(p.branch)),
                                    secondary: Icon(
                                      p.gender == 'female' ? Icons.face_3 : Icons.person,
                                      color: p.gender == 'female' ? const Color(0xFFD81B60) : const Color(0xFF1976D2),
                                      size: 20,
                                    ),
                                    value: spouseIds.contains(p.id),
                                    onChanged: (checked) => refresh(() {
                                      if (checked == true) {
                                        spouseIds.add(p.id);
                                      } else {
                                        spouseIds.remove(p.id);
                                      }
                                    }),
                                  )).toList(),
                                ),
                              ),
                            const SizedBox(height: 16),

                            // 6. Quê quán, Nơi an nghỉ & Ghi chú
                            TextFormField(
                              controller: hometown,
                              decoration: const InputDecoration(labelText: 'Quê quán', hintText: 'VD: Can Lộc, Hà Tĩnh', border: OutlineInputBorder()),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: resting,
                              decoration: const InputDecoration(labelText: 'Nơi an nghỉ (nếu đã mất)', border: OutlineInputBorder()),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: notes,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Ghi chép về người thân',
                                hintText: 'Kỷ niệm, ngày giỗ âm, nghề nghiệp, vai vế...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                    // Nút Lưu
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B1E0F)),
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Lưu hồ sơ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          onPressed: () {
                            if (form.currentState?.validate() != true) return;
                            final id = current?.id ?? 'person_${DateTime.now().microsecondsSinceEpoch}';

                            if (fatherId.isNotEmpty && fatherId == motherId) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('Cha và Mẹ phải là hai người khác nhau.')),
                              );
                              return;
                            }
                            if (createsFamilyCycle(id, fatherId, widget.people) ||
                                createsFamilyCycle(id, motherId, widget.people)) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('Không thể chọn con hoặc cháu làm cha mẹ.')),
                              );
                              return;
                            }

                            Navigator.pop(
                              ctx,
                              FamilyPerson(
                                id: id,
                                name: name.text.trim(),
                                gender: gender,
                                branch: branch,
                                birthDate: birth.text.trim(),
                                deathDate: death.text.trim(),
                                birthCalendar: birthCalendar,
                                deathCalendar: deathCalendar,
                                fatherId: fatherId,
                                motherId: motherId,
                                spouseIds: spouseIds.toList(),
                                hometown: hometown.text.trim(),
                                restingPlace: resting.text.trim(),
                                notes: notes.text.trim(),
                                birthOrder: birthOrder,
                                avatarBase64: avatarBase64,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      if (saved != null) {
        widget.onSaved(saved);
      }
    } finally {
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        name.dispose();
        birth.dispose();
        death.dispose();
        hometown.dispose();
        resting.dispose();
        notes.dispose();
      });
    }
  }

  Widget _calendarChoice(String label, String value, ValueChanged<String> update) => Wrap(
    spacing: 8,
    runSpacing: 4,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text('$label: ', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
      ChoiceChip(
        label: const Text('Dương lịch', style: TextStyle(fontSize: 12)),
        selected: value == 'solar',
        onSelected: (_) => update('solar'),
      ),
      ChoiceChip(
        label: const Text('Âm lịch', style: TextStyle(fontSize: 12)),
        selected: value == 'lunar',
        onSelected: (_) => update('lunar'),
      ),
    ],
  );
}
