import '../database/database_helper.dart';
import '../models/history_item.dart';

class HistoryService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Insert a new scan into history
  Future<bool> addScan(String content) async {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;

    // Check if the most recent scan is the same and was made within the last 5 seconds
    final lastScan = await _dbHelper.getMostRecentScan();
    if (lastScan != null &&
        lastScan.qrContent == content &&
        (timestamp - lastScan.timestamp) < 5000) {
      // Ignore duplicate scans within 5 seconds
      return false;
    }

    final isUrl = _isValidUrl(content);
    final dateStr = _formatDate(now);
    final timeStr = _formatTime(now);

    final item = HistoryItem(
      qrContent: content,
      date: dateStr,
      time: timeStr,
      scanType: isUrl ? 'url' : 'text',
      url: isUrl ? content : '',
      text: isUrl ? '' : content,
      isFavorite: false,
      timestamp: timestamp,
    );

    await _dbHelper.insertScan(item);
    return true;
  }

  // Get all history items
  Future<List<HistoryItem>> getHistory() async {
    return await _dbHelper.getAllScans();
  }

  // Search scans by content
  Future<List<HistoryItem>> searchHistory(String query) async {
    if (query.isEmpty) {
      return await getHistory();
    }
    return await _dbHelper.searchScans(query);
  }

  // Toggle favorite status
  Future<void> toggleFavorite(HistoryItem item) async {
    final updatedItem = item.copyWith(isFavorite: !item.isFavorite);
    await _dbHelper.updateScan(updatedItem);
  }

  // Delete single scan
  Future<void> deleteItem(int id) async {
    await _dbHelper.deleteScan(id);
  }

  // Clear all scans
  Future<void> clearAll() async {
    await _dbHelper.deleteAllScans();
  }

  bool _isValidUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) return false;
    return uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final scanDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (scanDay == today) {
      return 'Today';
    } else if (scanDay == yesterday) {
      return 'Yesterday';
    } else {
      // Format as YYYY-MM-DD
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
