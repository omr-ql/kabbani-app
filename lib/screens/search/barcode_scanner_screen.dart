import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../l10n/app_localizations.dart';
import '../products/product_details_screen.dart';
import 'search_by_id_screen.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final VoidCallback? onProductScanned;
  const BarcodeScannerScreen({
    super.key,
    this.onProductScanned,
  });

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isScanning = true;
  bool _hasPermission = false;
  String _lastScannedCode = '';

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _hasPermission = status == PermissionStatus.granted;
    });
  }

  void _handleBarcode(String code) {
    if (code.isNotEmpty && code != _lastScannedCode && _isScanning) {
      setState(() {
        _isScanning = false;
        _lastScannedCode = code;
      });

      HapticFeedback.mediumImpact();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailsScreen(productId: code),
        ),
      ).then((_) {
        setState(() {
          _isScanning = true;
          _lastScannedCode = '';
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!_hasPermission) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(l10n.scan, style: const TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFFFF4B4B),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt, size: 80, color: Colors.grey),
              const SizedBox(height: 20),
              Text(l10n.cameraPermissionRequired, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _checkPermission,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4B4B)),
                child: Text(l10n.grantPermission, style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(l10n.scanProductCode, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFFF4B4B),
        elevation: 0,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleBarcode(barcode.rawValue!);
                }
              }
            },
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
            ),
            child: Stack(
              children: [
                // Red scanning box
                Center(
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFFF4B4B), width: 3), // Red border
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                // Updated: White instruction box with localized barcode instructions
                Positioned(
                  bottom: 80,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isScanning ? Icons.qr_code_scanner : Icons.check_circle,
                          color: _isScanning ? const Color(0xFFFF4B4B) : Colors.green,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _isScanning
                                ? l10n.placeBarcodeInBox
                                : l10n.codeScannedSuccessfully,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Manual entry button
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const SearchByIdScreen()),
                      );
                    },
                    icon: const Icon(Icons.keyboard, color: Colors.white),
                    label: Text(
                      l10n.enterCodeManually,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                // Torch toggle
                Positioned(
                  top: 20,
                  right: 20,
                  child: IconButton(
                    onPressed: () => cameraController.toggleTorch(),
                    icon: ValueListenableBuilder(
                      valueListenable: cameraController.torchState,
                      builder: (context, state, child) {
                        switch (state) {
                          case TorchState.off:
                            return const Icon(Icons.flash_off, color: Colors.white);
                          case TorchState.on:
                            return const Icon(Icons.flash_on, color: Colors.yellow);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}
