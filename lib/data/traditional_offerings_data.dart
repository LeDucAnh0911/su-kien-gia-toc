/// Dữ liệu Cẩm nang Gợi ý Mâm cỗ & Đồ lễ cúng giỗ, sự kiện gia tộc truyền thống
class OfferingItem {
  final String name;
  final String description;
  final String category; // 'le_vat', 'co_man', 'co_chay', 'nghi_le'
  final bool isEssential; // Món cốt lõi / bắt buộc

  const OfferingItem({
    required this.name,
    required this.description,
    required this.category,
    this.isEssential = false,
  });
}

class TraditionalOfferingsData {
  /// Lễ vật dâng hương gia tiên cơ bản
  static const List<OfferingItem> essentialOfferings = [
    OfferingItem(
      name: 'Hương trầm thơm & Nến/Đèn cầy',
      description: 'Thắp 3 hoặc 5 nén hương tượng trưng cho Tam bảo hoặc Ngũ hành.',
      category: 'le_vat',
      isEssential: true,
    ),
    OfferingItem(
      name: 'Hoa tươi (Cúc vàng, Huệ trắng, Hoa sen)',
      description: 'Hoa tươi thơm ngát, tránh dùng hoa giả hoặc hoa có gai nhọn.',
      category: 'le_vat',
      isEssential: true,
    ),
    OfferingItem(
      name: 'Mâm ngũ quả tươi ngon',
      description: 'Gồm 5 loại quả tươi (Chuối, bưởi, cam, táo, thanh long...) tượng trưng ngũ phúc.',
      category: 'le_vat',
      isEssential: true,
    ),
    OfferingItem(
      name: 'Trầu têm cánh phượng & Cau tươi',
      description: 'Miếng trầu là đầu câu chuyện, kết nối âm dương và lòng thành kính.',
      category: 'le_vat',
      isEssential: true,
    ),
    OfferingItem(
      name: 'Rượu trắng, Trà thơm & Nước thanh tịnh',
      description: '3 chén rượu, 3 chén nước thanh tịnh và ấm trà mạn pha nóng.',
      category: 'le_vat',
      isEssential: true,
    ),
    OfferingItem(
      name: 'Tiền vàng mã & Bộ quần áo cúng gia tiên',
      description: 'Tiền vàng chuẩn bị trang trọng, hóa vàng sau khi tàn hương.',
      category: 'le_vat',
      isEssential: true,
    ),
  ];

  /// Gợi ý Mâm cỗ mặn truyền thống
  static const List<OfferingItem> traditionalMeatFeast = [
    OfferingItem(
      name: 'Gà trống thiến luộc lá chanh',
      description: 'Gà luộc da vàng ươm, nguyên con ngậm hoa hồng hoặc chặt xếp đĩa rải lá chanh.',
      category: 'co_man',
      isEssential: true,
    ),
    OfferingItem(
      name: 'Xôi gấc đỏ hoặc Xôi vò đỗ xanh',
      description: 'Màu đỏ tượng trưng cho may mắn, phúc lộc đầy nhà cho con cháu.',
      category: 'co_man',
      isEssential: true,
    ),
    OfferingItem(
      name: 'Giò lụa truyền thống / Giò xào',
      description: 'Cắt khoanh xếp cánh hoa trang nhã, tượng trưng cho phúc lộc trọn vẹn.',
      category: 'co_man',
      isEssential: true,
    ),
    OfferingItem(
      name: 'Canh măng miến nấu sườn/mọc',
      description: 'Bát canh nóng ấm cúng, rải hành mùi thơm ngát không thể thiếu trên mâm cỗ giỗ.',
      category: 'co_man',
      isEssential: true,
    ),
    OfferingItem(
      name: 'Nem rán truyền thống (Chả ram)',
      description: 'Vỏ giòn rụm, nhân thịt nấm mộc nhĩ tôm bùi béo.',
      category: 'co_man',
    ),
    OfferingItem(
      name: 'Thịt heo luộc / Thịt kho tàu',
      description: 'Thịt ba chỉ thái miếng đều đặn ăn kèm dưa chua hoặc nước mắm tỏi ớt.',
      category: 'co_man',
    ),
    OfferingItem(
      name: 'Nộm hoa chuối tai heo / Nộm ngó sen tôm thịt',
      description: 'Món giải ngấy thanh mát, cân bằng vị giác cho mâm cỗ truyền thống.',
      category: 'co_man',
    ),
    OfferingItem(
      name: 'Bát cơm trắng úp tròn & Chén muối ớt',
      description: 'Cơm gạo mới thơm thảo dâng lên người quá cố.',
      category: 'co_man',
      isEssential: true,
    ),
  ];

