import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:permission_handler/permission_handler.dart';

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

  /// Saves the QR code image to the public Downloads folder (Android) or documents directory (iOS)
  Future<String?> saveQrToDevice(GlobalKey qrKey, String filename) async {
    final bytes = await capturePng(qrKey);
    if (bytes == null) return null;

    try {
      Directory? directory;
      if (Platform.isAndroid) {
        // Request storage permission
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          // If denied, we can still try to write or fallback to app documents
          if (kDebugMode) {
            print('Storage permission not granted. Attempting download path anyway.');
          }
        }
        
        // Standard Android public Download directory
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = Directory('/sdcard/Download');
        }
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) return null;

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
