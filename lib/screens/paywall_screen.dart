import 'package:flutter/material.dart';

import '../services/storage_service.dart';

/// Thông tin bản thử nghiệm. Chưa có thanh toán hoặc quyền Premium được bán.
class PaywallScreen extends StatelessWidget {
  final UserProfile profile;
  final StorageService storageService;
  final Function(UserProfile) onProfileUpdated;

  const PaywallScreen({
    super.key,
    required this.profile,
    required this.storageService,
    required this.onProfileUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sự Kiện Gia Tộc'),
        backgroundColor: const Color(0xFF8B1E0F),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Icon(Icons.auto_awesome_outlined, size: 56, color: Color(0xFFD4AF37)),
          SizedBox(height: 14),
          Text(
            'Bản dùng thử miễn phí',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Text(
            'Các chức năng hiện có được dùng miễn phí. Dữ liệu được lưu trên thiết bị; hãy xuất bản sao lưu thường xuyên.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          SizedBox(height: 24),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dữ liệu gia tộc',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Dữ liệu được lưu trên thiết bị. Hãy xuất bản sao lưu JSON và giữ ở nơi riêng tư. Tệp JSON chưa được mã hóa.',
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đồng bộ nhiều người',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tính năng này đang được hoàn thiện và chưa có trong bản dùng thử. Khi ra mắt, ứng dụng sẽ giải thích rõ quyền truy cập và cách bảo vệ dữ liệu.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
