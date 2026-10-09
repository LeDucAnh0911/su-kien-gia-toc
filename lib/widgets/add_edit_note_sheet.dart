/// BottomSheet thêm / sửa Ghi chú theo ngày
import 'package:flutter/material.dart';
import '../lunar_engine.dart';
import '../models/note_model.dart';

class AddEditNoteSheet extends StatefulWidget {
  final DateTime initialDate;
  final DailyNoteItem? existingNote;

  const AddEditNoteSheet({
    super.key,
    required this.initialDate,
    this.existingNote,
  });

  @override
  State<AddEditNoteSheet> createState() => _AddEditNoteSheetState();
}

class _AddEditNoteSheetState extends State<AddEditNoteSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late String _content;
  late DateTime _selectedDate;
  late NoteCategory _category;
  String? _time;

  @override
  void initState() {
    super.initState();
    final n = widget.existingNote;
    if (n != null) {
      _title = n.title;
      _content = n.content ?? '';
      _selectedDate = n.date;
      _category = n.category;
      _time = n.time;
    } else {
      _title = '';
      _content = '';
      _selectedDate = widget.initialDate;
      _category = NoteCategory.todo;
      _time = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lunar = VietnameseLunarEngine.solarToLunar(
      _selectedDate.day,
      _selectedDate.month,
      _selectedDate.year,
    );
    final canChiDay = VietnameseLunarEngine.getCanChiDay(lunar.jd);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thanh kéo trên cùng
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tiêu đề Sheet
              Row(
                children: [
                  Icon(
                    widget.existingNote != null ? Icons.edit_note : Icons.note_add,
                    color: const Color(0xFF8B2500),
                    size: 26,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.existingNote != null ? 'Sửa Ghi Chú' : 'Thêm Ghi Chú Mới',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Card hiển thị ngày được chọn (Dương + Âm)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF9EFE6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.amber.withValues(alpha: 0.3) : const Color(0xFFD4AF37),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: Color(0xFF8B2500), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ngày ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} (Dương lịch)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            'Âm lịch: Ngày ${lunar.day} tháng ${lunar.month} • Ngày $canChiDay',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.amber : const Color(0xFF8B2500),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.edit_calendar, size: 16),
                      label: const Text('Đổi ngày', style: TextStyle(fontSize: 12)),
                      onPressed: _pickDate,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Chọn Phân loại ghi chú
              const Text('Phân loại việc:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _categoryChip('Chuẩn bị giỗ/lễ', NoteCategory.offering, Icons.restaurant),
                    const SizedBox(width: 8),
                    _categoryChip('Việc cần làm', NoteCategory.todo, Icons.check_circle_outline),
                    const SizedBox(width: 8),
                    _categoryChip('Gia đình/Dòng họ', NoteCategory.family, Icons.family_restroom),
                    const SizedBox(width: 8),
                    _categoryChip('Ghi nhớ chung', NoteCategory.general, Icons.bookmark_border),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Tiêu đề việc / ghi chú
              TextFormField(
                initialValue: _title,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề ghi chú / Việc cần làm *',
                  hintText: 'VD: Mua lá chuối, nếp, gà chuẩn bị làm giỗ',
                  prefixIcon: Icon(Icons.edit),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Vui lòng nhập nội dung ghi chú' : null,
                onSaved: (val) => _title = val!.trim(),
              ),
              const SizedBox(height: 12),

              // Giờ hẹn nhắc nhở
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.access_time),
                      label: Text(_time != null ? 'Giờ nhắc: $_time' : 'Đặt giờ nhắc (tùy chọn)'),
                      onPressed: _pickTime,
                    ),
                  ),
                  if (_time != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      tooltip: 'Bỏ giờ',
                      onPressed: () => setState(() => _time = null),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Chi tiết ghi chú
              TextFormField(
                initialValue: _content,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Chi tiết thêm (tùy chọn)',
                  hintText: 'VD: Phân công cho em Trang đi mua hoa quả...',
                  border: OutlineInputBorder(),
                ),
                onSaved: (val) => _content = val?.trim() ?? '',
              ),
              const SizedBox(height: 20),

              // Nút lưu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B2500),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.save),
                  label: Text(
                    widget.existingNote != null ? 'LƯU THAY ĐỔI' : 'THÊM VÀO LỊCH',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  onPressed: _saveNote,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryChip(String label, NoteCategory cat, IconData icon) {
    final isSelected = _category == cat;
    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey[700]),
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF8B2500),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (selected) {
        if (selected) setState(() => _category = cat);
      },
    );
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final hour = picked.hour.toString().padLeft(2, '0');
      final min = picked.minute.toString().padLeft(2, '0');
      setState(() => _time = '$hour:$min');
    }
  }

  void _saveNote() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      final lunar = VietnameseLunarEngine.solarToLunar(
        _selectedDate.day,
        _selectedDate.month,
        _selectedDate.year,
      );

      final note = DailyNoteItem(
        id: widget.existingNote?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _title,
        content: _content.isNotEmpty ? _content : null,
        date: DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day),
        lunarDay: lunar.day,
        lunarMonth: lunar.month,
        lunarYear: lunar.year,
        category: _category,
        isCompleted: widget.existingNote?.isCompleted ?? false,
        time: _time,
        createdAt: widget.existingNote?.createdAt ?? DateTime.now(),
      );

      Navigator.pop(context, note);
    }
  }
}
