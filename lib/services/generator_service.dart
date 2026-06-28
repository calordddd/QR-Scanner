import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class GeneratorService {
  /// Captures the widget wrapped in a RepaintBoundary as PNG bytes
  Future<Uint8List?> capturePng(GlobalKey qrKey) async {
    try {
      final boundary = qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      // Use higher pixel ratio for high quality PNG
      final image = await boundary.toImage(pixelRatio: 4.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      if (kDebugMode) {
        print('Error capturing QR code image: $e');
      }
      return null;
    }
  }

  /// Saves the QR code image to the app documents directory
  Future<String?> saveQrToDevice(GlobalKey qrKey, String filename) async {
    final bytes = await capturePng(qrKey);
    if (bytes == null) return null;

    try {
      // Find app documents directory or external storage directory
      Directory? directory;
      if (Platform.isAndroid) {
        // Try getting external storage directory for user access, fallback to standard docs
        directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final file = File('${directory.path}/$filename.png');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving QR code file: $e');
      }
      return null;
    }
  }

  /// Shares the QR code image
  Future<void> shareQrImage(GlobalKey qrKey, String filename, String text) async {
    final bytes = await capturePng(qrKey);
    if (bytes == null) return;

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename.png');
      await file.writeAsBytes(bytes);

      final xFile = XFile(file.path, mimeType: 'image/png');
      await Share.shareXFiles([xFile], text: 'Generated QR Code for: $text');
    } catch (e) {
      if (kDebugMode) {
        print('Error sharing QR code file: $e');
      }
    }
  }
}
