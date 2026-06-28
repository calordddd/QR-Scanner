import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/history_item.dart';
import '../services/history_service.dart';
import '../services/scanner_service.dart';

import '../main.dart'; // Import to access activeTabNotifier

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _historyService = HistoryService();
  final ScannerService _scannerService = ScannerService();
  final TextEditingController _searchController = TextEditingController();

  List<HistoryItem> _allHistory = [];
  List<HistoryItem> _filteredHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _searchController.addListener(_onSearchChanged);
    activeTabNotifier.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    activeTabNotifier.removeListener(_onTabChanged);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (activeTabNotifier.value == 2) {
      _loadHistory();
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final history = await _historyService.getHistory();
    setState(() {
      _allHistory = history;
      _filteredHistory = history;
      _isLoading = false;
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredHistory = _allHistory.where((item) {
        final content = item.qrContent.toLowerCase();
        final url = item.url.toLowerCase();
        final text = item.text.toLowerCase();
        return content.contains(query) || url.contains(query) || text.contains(query);
      }).toList();
    });
  }

  String _getFriendlyTitle(HistoryItem item) {
    if (item.scanType == 'url') {
      try {
        final uri = Uri.parse(item.url);
        final host = uri.host;
        if (host.isNotEmpty) {
          final parts = host.split('.');
          if (parts.length >= 2) {
            final siteName = parts[0].toLowerCase() == 'www' ? parts[1] : parts[0];
            if (siteName.isNotEmpty) {
              return siteName[0].toUpperCase() + siteName.substring(1);
            }
          }
          return host;
        }
      } catch (_) {}
      return 'Link';
    } else {
      return item.text.length > 40 ? '${item.text.substring(0, 40)}...' : item.text;
    }
  }

  Future<void> _toggleFavorite(HistoryItem item) async {
    await _historyService.toggleFavorite(item);
    await _loadHistory();
  }

  Future<void> _deleteItem(int id) async {
    await _historyService.deleteItem(id);
    await _loadHistory();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Item deleted'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _clearAllHistory() async {
    if (_allHistory.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Scan History?'),
        content: const Text('This will permanently delete all scanned records.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _historyService.clearAll();
      await _loadHistory();
    }
  }

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _shareContent(String text) {
    Share.share(text);
  }

  Future<void> _openUrlAgain(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not open URL'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _showItemOptions(HistoryItem item) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _getFriendlyTitle(item),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  item.qrContent,
                  style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 14),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    if (item.scanType == 'url')
                      _buildBottomAction(
                        icon: Icons.open_in_browser,
                        label: 'Open URL',
                        onTap: () {
                          Navigator.of(context).pop();
                          _openUrlAgain(item.url);
                        },
                      ),
                    _buildBottomAction(
                      icon: Icons.copy,
                      label: 'Copy',
                      onTap: () {
                        Navigator.of(context).pop();
                        _copyText(item.qrContent);
                      },
                    ),
                    _buildBottomAction(
                      icon: Icons.share,
                      label: 'Share',
                      onTap: () {
                        Navigator.of(context).pop();
                        _shareContent(item.qrContent);
                      },
                    ),
                    _buildBottomAction(
                      icon: item.isFavorite ? Icons.star : Icons.star_border,
                      label: item.isFavorite ? 'Unfavorite' : 'Favorite',
                      iconColor: item.isFavorite ? Colors.amber : null,
                      onTap: () {
                        Navigator.of(context).pop();
                        _toggleFavorite(item);
                      },
                    ),
                    _buildBottomAction(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      iconColor: colorScheme.error,
                      onTap: () {
                        Navigator.of(context).pop();
                        if (item.id != null) {
                          _deleteItem(item.id!);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: iconColor ?? theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'History',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          if (_allHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Delete all',
              onPressed: _clearAllHistory,
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search scans...',
              leading: const Icon(Icons.search),
              elevation: MaterialStateProperty.all(0),
              backgroundColor: MaterialStateProperty.all(
                colorScheme.surfaceVariant.withOpacity(0.3),
              ),
              shape: MaterialStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredHistory.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchController.text.isNotEmpty
                                  ? Icons.search_off
                                  : Icons.history,
                              size: 72,
                              color: colorScheme.onSurface.withOpacity(0.2),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'No matching scans found'
                                  : 'No scan history yet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _filteredHistory.length,
                        itemBuilder: (context, index) {
                          final item = _filteredHistory[index];
                          final isUrl = item.scanType == 'url';
                          final title = _getFriendlyTitle(item);
                          final subtitle = isUrl ? item.url : 'Text';

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: colorScheme.outlineVariant.withOpacity(0.5),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: isUrl
                                    ? colorScheme.primaryContainer
                                    : colorScheme.secondaryContainer,
                                child: Icon(
                                  isUrl ? Icons.link : Icons.text_fields,
                                  color: isUrl
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onSecondaryContainer,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (item.isFavorite)
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 20,
                                    ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      subtitle,
                                      style: TextStyle(
                                        color: colorScheme.onSurface.withOpacity(0.6),
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          item.date,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: colorScheme.onSurface.withOpacity(0.4),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          item.time,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: colorScheme.onSurface.withOpacity(0.4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              onTap: () => _showItemOptions(item),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