  /// Gợi ý Mâm cỗ chay thanh tịnh
  static const List<OfferingItem> traditionalVegetarianFeast = [
    OfferingItem(
      name: 'Xôi hạt sen dừa nạo',
      description: 'Xôi dẻo thơm hạt sen bùi béo, thanh tịnh trang nhã.',
      category: 'co_chay',
      isEssential: true,
    ),
    OfferingItem(
      name: 'Nem chay nấm đỗ rau củ',
      description: 'Nhân nấm hương, mộc nhĩ, cà rốt, miến dong giòn rụm.',
      category: 'co_chay',
      isEssential: true,
    ),
    OfferingItem(
      name: 'Giò lụa chay / Đậu phụ sốt nấm sen',
      description: 'Làm từ váng đậu hoặc nấm bào ngư thơm ngon bổ dưỡng.',
      category: 'co_chay',
      isEssential: true,
    ),
    OfferingItem(
      name: 'Canh củ sen ngô ngọt nấu nấm đông cô',
      description: 'Vị ngọt thanh tự nhiên từ rau củ, thanh lọc tâm hồn.',
      category: 'co_chay',
      isEssential: true,
    ),
    OfferingItem(
      name: 'Nấm kho tộ tiêu xanh',
      description: 'Nấm đùi gà hoặc nấm rơm kho đậm đà đưa cơm.',
      category: 'co_chay',
    ),
    OfferingItem(
      name: 'Rau củ ngũ sắc luộc chấm kho quẹt chay',
      description: 'Bông cải, cà rốt, su su, đậu bắp tươi mát nhiều màu sắc.',
      category: 'co_chay',
    ),
    OfferingItem(
      name: 'Chè trôi nước hoặc Chè kho',
      description: 'Món tráng miệng truyền thống mang ý nghĩa sum vầy, thuận hòa.',
      category: 'co_chay',
    ),
  ];

  /// Kiến thức phong tục cúng giỗ
  static const Map<String, String> customsKnowledge = {
    'Lễ Tiên Thường (Cúng chiều trước ngày giỗ)':
        'Thực hiện vào buổi chiều tối trước ngày giỗ chính. Gia chủ dâng hương, lễ mọn để cáo giỗ, xin phép thần linh thổ địa và mời vong linh người quá cố về hưởng giỗ cùng con cháu vào ngày hôm sau.',
    'Lễ Chính Kỵ (Cúng ngày giỗ chính)':
        'Thực hiện vào buổi sáng (từ 9h30 đến 11h trưa) ngày giỗ. Đây là lễ quan trọng nhất, dâng mâm cỗ thịnh soạn, con cháu tề tựu thắp hương tưởng niệm, sau đó cùng thụ lộc sum vầy.',
    'Giỗ Đầu (Tiểu Tường)':
        'Tròn 1 năm sau ngày mất. Lúc này con cháu vẫn còn trong thời kỳ tang chế sâu sắc, không khí trang nghiêm, xúc động.',
    'Giỗ Hết (Đại Tường)':
        'Tròn 2 năm sau ngày mất. Đây là lễ mãn tang (hết tang), sau lễ này gia đình làm thủ tục trừ phục và đưa linh vị lên bàn thờ tổ tiên.',
    'Giỗ Thường (Cát Kỵ)':
        'Từ năm thứ 3 trở đi gọi là Cát Kỵ (ngày giỗ lành). Mang ý nghĩa ngày hội sum họp gia đình, nhắc nhở con cháu đạo hiếu và giữ gìn nề nếp gia phong.',
  };
}
