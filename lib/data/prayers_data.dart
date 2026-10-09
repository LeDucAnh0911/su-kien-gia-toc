/// Kho Dữ Liệu Văn Khấn Cổ Truyền & Lễ Tiết Việt Nam
/// Dành cho ứng dụng Sổ Giỗ & Lịch Gia Tộc
/// Hỗ trợ placeholder thông minh: {ngay_am}, {gia_chu}, {dia_chi}, {nguoi_mat}, {quan_he}, {nam_mat}

class PrayerItem {
  final String id;
  final String title;
  final String category; // 'gio', 'tet', 'le_tiet', 'ram_mung_mot'
  final String occasion; // Thời gian & Ý nghĩa
  final List<String> offerings; // Gợi ý sắm lễ
  final String content; // Nội dung văn khấn
  final String notes; // Lưu ý văn hóa / phong tục

  const PrayerItem({
    required this.id,
    required this.title,
    required this.category,
    required this.occasion,
    required this.offerings,
    required this.content,
    required this.notes,
  });
}

class PrayersData {
  static const List<PrayerItem> allPrayers = [
    // ==========================================
    // 1. VĂN KHẤN NGÀY GIỖ (HIẾU ĐẠO GIA TIÊN)
    // ==========================================
    PrayerItem(
      id: 'gio_tien_thuong',
      title: 'Văn Khấn Lễ Tiên Thường (Cúng Chiều Hôm Trước Giỗ)',
      category: 'gio',
      occasion: 'Cúng vào buổi chiều ngày hôm trước ngày giỗ chính để cáo thỉnh Gia tiên và vong linh người mất về dự tiệc giỗ.',
      offerings: [
        'Hương hoa tươi, trầu cau, quả tươi',
        'Nước trong, trà, rượu',
        'Mâm cỗ mặn hoặc mâm cỗ chay giản dị',
        'Vàng mã cúng Tiên thường',
      ],
      notes: 'Lễ Tiên Thường là nghi thức kính báo gia tiên và mời hương linh về nhà từ ngày hôm trước, thể hiện tấm lòng chu đáo của con cháu.',
      content: '''Nam mô A Di Đà Phật! (3 lần, 3 lạy)

Con lạy chín phương Trời, mười phương Chư Phật, Chư Phật mười phương.
Con kính lạy Hoàng thiên Hậu Thổ chư vị Tôn thần.
Con kính lạy ngài Đông Trù Tư mệnh Táo phủ Thần quân.
Con kính lạy Thần linh, Thổ địa cai quản trong xứ này.
Con kính lạy Tổ Tiên nội ngoại họ... chư vị Hương linh.

Tín chủ con là: {gia_chu}
Ngụ tại: {dia_chi}

Hôm nay là chiều ngày {ngay_tien_thuong} (Âm lịch).
Ngày mai là ngày {ngay_chinh_ky} (Âm lịch), là ngày Chính kỵ của {quan_he} {nguoi_mat}.

Nghĩ đến công đức sinh thành dưỡng dục vô biên, con cháu chúng con một dạ thành tâm kính nhớ. Nay thiết lễ Tiên thường, kính dâng lễ vật, hương hoa phù tửu, lòng thành thắp nén tâm hương.

Kính thỉnh chư vị Thần linh, Thổ công ngự trước án giáng lâm chứng giám.
Kính mời chân linh {quan_he} {nguoi_mat} cùng chư vị Hương linh tiền tổ nội ngoại giáng phó từ đường, thụ hưởng lễ vật, độ trì cho toàn thể gia quyến bình an, mạnh khỏe, gia đạo hưng long, vạn sự cát tường.

Dãi tấm lòng thành, cúi xin chứng giám!
Nam mô A Di Đà Phật! (3 lần, 3 lạy)''',
    ),

    PrayerItem(
      id: 'gio_chinh_ky',
      title: 'Văn Khấn Lễ Chính Kỵ (Ngày Giỗ Thường / Cát Kỵ)',
      category: 'gio',
      occasion: 'Cúng vào buổi sáng (hoặc trưa) đúng ngày giỗ (từ năm thứ 3 sau ngày mất trở đi).',
      offerings: [
        'Mâm cỗ mặn (gà luộc, xôi/bánh chưng, canh măng, miến xào, nem...) hoặc cỗ chay thanh tịnh',
        'Hương trầm, hoa tươi, trầu cau, rượu, nước trong, đèn dầu/nến',
        'Vàng mã gia tiên',
      ],
      notes: 'Thường cúng từ 8h00 - 11h00 sáng. Sau khi tàn tuần hương mới xin hạ lễ để con cháu quây quần thụ lộc.',
      content: '''Nam mô A Di Đà Phật! (3 lần, 3 lạy)

Con lạy chín phương Trời, mười phương Chư Phật, Chư Phật mười phương.
Con kính lạy Hoàng thiên Hậu Thổ chư vị Tôn thần.
Con kính lạy ngài Đông Trù Tư mệnh Táo phủ Thần quân.
Con kính lạy ngài Bản gia Thổ địa Long Mạch Tôn thần.
Con kính lạy các ngài Ngũ phương, Ngũ thổ, Phúc đức Tôn thần.
Con kính lạy chư vị Hương linh tiền tổ nội ngoại họ...

Tín chủ con là: {gia_chu}
Ngụ tại: {dia_chi}

Hôm nay là ngày {ngay_am}, chính là ngày Chính kỵ của {quan_he} {nguoi_mat}.

Thiết nghĩ {quan_he} vắng bóng trần gian, vĩnh biệt cõi dương, nay đến ngày kỷ niệm, tưởng nhớ khôn nguôi.
Chính trực sinh thời có đức cao dày, con cháu khôn lớn nhớ ơn dưỡng dục.

Nay lòng thành kính cẩn, chúng con dâng mâm cỗ phẩm vật thanh tịnh, giọt rượu hương thơm, kính mời:
Chân linh {quan_he} {nguoi_mat} giáng lâm trước án, thụ hưởng lễ vật, chứng giám lòng thành.

Lại kính thỉnh chư vị Tổ Bá, Tổ Thúc, Tổ Cô và các chân linh tiền tổ nội ngoại cùng về hâm hưởng.
Cúi xin phù hộ độ trì cho toàn gia đình: già trẻ bình an, con cháu hiếu thảo, đỗ đạt công danh, tài lộc dồi dào, bốn mùa không điều trắc trở.

Lòng thành kính cẩn, cúi xin chứng giám!
Nam mô A Di Đà Phật! (3 lần, 3 lạy)''',
    ),

    PrayerItem(
      id: 'gio_dau',
      title: 'Văn Khấn Giỗ Đầu (Lễ Tiểu Tường - Tròn 1 Năm)',
      category: 'gio',
      occasion: 'Cúng vào đúng ngày giỗ tròn 1 năm sau khi người thân qua đời (Vẫn trong thời kỳ chịu tang).',
      offerings: [
        'Mâm cỗ mặn hoặc chay chu đáo',
        'Hương hoa, cau trầu, quần áo giấy mã đúng theo độ tuổi và giới tính người mất',
        'Trà, rượu, nến thắp sáng',
      ],
      notes: 'Lễ Tiểu Tường mang tính chất tang lễ trang nghiêm, con cháu mặc đồ tang tề tựu tưởng nhớ.',
      content: '''Nam mô A Di Đà Phật! (3 lần, 3 lạy)

Con lạy chín phương Trời, mười phương Chư Phật, Chư Phật mười phương.
Con kính lạy Chư vị Thần linh cai quản khu vực bản gia.
Con kính lạy Tiên linh nội ngoại dòng họ...

Tín chủ con là: {gia_chu}
Ngụ tại: {dia_chi}

Hôm nay ngày {ngay_am}, tròn ngày giỗ đầu (Tiểu Tường) của {quan_he} {nguoi_mat}.

Thời gian thấm thoát thoi đưa, nỗi đau mất mát khôn xiết nguôi ngoai. Nhớ ơn sinh thành dưỡng dục cao dày như non thái, nay nhân ngày giỗ đầu, toàn thể gia quyến thiết lập linh sàng, dâng mâm cơm canh quả thực, kính dâng giọt lệ sầu bi tưởng nhớ.

Kính thỉnh chân linh {quan_he} {nguoi_mat} giáng phó linh sàng, chứng giám lòng thành hiếu thảo, thụ hưởng phẩm vật.
Cầu mong hương linh sớm siêu sinh tịnh độ, phò hộ độ trì cho cháu con an hòa, tai qua nạn khỏi.

Nam mô A Di Đà Phật! (3 lần, 3 lạy)''',
    ),

    // ==========================================
    // 2. VĂN KHẤN TẾT NGUYÊN ĐÁN TRỌN GÓI
    // ==========================================
    PrayerItem(
      id: 'tet_ong_tao',
      title: 'Văn Khấn Cúng Ông Công Ông Táo (23 Tháng Chạp)',
      category: 'tet',
      occasion: 'Cúng trước 12h00 trưa ngày 23 tháng Chạp âm lịch tiễn Táo Quân chầu Trời.',
      offerings: [
        '3 bộ mũ Táo quân (2 mũ chuồn nam, 1 mũ nữ)',
        '3 con cá chép sống thả chậu nước sạch để phóng sinh',
        'Mâm cỗ mặn (gà luộc, đĩa xôi) hoặc cỗ ngọt',
        'Hương hoa quả tươi, trầu cau, vàng mã Táo quân',
      ],
      notes: 'Nên cúng xong trước giờ Ngọ (12h trưa) ngày 23 tháng Chạp để Táo quân kịp giờ bay về Thiên đình báo cáo Ngọc Hoàng.',
      content: '''Nam mô A Di Đà Phật! (3 lần, 3 lạy)

Con lạy chín phương Trời, mười phương Chư Phật, Chư Phật mười phương.
Con kính lạy Ngài Đông trù Tư mệnh Táo phủ Thần quân.

Tín chủ con là: {gia_chu}
Ngụ tại: {dia_chi}

Hôm nay ngày 23 tháng Chạp năm {nam_am}, tín chủ chúng con thành tâm sắm lễ: hương hoa phẩm vật, xiêm hài áo mũ kính dâng trước án tôn thần.

Kính lạy ngài Táo phủ Thần quân, chúa tể một nhà, giám sát vạn sự.
Cả một năm qua, nhờ ơn ngài che chở, gia sự thuận hòa, bình an no ấm.
Nay tiết cuối năm, thành tâm kính tiễn ngài cỡi cá chép bay về chầu Thiên đình.

Kính xin ngài bẩm tấu những điều tốt lành, giãi bày những điều sơ sót, cầu xin Thượng đế ban phúc ban lộc, phù hộ cho đất nước thanh bình, gia đình chúng con năm mới sang đắc tài sai lộc, người người bình an, vạn sự như ý.

Cúi xin Tôn thần giáng lâm thụ hưởng, soi thấu lòng thành!
Nam mô A Di Đà Phật! (3 lần, 3 lạy)''',
    ),

    PrayerItem(
      id: 'tet_tat_nien',
      title: 'Văn Khấn Lễ Tất Niên Chiều 30 Tết',
      category: 'tet',
      occasion: 'Cúng vào chiều ngày 30 Tết (hoặc 29 Tết nếu tháng thiếu) để tống cựu nghênh tân, mời tổ tiên về ăn Tết cùng gia đình.',
      offerings: [
        'Mâm cỗ Tất niên tươm tất (bánh chưng, gà luộc, giò chả, canh măng miến)',
        'Bát hương lau dọn sạch sẽ, hoa tươi (hoa đào, mai, cúc)',
        'Trầu cau, mâm ngũ quả, đèn nến, vàng mã Tất niên',
      ],
      notes: 'Bữa cơm Tất niên là bữa sum họp thiêng liêng nhất trong năm của đại gia đình người Việt.',
      content: '''Nam mô A Di Đà Phật! (3 lần, 3 lạy)

Con lạy chín phương Trời, mười phương Chư Phật, Chư Phật mười phương.
Con kính lạy Hoàng thiên Hậu Thổ chư vị Tôn thần.
Con kính lạy ngài Kim niên Đương cai Thái Tuế Chí đức Tôn thần.
Con kính lạy các ngài Bản xứ Thần linh Thổ địa, Táo phủ Thần quân cai quản chốn này.
Con kính lạy chư vị Tổ Tiên nội ngoại chư vị Hương linh.

Tín chủ con là: {gia_chu}
Ngụ tại: {dia_chi}

Hôm nay là chiều ngày 30 tháng Chạp năm {nam_am}.
Giờ phút chuyển giao năm cũ sắp qua, năm mới sắp đến.

Chúng con thành tâm sắm biện hương hoa cơm canh thanh tịnh, kính dâng trước án.
Cúi xin chư vị Tôn thần, liệt vị Tiên tổ giáng lâm trước án, thụ hưởng lễ vật.
Tạ ơn trời đất thần Phật và gia tiên đã phù hộ cho một năm qua vạn sự bình yên.
Kính mời Tổ tiên, ông bà, cô bác nội ngoại về ngự linh sàng cùng con cháu vui vầy đón mừng Tết Nguyên Đán.

Cúi xin phù hộ cho gia đình sang năm mới Tân xuân đắc lộc đắc tài, khang ninh thịnh vượng!
Nam mô A Di Đà Phật! (3 lần, 3 lạy)''',
    ),

    PrayerItem(
      id: 'tet_giao_thua_ngoai_troi',
      title: 'Văn Khấn Đêm Giao Thừa Ngoài Trời (Trừ Tịch)',
      category: 'tet',
      occasion: 'Cúng vào đúng khắc 00h00 đêm Giao thừa ở ngoài sân/ban công để tiễn quan Hành khiển năm cũ và đón quan Hành khiển năm mới.',
      offerings: [
        'Gà trống thiến luộc ngậm hoa hồng, bánh chưng',
        'Xôi gấc đỏ may mắn, hoa tươi, trầu cau',
        'Đĩa muối gạo, 1 chén rượu, 1 chén nước',
        'Bộ sớ/vàng mã nghênh tân cúng quan Hành khiển',
      ],
      notes: 'Bàn lễ đặt ngoài trời hướng về phương cát lợi. Nghi thức đón rước các vị quan coi sóc thiên hạ trong năm mới.',
      content: '''Nam mô A Di Đà Phật! (3 lần, 3 lạy)

Con kính lạy Chín phương Trời, Mười phương Chư Phật, Chư Phật mười phương.
Con kính lạy Đức Đương lai hạ sinh Di Lặc Tôn Phật.
Con kính lạy Hoàng thiên, Hậu Thổ, chư vị Tôn thần.
Con kính lạy ngài Cựu niên Đương cai Hành khiển Tôn thần.
Con kính lạy ngài Tân niên Đương cai Hành khiển Tôn thần.
Con kính lạy Bản cảnh Thành hoàng, chư vị Đại Vương, Tôn thần cai quản xứ này.

Tín chủ con là: {gia_chu}
Ngụ tại: {dia_chi}

Phút thiêng liêng Giao thừa vừa tới, năm cũ qua đi, năm mới đã sang, tam dương khai thái, vạn tượng canh tân.
Nay ngài Thái Tuế Tôn thần trên vâng lệnh Thượng Đế giám sát vạn dân dưới trần thế.

Chúng con thành tâm sắm sửa hương hoa phẩm vật, dâng lên trước án ngoài trời, kính cẩn tiến dâng.
Cúi xin chư vị Tôn thần chứng giám lòng thành, thụ hưởng lễ vật, trừ tai trừ ách, phò hộ cho quốc thái dân an, cho gia đình chúng con bước sang năm mới nhân khang vật thịnh, bình an vô sự, sở cầu như ý, sở nguyện tòng tâm.

Dãi tấm lòng thành, cúi xin chứng giám!
Nam mô A Di Đà Phật! (3 lần, 3 lạy)''',
    ),

    PrayerItem(
      id: 'tet_giao_thua_trong_nha',
      title: 'Văn Khấn Đêm Giao Thừa Trong Nhà (Cúng Gia Tiên)',
      category: 'tet',
      occasion: 'Cúng ngay sau khi kết thúc lễ Giao thừa ngoài trời để rước tổ tiên về phù hộ đầu năm mới.',
      offerings: [
        'Mâm cỗ mặn hoặc mâm cỗ ngọt truyền thống',
        'Mâm ngũ quả tươi, hoa tươi rực rỡ',
        'Hương trầm, nến sáng lung linh, trầu cau, nước trà',
      ],
      notes: 'Sau khi cúng giao thừa trong nhà, các thành viên chúc Tết mừng tuổi nhau và đi lễ chùa cầu may.',
      content: '''Nam mô A Di Đà Phật! (3 lần, 3 lạy)

Con lạy chín phương Trời, mười phương Chư Phật, Chư Phật mười phương.
Con kính lạy ngài Đông trù Tư mệnh Táo phủ Thần quân.
Con kính lạy Bản gia Thổ công, Thổ địa, Long mạch Tôn thần.
Con kính lạy Tiên tổ nội ngoại gia tiên họ...

Tín chủ con là: {gia_chu}
Ngụ tại: {dia_chi}

Nay phút Giao thừa đầu xuân vừa điểm, đất trời hòa hợp, cảnh vật tốt tươi.
Toàn thể gia quyến chúng con tề tựu trước bàn thờ gia tiên, đốt nén tâm hương, dâng mâm quả ngọt cỗ bàn thơm thảo kính dâng.

Kính mời Thần linh ngự trị chốn này chứng giám.
Kính mời Liệt vị Tiên tổ, ông bà cha mẹ nội ngoại giáng lâm trước ban thờ hâm hưởng lễ vật.
Phù hộ độ trì cho gia đình con cháu bước sang năm mới: sức khỏe dồi dào, trí tuệ minh mẫn, gặp nhiều may mắn, ăn nên làm ra, gia đạo êm ấm trên thuận dưới hòa.

Cúi xin chứng giám lòng thành!
Nam mô A Di Đà Phật! (3 lần, 3 lạy)''',
    ),

    PrayerItem(
      id: 'tet_hoa_vang',
      title: 'Văn Khấn Lễ Tạ Năm Mới (Lễ Hóa Vàng Mùng 3 - Mùng 7 Tết)',
      category: 'tet',
      occasion: 'Làm vào ngày tiễn gia tiên sau kỳ nghỉ Tết (thường chọn mùng 3, mùng 4 hoặc mùng 7 Tết).',
      offerings: [
        'Mâm cỗ mặn thịnh soạn, bánh chưng bóc vỏ',
        'Vàng mã Tết, tiền vàng, 2 cây mía dài tượng trưng làm gậy gánh vàng về âm giới',
        'Hoa quả tươi, trầu cau, rượu trà',
      ],
      notes: 'Lễ hóa vàng tiễn ông bà tổ tiên trở về cõi âm sau mấy ngày Tết vui vầy cùng con cháu.',
      content: '''Nam mô A Di Đà Phật! (3 lần, 3 lạy)

Con lạy chín phương Trời, mười phương Chư Phật, Chư Phật mười phương.
Con kính lạy Hoàng thiên Hậu Thổ chư vị Tôn thần.
Con kính lạy ngài Đông trù Tư mệnh Táo phủ Thần quân, Ngũ phương ngũ thổ Long mạch Tôn thần.
Con kính lạy Tổ Tiên nội ngoại chư vị Hương linh.

Tín chủ con là: {gia_chu}
Ngụ tại: {dia_chi}

Hôm nay ngày {ngay_am} tháng Giêng năm {nam_am}.
Tiết xuân vừa sang, ngày Tết Nguyên Đán trọn vẹn thắm tình, nay tiệc xuân đã mãn, con cháu thiết lễ tạ kỳ xuân, kính tiễn chư vị Tôn thần và chư vị Tiên tổ quy hồi âm giới.

Kính dâng phẩm vật: hương hoa quả thực, kim ngân tài mã, rượu nồng nước ngọt.
Cúi xin các vị Tôn thần và Gia tiên thụ hưởng, phù hộ độ trì cho cháu con năm mới công việc thuận buồm xuôi gió, tai ách tiêu trừ, phước lộc thọ toàn.

Kính thỉnh xin hóa kim ngân, tiền vàng hồi nguyên cõi âm!
Nam mô A Di Đà Phật! (3 lần, 3 lạy)''',
    ),

    // ==========================================
    // 3. VĂN KHẤN NGÀY RẰM & MÙNG MỘT HÀNG THÁNG
    // ==========================================
    PrayerItem(
      id: 'ram_mung_mot_gia_tien',
      title: 'Văn Khấn Cúng Ngày Sóc (Mùng Một) & Vọng (Rằm) Hàng Tháng',
      category: 'ram_mung_mot',
      occasion: 'Cúng vào chiều 30 / sáng mùng 1 (ngày Sóc) hoặc chiều 14 / sáng ngày Rằm 15 (ngày Vọng) âm lịch hàng tháng.',
      offerings: [
        'Hương thơm, hoa tươi (hoa cúc, hoa huệ...), quả ngọt theo mùa',
        'Trầu cau, nước sạch, đèn dầu hoặc nến',
        'Có thể cúng chay thanh tịnh hoặc mâm cỗ mặn tùy điều kiện gia đình',
      ],
      notes: 'Ngày sóc vọng là ngày trăng tròn và ngày đầu tháng, con cháu thắp hương kính nhớ tổ tiên cầu mong tháng mới hanh thông bình an.',
      content: '''Nam mô A Di Đà Phật! (3 lần, 3 lạy)

Con lạy chín phương Trời, mười phương Chư Phật, Chư Phật mười phương.
Con kính lạy Hoàng thiên Hậu Thổ chư vị Tôn thần.
Con kính lạy ngài Đông Trù Tư mệnh Táo phủ Thần quân.
Con kính lạy ngài Bản gia Thổ địa Long Mạch Tôn thần.
Con kính lạy chư vị Hương linh tiền tổ nội ngoại.

Tín chủ con là: {gia_chu}
Ngụ tại: {dia_chi}

Hôm nay là ngày {ngay_am} (ngày Sóc / Vọng tháng {thang_am} năm {nam_am}).
Tín chủ con thành tâm sắm lễ: hương hoa trà quả, đốt nén tâm hương dâng lên trước án.

Kính mời các ngài Tôn thần giáng lâm chứng giám.
Kính thỉnh các cụ Tổ tiên, ông bà cha mẹ nội ngoại cùng chư vị hương linh hiển linh trước ban thờ, thụ hưởng lễ vật.

Cúi xin phù hộ độ trì cho toàn thể gia quyến: trong ấm ngoài êm, thân tâm an lạc, tai qua nạn khỏi, công việc hanh thông, buôn may bán đắt, vạn sự cát tường.

Dãi tấm lòng thành, cúi xin chứng giám!
Nam mô A Di Đà Phật! (3 lần, 3 lạy)''',
    ),

    // ==========================================
    // 4. VĂN KHẤN CÁC LỄ TIẾT TRONG NĂM
    // ==========================================
    PrayerItem(
      id: 'ram_thang_gieng',
      title: 'Văn Khấn Rằm Tháng Giêng (Tết Thượng Nguyên)',
      category: 'le_tiet',
      occasion: 'Ngày 15 tháng Giêng Âm lịch. "Cả năm được rằm tháng Bảy, không bằng rằm tháng Giêng". Lễ cầu an lành lớn nhất đầu năm.',
      offerings: [
        'Mâm cỗ chay dâng Phật (hoa quả, chè trôi nước)',
        'Mâm cỗ mặn dâng Thần linh và Gia tiên',
        'Hương, hoa tươi, trầu cau, đèn nến, bánh chưng',
      ],
      notes: 'Rằm tháng Giêng là đêm rằm đầu tiên của năm mới, ánh trăng tròn đầy viên mãn, cầu bình an cho cả một năm.',
      content: '''Nam mô A Di Đà Phật! (3 lần, 3 lạy)

Con lạy chín phương Trời, mười phương Chư Phật, Chư Phật mười phương.
Con kính lạy Hoàng thiên Hậu Thổ chư vị Tôn thần.
Con kính lạy ngài Bản cảnh Thành hoàng, ngài Bản gia Táo quân, Thổ địa tôn thần.
Con kính lạy Cao tằng tổ khảo, Cao tằng tổ tỷ, bá thúc huynh đệ cô di tỷ muội nội ngoại.

Tín chủ con là: {gia_chu}
Ngụ tại: {dia_chi}

Hôm nay là ngày Rằm tháng Giêng năm {nam_am}, nhằm tiết Thượng Nguyên thiên quan tứ phước.
Gia đình con một dạ chí thành, sửa biện hương hoa đăng trà quả thực, kính dâng trước án.

Cầu xin Phật Thánh chứng minh, Thần linh gia ân bảo hộ.
Kính mời chư vị Tiên linh gia quyến đồng lâm thụ hưởng lễ vật.

Cúi xin phù hộ độ trì cho cả năm mới: phong điều vũ thuận, gia đình hòa thuận, vạn sự bình an, lộc tài vượng phát.

Nam mô A Di Đà Phật! (3 lần, 3 lạy)''',
    ),

    PrayerItem(
      id: 'tet_han_thuc',
      title: 'Văn Khấn Tết Hàn Thực (Mùng 3 Tháng 3 Âm Lịch)',
      category: 'le_tiet',
      occasion: 'Ngày mùng 3 tháng 3 Âm lịch. Dâng cúng bánh trôi, bánh chay tưởng nhớ tổ tiên.',
      offerings: [
        'Đĩa bánh trôi, bát bánh chay (thường là 3 hoặc 5 bát bánh chay, đĩa bánh trôi)',
        'Hương hoa quả tươi, trầu cau, nước sạch',
      ],
      notes: 'Bánh trôi tròn xoe, trắng trong tượng trưng cho sự thuần khiết, hướng về cội nguồn dân tộc.',
      content: '''Nam mô A Di Đà Phật! (3 lần, 3 lạy)

Con lạy chín phương Trời, mười phương Chư Phật, Chư Phật mười phương.
Con kính lạy Hoàng thiên Hậu Thổ chư vị Tôn thần.
Con kính lạy ngài Đông trù Tư mệnh Táo phủ Thần quân.
Con kính lạy Tổ Tiên nội ngoại chư vị Hương linh.

Tín chủ con là: {gia_chu}
Ngụ tại: {dia_chi}

Hôm nay là ngày mùng 3 tháng 3 năm {nam_am}, tiết Hàn Thực.
Tín chủ con thành tâm chuẩn bị phẩm vật: bánh trôi bánh chay thơm ngọt, hương hoa trà quả, kính dâng trước án.

Kính mời Thần linh ngự xứ chứng giám.
Kính mời Tiên tổ nội ngoại giáng lâm trước ban thờ thụ hưởng phẩm vật.

Kính nguyện tổ tiên chứng cho lòng thành thảo hiếu, độ trì cho gia đình con cháu yên vui sum vầy, vạn sự hanh thông.

Nam mô A Di Đà Phật! (3 lần, 3 lạy)''',
    ),

    PrayerItem(
      id: 'tet_doan_ngo',
      title: 'Văn Khấn Tết Đoan Ngọ (Mùng 5 Tháng 5 Âm Lịch)',
      category: 'le_tiet',
      occasion: 'Ngày mùng 5 tháng 5 Âm lịch. Tết giết sâu bọ, cúng giữa giờ Ngọ (11h - 13h trưa).',
      offerings: [
        'Rượu nếp cái / nếp cẩm, mận, vải, dưa hấu, đào... (các loại quả chua chát trừ sâu bọ)',
        'Bánh tro (bánh ú tro), chè sen',
        'Hương hoa, vàng mã Đoan Ngọ, trầu cau',
      ],
      notes: 'Thời điểm dương khí thịnh nhất trong năm, trừ sâu bọ tà khí và cầu mong mùa màng tốt tươi.',
      content: '''Nam mô A Di Đà Phật! (3 lần, 3 lạy)

Con lạy chín phương Trời, mười phương Chư Phật, Chư Phật mười phương.
Con kính lạy Hoàng thiên Hậu Thổ chư vị Tôn thần.
Con kính lạy ngài Táo phủ Thần quân, Thần linh bản thổ.
Con kính lạy chư vị Hương linh tiền tổ nội ngoại.

Tín chủ con là: {gia_chu}
Ngụ tại: {dia_chi}

Hôm nay là ngày mùng 5 tháng 5 năm {nam_am}, tiết Đoan Ngọ giữa trưa.
Chúng con thiết lập án thờ, dâng nén tâm hương cùng cơm rượu nếp, hoa quả ngọt lành, bánh tro thanh mát kính dâng lên trước án.

Cúi xin Thần linh và Tiên tổ phù trì: trừ khử tà khí, diệt trừ bệnh tật, cho con cháu khỏe mạnh an khang, ruộng vườn xanh tốt, mọi bề hưng vượng.

Nam mô A Di Đà Phật! (3 lần, 3 lạy)''',
    ),

    PrayerItem(
      id: 'ram_thang_bay_vu_lan',
      title: 'Văn Khấn Lễ Vu Lan Báo Hiếu (Rằm Tháng Bảy)',
      category: 'le_tiet',
      occasion: 'Ngày 15 tháng 7 Âm lịch (tiến hành từ mùng 2 đến rằm tháng 7). Mùa báo hiếu tứ thân phụ mẫu và xá tội vong nhân.',
      offerings: [
        'Mâm cúng Phật chay tịnh',
        'Mâm cúng Gia tiên (cúng trong nhà)',
        'Mâm cúng chúng sinh / cô hồn ngoài sân (cháo hoa loãng, gạo muối, bỏng ngô, bánh kẹo, tiền lẻ)',
      ],
      notes: 'Dịp lễ trọng nhất về đạo hiếu trong văn hóa Việt Nam. Cúng gia tiên trước trong nhà, cúng thí thực chúng sinh sau ở ngoài sân.',
      content: '''Nam mô Bổn Sư Thích Ca Mâu Ni Phật! (3 lần)
Nam mô Đại Hiếu Mục Kiền Liên Bồ Tát! (3 lần)

Con lạy chín phương Trời, mười phương Chư Phật, Chư Phật mười phương.
Con kính lạy chư vị Tôn thần cai quản bản gia.
Con kính lạy Liệt vị Tiên tổ nhiều đời nội ngoại dòng họ...

Tín chủ con là: {gia_chu}
Ngụ tại: {dia_chi}

Hôm nay là ngày Rằm tháng Bảy năm {nam_am}, tiết Trung Nguyên mùa Vu Lan Thắng Hội.
Nhớ đức sinh thành dưỡng dục cù lao, ơn sâu nghĩa nặng tựa biển trời.
Nay nhờ ơn Phật từ bi xá tội vong nhân, con cháu chí thành thiết lễ: hương đăng trà quả, cơm canh thanh tịnh dâng lên trước án kính mời Tiên tổ.

Kính thỉnh hương linh ông bà cha mẹ nội ngoại cùng chư vị hương linh thân tộc đồng lai thụ hưởng.
Nguyện cầu Phật lực gia trì, cho hương linh sớm siêu sinh miền Lạc quốc, phù hộ cháu con đời đời hiếu thuận, nhân hòa gia ấm.

Nam mô A Di Đà Phật! (3 lần, 3 lạy)''',
    ),

    PrayerItem(
      id: 'le_thanh_minh_tao_mo',
      title: 'Văn Khấn Lễ Thanh Minh / Tảo Mộ / Chạp Mả',
      category: 'le_tiet',
      occasion: 'Tiết Thanh Minh (tháng 3 Âm lịch) hoặc Lễ Chạp mả cuối năm (tháng Chạp) khi đi thăm và sửa sang phần mộ tổ tiên.',
      offerings: [
        'Hương hoa tươi, trầu cau, quả tươi, nước trong, rượu',
        'Mâm cỗ mặn (gà luộc, xôi) hoặc cỗ ngọt bánh trái',
        'Vàng mã cúng tạ Thổ Thần cai quản nghĩa trang và vàng mã cúng Gia tiên',
      ],
      notes: 'Khi ra mộ, phải khấn Thần Linh Thổ Địa nơi nghĩa trang trước xin phép cho gia tiên được thụ hưởng, rồi mới khấn trước phần mộ của người thân.',
      content: '''Nam mô A Di Đà Phật! (3 lần, 3 lạy)

Con lạy chín phương Trời, mười phương Chư Phật, Chư Phật mười phương.
Con kính lạy ngài Hoàng thiên Hậu Thổ chư vị Tôn thần.
Con kính lạy ngài Thành hoàng, Sơn thần, Thổ địa cai quản nơi nghĩa trang bản xứ này.
Con kính lạy hương linh: {quan_he} {nguoi_mat} cùng chư vị tiên tổ an nghỉ nơi đây.

Tín chủ con là: {gia_chu}
Ngụ tại: {dia_chi}

Hôm nay nhân tiết Thanh Minh (hoặc Lễ Chạp mả cuối năm), con cháu hướng về nguồn cội, đến trước phần mộ kính cẩn phát cỏ sửa sang, thắp nén tâm hương tỏ lòng thành kính nhớ.

Trước kính tạ ơn chư vị Sơn thần Thổ địa che chở phù hộ cho nơi an nghỉ ngàn thu của tiên tổ được yên tĩnh ấm êm.
Sau kính rước hương linh {quan_he} {nguoi_mat} cùng tiền tổ chứng giám tấc lòng thơm thảo, thụ hưởng lễ vật.

Cúi xin hương linh che chở cho toàn gia quyến: tai qua nạn khỏi, con cháu thảo hiền, muôn sự bình yên!

Nam mô A Di Đà Phật! (3 lần, 3 lạy)''',
    ),
  ];

  /// Hàm hỗ trợ thay thế thông tin động vào bài cúng
  static String formatPrayerContent({
    required String template,
    required String giaChu,
    required String diaChi,
    String? ngayAm,
    String? namAm,
    String? ngayTienThuong,
    String? ngayChinhKy,
    String? thangAm,
    String? nguoiMat,
    String? quanHe,
  }) {
    var result = template
        .replaceAll('{gia_chu}', giaChu.isNotEmpty ? giaChu : '........................................')
        .replaceAll('{dia_chi}', diaChi.isNotEmpty ? diaChi : '........................................')
        .replaceAll('{ngay_am}', ngayAm ?? '........................')
        .replaceAll('{nam_am}', namAm ?? '........................')
        .replaceAll('{ngay_tien_thuong}', ngayTienThuong ?? '........................')
        .replaceAll('{ngay_chinh_ky}', ngayChinhKy ?? '........................')
        .replaceAll('{thang_am}', thangAm ?? '........................')
        .replaceAll('{nguoi_mat}', nguoiMat ?? '........................')
        .replaceAll('{quan_he}', quanHe ?? '........................');
    return result;
  }
}
