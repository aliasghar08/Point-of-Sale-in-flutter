import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/permission_service.dart';

enum ScannerExpectedType { barcode, qrCode, any }

class BarcodeScanner extends StatefulWidget {
  final Function(String) onScan;
  final String title;
  final String hintText;
  final List<BarcodeFormat>? formats;
  final ScannerExpectedType expectedType;

  const BarcodeScanner({
    super.key,
    required this.onScan,
    this.title = 'Scan Barcode / QR Code',
    this.hintText = 'Align barcode or QR code inside the frame to scan',
    this.formats,
    this.expectedType = ScannerExpectedType.barcode,
  });

  @override
  State<BarcodeScanner> createState() => _BarcodeScannerState();
}

class _BarcodeScannerState extends State<BarcodeScanner>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final MobileScannerController _controller;
  late final AnimationController _laserAnimationController;

  bool _isProcessing = false;
  bool _isTorchOn = false;
  bool _hasPermission = false;
  bool _scanSuccessFlash = false;
  bool _scanErrorFlash = false;
  String? _errorMessage;

  Color get _activeBorderColor {
    if (_scanErrorFlash) return Colors.redAccent;
    if (_scanSuccessFlash) return Colors.greenAccent;
    return Colors.cyanAccent;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      returnImage: false,
      autoStart: true,
      formats:
          widget.formats ??
          const [
            BarcodeFormat.qrCode,
            BarcodeFormat.code128,
            BarcodeFormat.code39,
            BarcodeFormat.code93,
            BarcodeFormat.ean13,
            BarcodeFormat.ean8,
            BarcodeFormat.upcA,
            BarcodeFormat.upcE,
            BarcodeFormat.codabar,
            BarcodeFormat.itf14,
            BarcodeFormat.dataMatrix,
            BarcodeFormat.aztec,
            BarcodeFormat.pdf417,
          ],
    );

    _laserAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _checkPermission();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      _controller.start();
    }
  }

  Future<void> _checkPermission() async {
    bool hasPermission = await PermissionService.requestCameraPermission();
    if (mounted) {
      setState(() {
        _hasPermission = hasPermission;
      });
    }

    if (!hasPermission && mounted) {
      PermissionService.showPermissionDialog(
        context,
        'Camera Permission Required',
        'This app needs camera access to scan barcodes. Please grant permission in settings.',
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _laserAnimationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleBarcodeDetect(BarcodeCapture capture) {
    if (_isProcessing || capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    final String? rawValue = barcode.rawValue;

    if (rawValue != null && rawValue.isNotEmpty) {
      final isQr =
          barcode.format == BarcodeFormat.qrCode ||
          barcode.format == BarcodeFormat.dataMatrix ||
          barcode.format == BarcodeFormat.aztec;

      // Validate scanned format against expectedType
      if (widget.expectedType == ScannerExpectedType.barcode && isQr) {
        _triggerScanError('❌ Scanned a QR code. Please scan a Barcode.');
        return;
      }

      if (widget.expectedType == ScannerExpectedType.qrCode && !isQr) {
        _triggerScanError('❌ Scanned a Barcode. Please scan a QR code.');
        return;
      }

      _isProcessing = true;
      HapticFeedback.mediumImpact();

      setState(() {
        _scanSuccessFlash = true;
        _errorMessage = null;
      });

      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) {
          widget.onScan(rawValue);
          Navigator.pop(context);
        }
      });
    }
  }

  void _triggerScanError(String message) {
    _isProcessing = true;
    HapticFeedback.heavyImpact();

    setState(() {
      _scanErrorFlash = true;
      _errorMessage = message;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _scanErrorFlash = false;
          _errorMessage = null;
          _isProcessing = false;
        });
      }
    });
  }

  void _showManualInputDialog() {
    final TextEditingController codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit_note, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              'Enter Code Manually',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the barcode or QR code number manually:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              autofocus: true,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                hintText: 'e.g. 8901234567890',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.barcode_reader),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              final text = codeController.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(dialogContext);
                HapticFeedback.lightImpact();
                widget.onScan(text);
                Navigator.pop(context);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _hasPermission
          ? Stack(
              children: [
                // Camera View
                MobileScanner(
                  controller: _controller,
                  onDetect: _handleBarcodeDetect,
                ),

                // Dark Semi-transparent Overlay with Viewfinder Cutout
                CustomPaint(
                  size: Size.infinite,
                  painter: _ScannerOverlayPainter(
                    borderColor: _activeBorderColor,
                  ),
                ),

                // Viewfinder Target Box with Corner Brackets & Laser
                Center(
                  child: SizedBox(
                    width: 270,
                    height: 270,
                    child: Stack(
                      children: [
                        // Animated Scanning Laser Line
                        AnimatedBuilder(
                          animation: _laserAnimationController,
                          builder: (context, child) {
                            return Positioned(
                              top: _laserAnimationController.value * 250,
                              left: 8,
                              right: 8,
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      _activeBorderColor,
                                      Colors.greenAccent,
                                      _activeBorderColor,
                                      Colors.transparent,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _activeBorderColor.withValues(
                                        alpha: 0.8,
                                      ),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        // Sleek Corner Brackets
                        _buildCornerBracket(Alignment.topLeft),
                        _buildCornerBracket(Alignment.topRight),
                        _buildCornerBracket(Alignment.bottomLeft),
                        _buildCornerBracket(Alignment.bottomRight),
                      ],
                    ),
                  ),
                ),

                // Header Bar (Back button, Title badge)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back Button
                        Material(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),

                        // Title Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24, width: 1),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.qr_code_scanner,
                                color: Colors.cyanAccent,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 48), // Balance spacing
                      ],
                    ),
                  ),
                ),

                // Instruction Banner / Error Overlay
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.18,
                  left: 20,
                  right: 20,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _errorMessage != null
                          ? Container(
                              key: const ValueKey('error_banner'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade900.withValues(
                                  alpha: 0.92,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.redAccent,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.redAccent.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      _errorMessage!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(
                              key: const ValueKey('hint_banner'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.hintText,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),

                // Bottom Floating Control Bar (Torch, Switch Camera, Manual Input)
                Positioned(
                  bottom: 40,
                  left: 24,
                  right: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white12, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Flash Toggle
                        _buildControlButton(
                          icon: _isTorchOn ? Icons.flash_on : Icons.flash_off,
                          label: 'Flash',
                          isActive: _isTorchOn,
                          onTap: () {
                            setState(() {
                              _isTorchOn = !_isTorchOn;
                            });
                            _controller.toggleTorch();
                          },
                        ),

                        // Camera Switch
                        _buildControlButton(
                          icon: Icons.cameraswitch,
                          label: 'Flip',
                          onTap: () => _controller.switchCamera(),
                        ),

                        // Manual Entry
                        _buildControlButton(
                          icon: Icons.keyboard,
                          label: 'Manual',
                          onTap: _showManualInputDialog,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : _buildPermissionDeniedState(),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.amberAccent : Colors.white,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.amberAccent : Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerBracket(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border(
            top: (alignment.y == -1)
                ? BorderSide(color: _activeBorderColor, width: 4)
                : BorderSide.none,
            bottom: (alignment.y == 1)
                ? BorderSide(color: _activeBorderColor, width: 4)
                : BorderSide.none,
            left: (alignment.x == -1)
                ? BorderSide(color: _activeBorderColor, width: 4)
                : BorderSide.none,
            right: (alignment.x == 1)
                ? BorderSide(color: _activeBorderColor, width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_enhance_outlined,
              size: 72,
              color: Colors.white38,
            ),
            const SizedBox(height: 16),
            const Text(
              'Camera Permission Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Camera access is needed to scan product barcodes and QR codes.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _checkPermission,
              icon: const Icon(Icons.settings),
              label: const Text('Grant Camera Permission'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for semi-transparent dark backdrop with camera cutout viewport
class _ScannerOverlayPainter extends CustomPainter {
  final Color borderColor;

  _ScannerOverlayPainter({required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final double boxSize = 270.0;
    final double left = (size.width - boxSize) / 2;
    final double top = (size.height - boxSize) / 2;
    final Rect cutoutRect = Rect.fromLTWH(left, top, boxSize, boxSize);

    final Paint backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.65);

    final Path backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(cutoutRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(backgroundPath, backgroundPaint);

    // Inner border for cutout
    final Paint borderPaint = Paint()
      ..color = borderColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(
      RRect.fromRectAndRadius(cutoutRect, const Radius.circular(16)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.borderColor != borderColor;
  }
}
