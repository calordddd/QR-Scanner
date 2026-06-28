import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'settings_screen.dart';
import '../services/scanner_service.dart';
import '../widgets/scanner_overlay.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  final ScannerService _scannerService = ScannerService();
  MobileScannerController? _controller;

  bool _isProcessing = false;
  String? _lastScannedValue;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initController();
  }

  void _initController() {
    _controller = MobileScannerController(
      autoStart: true,
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: [BarcodeFormat.qrCode],
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        if (controller.value.hasCameraPermission && !_isProcessing) {
          controller.start();
        }
        break;
      case AppLifecycleState.paused:
        controller.stop();
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final value = barcode.rawValue!;
    if (value == _lastScannedValue) return;

    setState(() {
      _isProcessing = true;
      _lastScannedValue = value;
    });

    _controller?.stop();

    final result = await _scannerService.processScannedValue(value);

    if (_isDisposed || !mounted) return;

    switch (result) {
      case ScannerResult.launched:
        _showSnackBar('Opening URL…', isError: false);
        await Future.delayed(const Duration(seconds: 2));
        break;
      case ScannerResult.textSaved:
        _showSnackBar('Text saved to history', isError: false);
        await Future.delayed(const Duration(seconds: 1));
        break;
      case ScannerResult.invalidUrl:
        _showSnackBar('Invalid QR Code');
        break;
      case ScannerResult.launchFailed:
        _showSnackBar('Could not open URL');
        break;
    }

    if (_isDisposed || !mounted) return;

    setState(() {
      _isProcessing = false;
      _lastScannedValue = null;
    });

    _controller?.start();
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Theme.of(context).colorScheme.error : null,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _restartCamera() {
    _controller?.dispose();
    _initController();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final controller = _controller;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'QR Scanner',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: false,
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: controller == null
                    ? Container(color: colorScheme.surface)
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          MobileScanner(
                            key: ValueKey(controller),
                            controller: controller,
                            onDetect: _onBarcodeDetected,
                            errorBuilder: (context, error) {
                              return _CameraErrorView(
                                error: error,
                                onRetry: _restartCamera,
                              );
                            },
                            placeholderBuilder: (context) {
                              return Container(
                                color: colorScheme.surface,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                          ),
                          const ScannerOverlay(),
                          if (_isProcessing)
                            Container(
                              color: Colors.black54,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 48, top: 16),
            child: Text(
              'Point your camera at a QR code',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraErrorView extends StatelessWidget {
  final MobileScannerException error;
  final VoidCallback onRetry;

  const _CameraErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    String message;
    IconData icon;

    switch (error.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        icon = Icons.no_photography_outlined;
        message =
            'Camera permission is required.\nPlease grant camera access in your device settings.';
        break;
      default:
        icon = Icons.error_outline;
        message =
            'Camera is unavailable.\n${error.errorDetails?.message ?? "Please try again."}';
        break;
    }

    return Container(
      color: colorScheme.surface,
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: colorScheme.error),
          const SizedBox(height: 24),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
