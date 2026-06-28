import 'package:url_launcher/url_launcher.dart';
import 'history_service.dart';

enum ScannerResult {
  launched,
  invalidUrl,
  launchFailed,
  textSaved,
}

class ScannerService {
  final HistoryService _historyService = HistoryService();

  /// Checks if value is valid HTTP/HTTPS URL
  bool isValidUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) return false;
    return uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  /// Processes scanned code:
  /// - Saves it in the history database (enforcing duplicate check).
  /// - Launches if it is a valid URL, otherwise returns text status.
  Future<ScannerResult> processScannedValue(String value) async {
    // Add to history
    await _historyService.addScan(value);

    if (isValidUrl(value)) {
      final uri = Uri.parse(value);
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        return launched ? ScannerResult.launched : ScannerResult.launchFailed;
      } catch (_) {
        return ScannerResult.launchFailed;
      }
    } else {
      return ScannerResult.textSaved;
    }
  }
}
