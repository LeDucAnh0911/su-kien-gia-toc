import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class BackupFileService {
  /// Xuất file sao lưu .json về máy hoặc mở hộp thoại chia sẻ Zalo/Drive/Files
  static Future<bool> exportBackupFile({
    required BuildContext context,
    required String jsonContent,
    String? customFileName,
  }) async {
    try {
      final now = DateTime.now();
      final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final fileName = customFileName ?? 'GiaPha_SoGio_Backup_$dateStr.json';
      final bytes = utf8.encode(jsonContent);

      if (kIsWeb) {
        // Trên nền tảng Web: Kích hoạt tải tệp trực tiếp về trình duyệt
        final xFile = XFile.fromData(
          Uint8List.fromList(bytes),
          mimeType: 'application/json',
          name: fileName,
        );
        await xFile.saveTo(fileName);
        return true;
      } else {
        // Trên thiết bị di động (Android / iOS) hoặc Desktop:
        // Lưu vào thư mục tạm thời và mở chia sẻ (Zalo, Drive, Lưu vào tệp...)
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        final xFile = XFile(filePath, mimeType: 'application/json', name: fileName);
        
        // Mở bảng chia sẻ hệ thống
        final box = context.findRenderObject() as RenderBox?;
        final origin = box != null ? box.localToGlobal(Offset.zero) & box.size : null;

        final result = await Share.shareXFiles(
          [xFile],
          text: 'Tệp sao lưu Gia phả & Sự kiện Gia tộc ($dateStr)',
          sharePositionOrigin: origin,
        );

        return result.status == ShareResultStatus.success || result.status == ShareResultStatus.dismissed;
      }
    } catch (e) {
      debugPrint('Lỗi khi xuất file sao lưu: $e');
      return false;
    }
  }

  /// Mở hộp thoại chọn file .json từ thiết bị và đọc nội dung JSON
  static Future<String?> pickAndReadBackupFile() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (files.isEmpty) {
        return null; // Người dùng hủy chọn
      }

      final pickedFile = files.first;
      return await pickedFile.xFile.readAsString();
    } catch (e) {
      debugPrint('Lỗi khi chọn file sao lưu: $e');
      return null;
    }
  }
}
