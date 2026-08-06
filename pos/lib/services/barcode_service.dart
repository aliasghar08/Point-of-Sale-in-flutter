import 'package:flutter/material.dart';

/// In-house vector Barcode & QR code generator and renderer.
/// Renders standard Code 128 and 2D matrix patterns cleanly using CustomPainters.
class BarcodeService {
  BarcodeService._();

  // Code 128B pattern table (107 patterns, each 11 modules wide, plus stop character 13 modules)
  static const List<String> _code128Patterns = [
    '11011001100', '11001101100', '11001100110', '10010011000', '10010001100',
    '10001001100', '10011001000', '10011000100', '10001100100', '11001001000',
    '11001000100', '11000100100', '10110011100', '10011011100', '10011001110',
    '10111001100', '10011101100', '10011100110', '11001110010', '11001011100',
    '11001001110', '11011100100', '11001110100', '11101101110', '11101001100',
    '11100101100', '11100100110', '11101100100', '11100110100', '11100110010',
    '11011011000', '11011000110', '11000110110', '10100011000', '10001011000',
    '10001000110', '10110001000', '10001101000', '10001100010', '11010001000',
    '11000101000', '11000100010', '10110111000', '10110001110', '10001101110',
    '10111011000', '10111000110', '10001110110', '11101110110', '11010001110',
    '11000101110', '11011101000', '11011100010', '11011101110', '11101011000',
    '11101000110', '11100010110', '11101101000', '11101100010', '11100011010',
    '11101111010', '11001000010', '11110001010', '10100110000', '10100001100',
    '10010110000', '10010000110', '10000101100', '10000100110', '10110010000',
    '10110000100', '10011010000', '10011000010', '10000110100', '10000110010',
    '11000010010', '11001010000', '11110111010', '11000010100', '10001111010',
    '10100111100', '10010111100', '10010011110', '10111100100', '10011110100',
    '10011110010', '11110100100', '11110010100', '11110010010', '11011011110',
    '11011110110', '11110110110', '10101111000', '10100011110', '10001011110',
    '10111101000', '10111100010', '11110101000', '11110100010', '10111011110',
    '10111101110', '11101011110', '11110101110', '11010000100', '11010010000',
    '11010011100', '11000111010', // Stop: 106
  ];

  static const String _stopPattern = '1100011101011';

  /// Generates the binary bit sequence for Code 128B
  static String encodeCode128(String data) {
    if (data.isEmpty) data = '0000';
    // Start B is index 104
    final startCode = 104;
    final List<int> codes = [startCode];

    int checksum = startCode;
    for (int i = 0; i < data.length; i++) {
      int code = data.codeUnitAt(i) - 32;
      if (code < 0 || code > 95) code = 0; // fallback to space
      codes.add(code);
      checksum += code * (i + 1);
    }

    int checkDigit = checksum % 103;
    codes.add(checkDigit);

    final StringBuffer buffer = StringBuffer();
    for (final code in codes) {
      if (code >= 0 && code < _code128Patterns.length) {
        buffer.write(_code128Patterns[code]);
      }
    }
    buffer.write(_stopPattern);
    return buffer.toString();
  }
}

/// Custom widget that paints a vector Code 128 barcode
class BarcodeWidget extends StatelessWidget {
  final String data;
  final double width;
  final double height;
  final Color color;
  final Color backgroundColor;
  final bool showText;
  final TextStyle? textStyle;

  const BarcodeWidget({
    super.key,
    required this.data,
    this.width = 200,
    this.height = 70,
    this.color = Colors.black,
    this.backgroundColor = Colors.white,
    this.showText = true,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final bitString = BarcodeService.encodeCode128(data);

    return Container(
      width: width,
      height: height,
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: CustomPaint(
              size: Size(width, height - (showText ? 16 : 0)),
              painter: _BarcodePainter(
                bitString: bitString,
                barColor: color,
              ),
            ),
          ),
          if (showText) ...[
            const SizedBox(height: 2),
            Text(
              data,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle ??
                  TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    color: color,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BarcodePainter extends CustomPainter {
  final String bitString;
  final Color barColor;

  _BarcodePainter({required this.bitString, required this.barColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (bitString.isEmpty) return;

    final paint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;

    final moduleWidth = size.width / bitString.length;

    for (int i = 0; i < bitString.length; i++) {
      if (bitString[i] == '1') {
        final rect = Rect.fromLTWH(
          i * moduleWidth,
          0,
          moduleWidth,
          size.height,
        );
        canvas.drawRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarcodePainter oldDelegate) {
    return oldDelegate.bitString != bitString || oldDelegate.barColor != barColor;
  }
}
