/// Widget hiển thị Cây Phả Hệ phân cấp từ trên xuống dưới
/// Hỗ trợ Zoom in/out, Pan kéo thả tự do, cặp vợ chồng nằm cạnh nhau, và đường nối thế hệ chuẩn xác
import 'dart:convert';
import 'dart:io' show File;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/family_person.dart';
import '../services/family_tree_builder.dart';

class FamilyTreeCanvas extends StatefulWidget {
  final List<FamilyTreeNode> roots;
  final FamilyPerson focusPerson;
  final ValueChanged<FamilyPerson> onPersonTap;
  final VoidCallback? onResetZoom;

  const FamilyTreeCanvas({
    super.key,
    required this.roots,
    required this.focusPerson,
    required this.onPersonTap,
    this.onResetZoom,
  });

  @override
  State<FamilyTreeCanvas> createState() => _FamilyTreeCanvasState();
}

class _FamilyTreeCanvasState extends State<FamilyTreeCanvas> {
  final TransformationController _transformController = TransformationController();
  final GlobalKey _treeBoundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fitToScreen();
    });
  }

  @override
  void didUpdateWidget(covariant FamilyTreeCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roots != widget.roots) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fitToScreen();
      });
    }
  }

  void _zoom(double factor) {
    final matrix = _transformController.value.clone();
    matrix.scaleByDouble(factor, factor, 1.0, 1.0);
    _transformController.value = matrix;
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
  }

  void _fitToScreen() {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final matrix = Matrix4.identity();
    if (isMobile) {
      // Tỷ lệ thu phóng 0.65 - 0.7 giúp nhìn thấy toàn bộ cây trên màn hình iPhone
      const scale = 0.68;
      matrix.scaleByDouble(scale, scale, 1.0, 1.0);
      matrix.setTranslationRaw(16.0, 16.0, 0.0);
    } else {
      matrix.setTranslationRaw(32.0, 32.0, 0.0);
    }
    _transformController.value = matrix;
  }

  Future<void> _exportTreeAsImage() async {
    try {
      final boundary = _treeBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();

      final now = DateTime.now();
      final fileName = 'Cay_Gia_Pha_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.png';

      if (kIsWeb) {
        final xFile = XFile.fromData(
          pngBytes,
          mimeType: 'image/png',
          name: fileName,
        );
        await xFile.saveTo(fileName);
      } else {
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(pngBytes);
        final xFile = XFile(filePath, mimeType: 'image/png', name: fileName);
        await Share.shareXFiles(
          [xFile],
          text: 'Ảnh Cây Gia Phả - Sự Kiện Gia Tộc',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xuất ảnh Cây Gia Phả sắc nét thành công!'),
            backgroundColor: Color(0xFF8B1E0F),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xuất ảnh: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (widget.roots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_tree_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text(
              'Chưa có dữ liệu cây cho nhánh này',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final allGens = <int>[];
    void collectGens(FamilyTreeNode n) {
      allGens.add(n.relativeGeneration);
      for (final c in n.children) {
        collectGens(c);
      }
    }
    for (final r in widget.roots) {
      collectGens(r);
    }
    final minGen = allGens.isEmpty ? 0 : allGens.reduce((a, b) => a < b ? a : b);
    final maxGen = allGens.isEmpty ? 0 : allGens.reduce((a, b) => a > b ? a : b);

    final tierCardHeight = isMobile ? 96.0 : 100.0;
    const stemHeight = 18.0;
    final tierStep = tierCardHeight + stemHeight * 2;
    const headerHeight = 36.0;
    const headerBottomGap = 20.0;

    return Stack(
      children: [
        // CANVAS TỰ DO KÉO THẢ & PHÓNG TO / THU NHỎ
        InteractiveViewer(
          transformationController: _transformController,
          boundaryMargin: const EdgeInsets.all(500),
          minScale: 0.15,
          maxScale: 2.5,
          constrained: false, // Cho phép canvas tự do mở rộng ngang & dọc mà không bị cắt
          child: RepaintBoundary(
            key: _treeBoundaryKey,
            child: Container(
              color: isDark ? const Color(0xFF191412) : const Color(0xFFF7F2E8),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24 : 64,
                vertical: isMobile ? 20 : 40,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. THƯỚC TRỤC THẾ HỆ BÊN TRÁI (GENERATION RULER)
                  if (widget.roots.length > 1 || (maxGen - minGen >= 1)) ...[
                    _buildGenerationRuler(
                      minGen,
                      maxGen,
                      tierCardHeight,
                      stemHeight,
                      headerHeight + headerBottomGap,
                      isDark,
                      isMobile,
                    ),
                    SizedBox(width: isMobile ? 18 : 32),
                  ],

                  // 2. CÁC NHÁNH CÂY GIA PHẢ (BÊN NỘI, BÊN NGOẠI, BÊN VỢ)
                  for (int i = 0; i < widget.roots.length; i++) ...[
                    if (i > 0) SizedBox(width: isMobile ? 48 : 80),
                    _buildRootColumn(
                      widget.roots[i],
                      minGen,
                      tierStep,
                      headerHeight,
                      headerBottomGap,
                      isDark,
                      isMobile,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // THANH ĐIỀU KHIỂN ZOOM & XUẤT ẢNH GÓC DƯỚI BÊN TRÁI
        Positioned(
          left: 16,
          bottom: 16,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
              ],
              border: Border.all(
                color: isDark ? Colors.white24 : const Color(0xFFE0D5C1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 18),
                  tooltip: 'Thu nhỏ',
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  constraints: const BoxConstraints(),
                  onPressed: () => _zoom(0.85),
                ),
                IconButton(
                  icon: const Icon(Icons.filter_center_focus, size: 18),
                  tooltip: 'Vừa màn hình',
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  constraints: const BoxConstraints(),
                  onPressed: _fitToScreen,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: 'Cỡ chuẩn 1:1',
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  constraints: const BoxConstraints(),
                  onPressed: _resetZoom,
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  tooltip: 'Phóng to',
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  constraints: const BoxConstraints(),
                  onPressed: () => _zoom(1.2),
                ),
                Container(
                  width: 1,
                  height: 18,
                  color: isDark ? Colors.white24 : Colors.black12,
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt_outlined, size: 18, color: Color(0xFF8B1E0F)),
                  tooltip: 'Xuất ảnh Cây Gia Phả sắc nét (PNG)',
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  constraints: const BoxConstraints(),
                  onPressed: _exportTreeAsImage,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Cột của một nhánh cây hoàn chỉnh kèm tiêu đề và bù khoảng cách để ngang hàng thế hệ
  Widget _buildRootColumn(
    FamilyTreeNode root,
    int minGen,
    double tierStep,
    double headerHeight,
    double headerBottomGap,
    bool isDark,
    bool isMobile,
  ) {
    final topGenOffset = root.relativeGeneration - minGen;
    final topSpacer = topGenOffset > 0 ? topGenOffset * tierStep : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Tiêu đề nhánh dòng tộc
        if (root.rootBranchTitle.isNotEmpty) ...[
          Container(
            height: headerHeight,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF332316) : const Color(0xFFFFF3D6),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFD4AF37),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              root.rootBranchTitle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 12 : 13,
                color: const Color(0xFF8B2500),
                letterSpacing: 0.4,
              ),
            ),
          ),
          SizedBox(height: headerBottomGap),
        ],

        // 2. Khoảng bù độ cao thế hệ để Bản thân và các đời nằm cùng một dòng ngang
        if (topSpacer > 0) ...[
          SizedBox(height: topSpacer),
        ],

        // 3. Cây phả hệ phân cấp từ gốc
        _buildTreeNodeWidget(root, isDark, isMobile),
      ],
    );
  }

  /// Thước trục mốc thế hệ chạy dọc bên trái canvas
  Widget _buildGenerationRuler(
    int minGen,
    int maxGen,
    double tierCardHeight,
    double stemHeight,
    double topHeaderOffset,
    bool isDark,
    bool isMobile,
  ) {
    String getGenLabel(int gen) {
      return switch (gen) {
        -4 => 'ĐỜI CỤ TỔ',
        -3 => 'ĐỜI CỤ CỐ',
        -2 => 'ĐỜI ÔNG BÀ',
        -1 => 'ĐỜI CHA MẸ',
        0 => '⭐ ĐỜI TÔI & VỢ',
        1 => 'ĐỜI CON',
        2 => 'ĐỜI CHÁU',
        3 => 'ĐỜI CHẮT',
        _ => 'THẾ HỆ ${gen > 0 ? "+$gen" : "$gen"}',
      };
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(height: topHeaderOffset),
        for (int gen = minGen; gen <= maxGen; gen++) ...[
          SizedBox(
            height: tierCardHeight,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8 : 12,
                  vertical: isMobile ? 5 : 7,
                ),
                decoration: BoxDecoration(
                  color: gen == 0
                      ? const Color(0xFFD4AF37).withValues(alpha: 0.2)
                      : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: gen == 0
                        ? const Color(0xFFD4AF37)
                        : (isDark ? Colors.white24 : Colors.grey.withValues(alpha: 0.3)),
                    width: gen == 0 ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  getGenLabel(gen),
                  style: TextStyle(
                    fontSize: isMobile ? 10.5 : 11.5,
                    fontWeight: gen == 0 ? FontWeight.bold : FontWeight.w600,
                    color: gen == 0
                        ? const Color(0xFFB8860B)
                        : (isDark ? Colors.grey[400] : const Color(0xFF755C48)),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
          if (gen < maxGen)
            SizedBox(
              height: stemHeight * 2,
              child: Center(
                child: Container(
                  width: 1,
                  height: stemHeight * 2,
                  color: isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.2),
                ),
              ),
            ),
        ],
      ],
    );
  }

  /// Xây dựng một node cây phân cấp
  Widget _buildTreeNodeWidget(FamilyTreeNode node, bool isDark, bool isMobile) {
    const lineColor = Color(0xFFB8860B); // Vàng kim đồng truyền thống
    const lineWidth = 2.0;
    const stemHeight = 18.0;
    final tierCardHeight = isMobile ? 96.0 : 100.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. CẶP VỢ CHỒNG (NẰM CẠNH NHAU) - ĐỘ CAO CHUẨN ĐỂ CĂN DÒNG CÙNG NHAU
        SizedBox(
          height: tierCardHeight,
          child: Center(
            child: _buildCoupleWidget(node, isDark, isMobile),
          ),
        ),

        // 2. NẾU CÓ CON:
        if (node.children.isNotEmpty) ...[
          // Cuống dọc đi xuống từ giữa cặp vợ chồng
          Container(
            width: lineWidth,
            height: stemHeight,
            color: lineColor,
          ),

          if (node.children.length == 1) ...[
            // Trường hợp 1 con: vẽ cuống nối thẳng đứng xuống đỉnh con
            Container(
              width: lineWidth,
              height: stemHeight,
              color: lineColor,
            ),
            _buildTreeNodeWidget(node.children.first, isDark, isMobile),
          ] else ...[
            // Trường hợp từ 2 con trở lên: vẽ đường ngang nối và cuống rẽ nhánh xuống từng con
            _buildChildrenRow(node.children, isDark, isMobile, lineColor, lineWidth, stemHeight),
          ],
        ],
      ],
    );
  }

  /// Hàng các con với các đường nối thế hệ hoàn chỉnh chuẩn mực
  Widget _buildChildrenRow(
    List<FamilyTreeNode> children,
    bool isDark,
    bool isMobile,
    Color lineColor,
    double lineWidth,
    double stemHeight,
  ) {
    final spacing = isMobile ? 18.0 : 28.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          if (i > 0)
            // Nhánh nối ngang qua khoảng cách giữa hai con
            CustomPaint(
              size: Size(spacing, stemHeight),
              painter: _SpacingConnectorPainter(
                lineColor: lineColor,
                lineWidth: lineWidth,
              ),
            ),
          // Cột của con thứ i
          IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Đầu nối rẽ nhánh: đường ngang đón từ trái/phải và đường dọc đi xuống tâm con
                CustomPaint(
                  size: Size.fromHeight(stemHeight),
                  painter: _ChildBranchPainter(
                    isFirst: i == 0,
                    isLast: i == children.length - 1,
                    lineColor: lineColor,
                    lineWidth: lineWidth,
                  ),
                ),
                _buildTreeNodeWidget(children[i], isDark, isMobile),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Cặp vợ chồng nằm cạnh nhau trong 1 khối
  /// Cặp vợ chồng hoặc 1 chồng nhiều vợ nằm cạnh nhau trong 1 khối ngang hàng
  Widget _buildCoupleWidget(FamilyTreeNode node, bool isDark, bool isMobile) {
    final personCard = _buildPersonCard(
      person: node.person,
      kinship: node.kinshipTitle,
      childOrder: node.childOrder,
      totalSiblings: node.totalSiblings,
      isDark: isDark,
      isMobile: isMobile,
    );

    if (node.spouses.isEmpty) {
      return personCard;
    }

    final spouseCards = <Widget>[];
    for (int i = 0; i < node.spouses.length; i++) {
      final sp = node.spouses[i];
      final title = i < node.spouseKinshipTitles.length ? node.spouseKinshipTitles[i] : 'Vợ/Chồng';
      spouseCards.add(
        _buildPersonCard(
          person: sp,
          kinship: title,
          isDark: isDark,
          isMobile: isMobile,
        ),
      );
    }

    // Xếp các thẻ ngang hàng trên cùng 1 khối:
    // - Nếu node.person là nữ và tất cả bạn đời là nam:
    //   + 1 chồng: [Chồng] 💍 [Vợ]
    //   + Nhiều chồng: [Chồng 1] 💍 [Vợ] 💍 [Chồng 2]
    // - Trường hợp phổ biến: node.person là nam (Chồng), có 1 hoặc nhiều vợ:
    //   + Thứ tự: [Chồng] 💍 [Vợ Cả] 💍 [Vợ Hai]...
    final rowItems = <Widget>[];
    if (node.person.gender == 'female' && node.spouses.every((s) => s.gender == 'male')) {
      if (spouseCards.length == 1) {
        rowItems.add(spouseCards.first);
        rowItems.add(_buildMarriageSymbol(isMobile));
        rowItems.add(personCard);
      } else {
        // 2 chồng: Chồng 1 💍 Vợ 💍 Chồng 2
        rowItems.add(spouseCards[0]);
        rowItems.add(_buildMarriageSymbol(isMobile));
        rowItems.add(personCard);
        for (int i = 1; i < spouseCards.length; i++) {
          rowItems.add(_buildMarriageSymbol(isMobile));
          rowItems.add(spouseCards[i]);
        }
      }
    } else {
      // Chồng 💍 Vợ Cả 💍 Vợ Hai
      rowItems.add(personCard);
      for (final sCard in spouseCards) {
        rowItems.add(_buildMarriageSymbol(isMobile));
        rowItems.add(sCard);
      }
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 5 : 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF22201E) : const Color(0xFFFBF7F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: rowItems,
      ),
    );
  }

  Widget _buildMarriageSymbol(bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.all_inclusive, color: const Color(0xFFD4AF37), size: isMobile ? 16 : 18),
          Text(
            '⚭',
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF8B2500),
            ),
          ),
        ],
      ),
    );
  }

  /// Thẻ thông tin một người (Kích thước chuẩn, đẹp, hiển thị vai vế & thứ tự con)
  Widget _buildPersonCard({
    required FamilyPerson person,
    required String kinship,
    int? childOrder,
    int totalSiblings = 1,
    required bool isDark,
    required bool isMobile,
  }) {
    final isMe = person.id == widget.focusPerson.id;
    final isFemale = person.gender == 'female';
    final cardWidth = isMobile ? 134.0 : 152.0;

    // Bảng màu phân biệt
    final cardBg = isMe
        ? (isDark ? const Color(0xFF422800) : const Color(0xFFFFF9E6))
        : (isDark
            ? (isFemale ? const Color(0xFF2B1D24) : const Color(0xFF1D242B))
            : (isFemale ? const Color(0xFFFFF5F7) : const Color(0xFFF5F9FF)));

    final borderColor = isMe
        ? const Color(0xFFE6A100)
        : (isFemale ? const Color(0xFFD81B60) : const Color(0xFF1976D2));

    final kinshipBg = isMe
        ? const Color(0xFFE6A100)
        : (isFemale ? const Color(0xFFAD1457) : const Color(0xFF8B2500));

    return InkWell(
      onTap: () => widget.onPersonTap(person),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: cardWidth,
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 8, vertical: isMobile ? 7 : 8),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor.withValues(alpha: isMe ? 1.0 : 0.7),
            width: isMe ? 2.0 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: borderColor.withValues(alpha: isMe ? 0.25 : 0.08),
              blurRadius: isMe ? 6 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Dòng 1: Icon giới tính + Thứ tự con (Con 1, Con 2...) + Huy hiệu vai vế
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (person.avatarBase64 != null && person.avatarBase64!.isNotEmpty) ...[
                  ClipOval(
                    child: Image.memory(
                      base64Decode(person.avatarBase64!),
                      width: isMobile ? 16 : 18,
                      height: isMobile ? 16 : 18,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        isFemale ? Icons.face_3 : Icons.person,
                        size: isMobile ? 13 : 14,
                        color: isFemale ? const Color(0xFFD81B60) : const Color(0xFF1976D2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ] else ...[
                  Icon(
                    isFemale ? Icons.face_3 : Icons.person,
                    size: isMobile ? 13 : 14,
                    color: isFemale ? const Color(0xFFD81B60) : const Color(0xFF1976D2),
                  ),
                  const SizedBox(width: 4),
                ],
                if (childOrder != null && childOrder > 0 && (totalSiblings > 1 || childOrder > 1)) ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF4A3518) : const Color(0xFFFFF0D0),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: const Color(0xFFD4AF37),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Con $childOrder',
                      style: TextStyle(
                        color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF8B2500),
                        fontSize: isMobile ? 8.5 : 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 5 : 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: kinshipBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isMe ? '⭐ $kinship' : kinship,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 9.5 : 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 5 : 6),

            // Dòng 2: Họ và tên
            Text(
              person.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile ? 12.5 : 13.5,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF2C1810),
              ),
            ),
            const SizedBox(height: 3),

            // Dòng 3: Năm sinh / năm mất
            Text(
              _formatLifeSpan(person),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isMobile ? 10.5 : 11,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatLifeSpan(FamilyPerson p) {
    if (p.birthDate.isEmpty && p.deathDate.isEmpty) return 'Chưa rõ năm';
    final b = p.birthDate.isNotEmpty ? p.birthDate.split('/').last : '?';
    if (p.deathDate.isNotEmpty) {
      final d = p.deathDate.split('/').last;
      return '$b – $d';
    }
    return 'Sinh $b';
  }
}

