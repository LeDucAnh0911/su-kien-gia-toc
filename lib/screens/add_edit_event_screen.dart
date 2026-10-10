/// Màn hình Thêm / Sửa Ngày Giỗ & Sự Kiện
import 'package:flutter/material.dart';
import '../models/event_model.dart';

class AddEditEventScreen extends StatefulWidget {
  final EventItem? event;

  const AddEditEventScreen({super.key, this.event});

  @override
  State<AddEditEventScreen> createState() => _AddEditEventScreenState();
}

class _AddEditEventScreenState extends State<AddEditEventScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _title;
  late EventType _type;
  late CalendarType _calendar;
  late int _day;
  late int _month;
  int? _year;
  late String _personName;
  late String _relation;
  late String _restingPlace;
  int? _ageAtDeath;
  late bool _remindTienThuong;
  late bool _remindChinhKy;
  late int _advanceDays;
  late String _notes;

  @override
  void initState() {
    super.initState();
    final ev = widget.event;
    if (ev != null) {
      _title = ev.title;
      _type = ev.type;
      _calendar = ev.calendar;
      _day = ev.day;
      _month = ev.month;
      _year = ev.year;
      _personName = ev.personName ?? '';
      _relation = ev.relation ?? '';
      _restingPlace = ev.restingPlace ?? '';
      _ageAtDeath = ev.ageAtDeath;
      _remindTienThuong = ev.remindTienThuong;
      _remindChinhKy = ev.remindChinhKy;
      _advanceDays = ev.advanceDays;
      _notes = ev.notes ?? '';
    } else {
      _title = '';
      _type = EventType.deathAnniversary;
      _calendar = CalendarType.lunar;
      _day = 15;
      _month = 8;
      _year = null;
      _personName = '';
      _relation = '';
      _restingPlace = '';
      _ageAtDeath = null;
      _remindTienThuong = true;
      _remindChinhKy = true;
      _advanceDays = 3;
      _notes = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.event != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Sửa Ngày Giỗ / Sự Kiện' : 'Thêm Ngày Giỗ Mới'),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFF8B2500),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Lưu',
            onPressed: _saveEvent,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // LOẠI LỊCH (ÂM LỊCH / DƯƠNG LỊCH)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Lịch sử dụng:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    SegmentedButton<CalendarType>(
                      segments: const [
                        ButtonSegment(
                          value: CalendarType.lunar,
                          label: Text('Âm Lịch (Ngày Giỗ)'),
                          icon: Icon(Icons.nightlight_round),
                        ),
                        ButtonSegment(
                          value: CalendarType.solar,
                          label: Text('Dương Lịch'),
                          icon: Icon(Icons.wb_sunny_rounded),
                        ),
                      ],
                      selected: {_calendar},
                      onSelectionChanged: (set) => setState(() => _calendar = set.first),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // TIÊU ĐỀ & LOẠI SỰ KIỆN
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      initialValue: _title,
                      decoration: const InputDecoration(
                        labelText: 'Tiêu đề sự kiện *',
                        hintText: 'VD: Giỗ Cụ Ông, Giỗ Bác Cả, Sinh nhật Mẹ',
                        prefixIcon: Icon(Icons.bookmark_border),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Vui lòng nhập tiêu đề' : null,
                      onSaved: (val) => _title = val!.trim(),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<EventType>(
                      value: _type,
                      decoration: const InputDecoration(
                        labelText: 'Loại sự kiện',
                        prefixIcon: Icon(Icons.category_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: EventType.deathAnniversary, child: Text('Ngày Giỗ (Kỵ nhật)')),
                        DropdownMenuItem(value: EventType.birthday, child: Text('Sinh nhật')),
                        DropdownMenuItem(value: EventType.memorial, child: Text('Ngày kỷ niệm')),
                        DropdownMenuItem(value: EventType.custom, child: Text('Khác')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _type = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // NGÀY THÁNG NĂM
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _calendar == CalendarType.lunar ? 'Chọn Ngày Âm Lịch:' : 'Chọn Ngày Dương Lịch:',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Chọn ngày
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _day,
                            decoration: const InputDecoration(
                              labelText: 'Ngày',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            items: List.generate(31, (i) => i + 1).map((d) {
                              return DropdownMenuItem(value: d, child: Text('$d'));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _day = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Chọn tháng
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _month,
                            decoration: const InputDecoration(
                              labelText: 'Tháng',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            items: List.generate(12, (i) => i + 1).map((m) {
                              return DropdownMenuItem(value: m, child: Text('Tháng $m'));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _month = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Năm mất (tùy chọn)
                        Expanded(
                          child: TextFormField(
                            initialValue: _year?.toString() ?? '',
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Năm (tuỳ chọn)',
                              hintText: 'VD: 2015',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            onSaved: (val) {
                              if (val != null && val.trim().isNotEmpty) {
                                _year = int.tryParse(val.trim());
                              } else {
                                _year = null;
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // THÔNG TIN NGƯỜI MẤT / TƯỞNG NHỚ
            if (_type == EventType.deathAnniversary)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Thông Tin Gia Tiên / Người Mất:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: _personName,
                        decoration: const InputDecoration(
                          labelText: 'Họ và tên người mất',
                          hintText: 'VD: Ông Nội',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        onSaved: (val) => _personName = val?.trim() ?? '',
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: _relation,
                              decoration: const InputDecoration(
                                labelText: 'Vai vế / Quan hệ',
                                hintText: 'VD: Cụ Ông, Bác Cả...',
                                prefixIcon: Icon(Icons.family_restroom_outlined),
                                border: OutlineInputBorder(),
                              ),
                              onSaved: (val) => _relation = val?.trim() ?? '',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              initialValue: _ageAtDeath?.toString() ?? '',
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Hưởng thọ (tuổi)',
                                hintText: 'VD: 85',
                                prefixIcon: Icon(Icons.cake_outlined),
                                border: OutlineInputBorder(),
                              ),
                              onSaved: (val) {
                                if (val != null && val.trim().isNotEmpty) {
                                  _ageAtDeath = int.tryParse(val.trim());
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: _restingPlace,
                        decoration: const InputDecoration(
                          labelText: 'Nơi an nghỉ / Vị trí mộ phần',
                          hintText: 'VD: Nghĩa trang quê nhà, khu lăng mộ họ Lê...',
                          prefixIcon: Icon(Icons.place_outlined),
                          border: OutlineInputBorder(),
                        ),
                        onSaved: (val) => _restingPlace = val?.trim() ?? '',
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),

            // CẤU HÌNH NHẮC NHỞ
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cấu hình Thông Báo & Nhắc Nhở:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Nhắc Lễ Tiên Thường (Chiều hôm trước)'),
                      subtitle: const Text('Báo vào 16:00 chiều hôm trước ngày giỗ chính'),
                      value: _remindTienThuong,
                      onChanged: (val) => setState(() => _remindTienThuong = val),
                    ),
                    SwitchListTile(
                      title: const Text('Nhắc Lễ Chính Kỵ (Sáng đúng ngày)'),
                      subtitle: const Text('Báo vào 06:30 sáng ngày giỗ'),
                      value: _remindChinhKy,
                      onChanged: (val) => setState(() => _remindChinhKy = val),
                    ),
                    ListTile(
                      title: const Text('Nhắc trước để chuẩn bị:'),
                      trailing: DropdownButton<int>(
                        value: _advanceDays,
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Trước 1 ngày')),
                          DropdownMenuItem(value: 3, child: Text('Trước 3 ngày')),
                          DropdownMenuItem(value: 5, child: Text('Trước 5 ngày')),
                          DropdownMenuItem(value: 7, child: Text('Trước 7 ngày')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _advanceDays = val);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // GHI CHÚ
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  initialValue: _notes,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú kiêng kỵ & tục lệ dòng họ',
                    hintText: 'VD: Người mất kiêng cúng món gì, sở thích sinh thời...',
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (val) => _notes = val?.trim() ?? '',
                ),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF8B2500) : const Color(0xFF8B2500),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _saveEvent,
              child: Text(
                isEditing ? 'LƯU THAY ĐỔI' : 'TẠO NGÀY GIỖ MỚI',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _saveEvent() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      final now = DateTime.now();
      final newEvent = EventItem(
        id: widget.event?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _title,
        type: _type,
        calendar: _calendar,
        day: _day,
        month: _month,
        year: _year,
        personName: _personName.isNotEmpty ? _personName : null,
        relation: _relation.isNotEmpty ? _relation : null,
        restingPlace: _restingPlace.isNotEmpty ? _restingPlace : null,
        ageAtDeath: _ageAtDeath,
        remindTienThuong: _remindTienThuong,
        remindChinhKy: _remindChinhKy,
        advanceDays: _advanceDays,
        notes: _notes.isNotEmpty ? _notes : null,
        dishes: widget.event?.dishes ?? [],
        contributions: widget.event?.contributions ?? [],
        createdAt: widget.event?.createdAt ?? now,
        updatedAt: now,
      );

      Navigator.pop(context, newEvent);
    }
  }
}
