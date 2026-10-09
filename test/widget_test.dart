import 'package:flutter_test/flutter_test.dart';
import 'package:so_gio_app/lunar_engine.dart';

void main() {
  test('Test Lunar Engine conversion for Tet Nguyen Dan', () {
    // 01/01/2026 Âm lịch -> Dương lịch
    final solar = VietnameseLunarEngine.lunarToSolar(1, 1, 2026);
    expect(solar, isNotNull);
    expect(solar![0], 17);
    expect(solar[1], 2);
    expect(solar[2], 2026);
  });
}
