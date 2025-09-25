import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../l10n/app_localizations.dart';
import '../products/product_details_screen.dart';
import 'search_by_id_screen.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final VoidCallback? onProductScanned;
  final VoidCallback? onBackToHome;

  const BarcodeScannerScreen({
    super.key,
    this.onProductScanned,
    this.onBackToHome,
  });

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  late MobileScannerController cameraController;
  bool _isScanning = true;
  bool _hasPermission = false;
  String _lastScannedCode = '';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    try {
      final status = await Permission.camera.request();
      setState(() {
        _hasPermission = status == PermissionStatus.granted;
      });

      if (!_hasPermission) {
        _errorMessage = 'Camera permission required';
      }
    } catch (e) {
      setState(() {
        _hasPermission = false;
        _errorMessage = 'Error checking permission: ${e.toString()}';
      });
    }
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

  void _navigateToManualEntry() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchByIdScreen(
          onBackToHome: widget.onBackToHome,
        ),
      ),
    ).then((_) {
      setState(() {
        _isScanning = true;
        _lastScannedCode = '';
      });
    });
  }

  void _handleBackNavigation() {
    if (widget.onBackToHome != null) {
      widget.onBackToHome!();
    } else {
      Navigator.pop(context);
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: _handleBackNavigation,
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt, size: 80, color: Colors.grey),
              const SizedBox(height: 20),
              Text(
                _errorMessage.isNotEmpty
                    ? _errorMessage
                    : l10n.cameraPermissionRequired,
                style: const TextStyle(color: Colors.white),
              ),
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

    return WillPopScope(
      onWillPop: () async {
        _handleBackNavigation();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(l10n.scanProductCode, style: const TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFFFF4B4B),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: _handleBackNavigation,
          ),
        ),
        body: Stack(
          children: [
            // Camera view with proper error handling
            _buildCameraView(),

            // Overlay elements
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFFF4B4B), width: 3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
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
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: TextButton.icon(
                      onPressed: _navigateToManualEntry,
                      icon: const Icon(Icons.keyboard, color: Colors.white),
                      label: Text(
                        l10n.enterCodeManually,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
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
      ),
    );
  }

  Widget _buildCameraView() {
    try {
      return MobileScanner(
        controller: cameraController,
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              _handleBarcode(barcode.rawValue!);
            }
          }
        },
      );
    } catch (e) {
      print("Error initializing camera: $e");
      return Center(
        child: Text(
          "Camera initialization failed: ${e.toString()}",
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}