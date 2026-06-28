import 'package:url_launcher/url_launcher.dart';

/// Result of processing a scanned QR code value.
enum QrResult {
  launched,
  invalidUrl,
  launchFailed,
}

/// Handles QR code value validation and URL launching.
class QrService {
  const QrService();

  /// Returns true if [value] is a valid HTTP or HTTPS URL.
  bool isValidUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) return false;
    return uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  /// Validates the scanned [value] and attempts to launch it
  /// in the default external browser.
  Future<QrResult> processScannedValue(String value) async {
    if (!isValidUrl(value)) {
      return QrResult.invalidUrl;
    }

    final uri = Uri.parse(value);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      return launched ? QrResult.launched : QrResult.launchFailed;
    } catch (_) {
      return QrResult.launchFailed;
    }
  }
}
