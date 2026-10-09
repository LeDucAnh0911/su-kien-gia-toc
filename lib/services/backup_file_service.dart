import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/event_model.dart';
import '../models/family_person.dart';

class BackupFileService {
  static String _escapeCsv(dynamic value) {
    if (value == null) return '""';
    final str = value.toString().replaceAll('"', '""');
    return '"$str"';
  }

  /// Xuất tệp văn bản hoặc CSV đa nền tảng
  static Future<bool> exportFile({
    required BuildContext context,
    required String content,
    required String fileName,
    required String mimeType,
  }) async {
    try {
      final bytes = utf8.encode(content);
      if (kIsWeb) {
        final xFile = XFile.fromData(
          Uint8List.fromList(bytes),
          mimeType: mimeType,
          name: fileName,
        );
        await xFile.saveTo(fileName);
        return true;
      } else {
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        final xFile = XFile(filePath, mimeType: mimeType, name: fileName);
        final box = context.findRenderObject() as RenderBox?;
        final origin = box != null ? box.localToGlobal(Offset.zero) & box.size : null;

        final result = await Share.shareXFiles(
          [xFile],
          text: 'Tệp $fileName',
          sharePositionOrigin: origin,
        );
        return result.status == ShareResultStatus.success || result.status == ShareResultStatus.dismissed;
      }
    } catch (e) {
      debugPrint('Lỗi khi xuất tệp: $e');
      return false;
    }
  }

  /// Xuất file sao lưu .json về máy hoặc mở hộp thoại chia sẻ Zalo/Drive/Files
  static Future<bool> exportBackupFile({
    required BuildContext context,
    required String jsonContent,
    String? customFileName,
  }) async {
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final fileName = customFileName ?? 'GiaPha_SuKien_Backup_$dateStr.json';
    return exportFile(
      context: context,
      content: jsonContent,
      fileName: fileName,
      mimeType: 'application/json',
    );
  }

  /// Xuất danh sách Ngày Giỗ & Sự Kiện Gia Tộc ra file Excel/CSV chuẩn UTF-8 BOM
  static Future<bool> exportEventsCsv({
    required BuildContext context,
    required List<EventItem> events,
  }) async {
    final buffer = StringBuffer();
    buffer.write('\uFEFF'); // UTF-8 BOM để Excel tiếng Việt không lỗi font
    buffer.writeln('STT,Tên Sự Kiện,Người Tưởng Nhớ,Quan Hệ,Lịch,Ngày/Tháng,Năm,Nơi An Nghỉ,Ghi Chú');
    for (int i = 0; i < events.length; i++) {
      final e = events[i];
      final calStr = e.calendar == CalendarType.lunar ? 'Âm lịch' : 'Dương lịch';
      final dateStr = 'Ngày ${e.day}/${e.month}${e.isLeapMonth ? " (Nhuận)" : ""}';
      final yearStr = e.year != null ? '${e.year}' : '';
      buffer.writeln('${i + 1},${_escapeCsv(e.title)},${_escapeCsv(e.personName ?? "")},${_escapeCsv(e.relation ?? "")},${_escapeCsv(calStr)},${_escapeCsv(dateStr)},${_escapeCsv(yearStr)},${_escapeCsv(e.restingPlace ?? "")},${_escapeCsv(e.notes ?? "")}');
    }
    final now = DateTime.now();
    final fileName = 'Danh_Sach_Su_Kien_Gia_Toc_${now.year}${now.month.toString().padLeft(2, "0")}${now.day.toString().padLeft(2, "0")}.csv';
    return exportFile(
      context: context,
      content: buffer.toString(),
      fileName: fileName,
      mimeType: 'text/csv',
    );
  }

  /// Xuất danh sách Thành Viên Gia Phả ra file Excel/CSV chuẩn UTF-8 BOM
  static Future<bool> exportFamilyCsv({
    required BuildContext context,
    required List<FamilyPerson> people,
  }) async {
    final buffer = StringBuffer();
    buffer.write('\uFEFF'); // UTF-8 BOM để Excel tiếng Việt không lỗi font
    buffer.writeln('STT,Họ và Tên,Giới Tính,Nhánh Dòng Họ,Thứ Tự Con,Ngày/Năm Sinh,Ngày/Năm Mất,Quê Quán,Nơi An Táng,Ghi Chú');
    for (int i = 0; i < people.length; i++) {
      final p = people[i];
      final genderStr = p.gender == 'male' ? 'Nam' : p.gender == 'female' ? 'Nữ' : 'Khác';
      final branchStr = p.branch == 'noi' ? 'Bên nội' : p.branch == 'ngoai' ? 'Bên ngoại' : 'Nhánh khác';
      final orderStr = p.birthOrder > 0 ? 'Con thứ ${p.birthOrder}' : '';
      buffer.writeln('${i + 1},${_escapeCsv(p.name)},${_escapeCsv(genderStr)},${_escapeCsv(branchStr)},${_escapeCsv(orderStr)},${_escapeCsv(p.birthDate)},${_escapeCsv(p.deathDate)},${_escapeCsv(p.hometown)},${_escapeCsv(p.restingPlace)},${_escapeCsv(p.notes)}');
    }
    final now = DateTime.now();
    final fileName = 'Danh_Sach_Gia_Pha_${now.year}${now.month.toString().padLeft(2, "0")}${now.day.toString().padLeft(2, "0")}.csv';
    return exportFile(
      context: context,
      content: buffer.toString(),
      fileName: fileName,
      mimeType: 'text/csv',
    );
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