/// CustomPainter vẽ nhánh nối thế hệ chuẩn xác vào đỉnh của từng người con
class _ChildBranchPainter extends CustomPainter {
  final bool isFirst;
  final bool isLast;
  final Color lineColor;
  final double lineWidth;

  _ChildBranchPainter({
    required this.isFirst,
    required this.isLast,
    required this.lineColor,
    required this.lineWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final midX = (size.width / 2).roundToDouble();
    final y = lineWidth / 2;

    // 1. Đường ngang trên đỉnh (y = lineWidth / 2)
    if (isFirst) {
      // Con đầu tiên: nối từ tâm sang mép phải
      canvas.drawLine(Offset(midX, y), Offset(size.width, y), paint);
    } else if (isLast) {
      // Con cuối cùng: nối từ mép trái sang tâm
      canvas.drawLine(Offset(0, y), Offset(midX, y), paint);
    } else {
      // Con ở giữa: nối suốt từ mép trái sang mép phải
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // 2. Cuống dọc đi thẳng xuống tâm con (từ y đến size.height)
    canvas.drawLine(Offset(midX, y), Offset(midX, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _ChildBranchPainter oldDelegate) {
    return oldDelegate.isFirst != isFirst ||
        oldDelegate.isLast != isLast ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.lineWidth != lineWidth;
  }
}

/// CustomPainter vẽ đường ngang nối qua khoảng cách giữa 2 con liền kề
class _SpacingConnectorPainter extends CustomPainter {
  final Color lineColor;
  final double lineWidth;

  _SpacingConnectorPainter({
    required this.lineColor,
    required this.lineWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final y = lineWidth / 2;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(covariant _SpacingConnectorPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor || oldDelegate.lineWidth != lineWidth;
  }
}
