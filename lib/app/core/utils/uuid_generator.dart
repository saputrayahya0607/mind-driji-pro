import 'dart:math';

class UuidGenerator {
  UuidGenerator._();

  static final Random _random = Random.secure();

  /// Menghasilkan UUID v4 standar (RFC 4122)
  static String v4() {
    final values = List<int>.generate(16, (i) => _random.nextInt(256));
    values[6] = (values[6] & 0x0f) | 0x40; // Version 4
    values[8] = (values[8] & 0x3f) | 0x80; // Variant 10xx

    final buffer = StringBuffer();
    for (var i = 0; i < 16; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) {
        buffer.write('-');
      }
      buffer.write(values[i].toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}
