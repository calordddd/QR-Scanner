import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/generator_service.dart';

class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key});

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  final TextEditingController _textController = TextEditingController();
  final GeneratorService _generatorService = GeneratorService();
  final GlobalKey _qrKey = GlobalKey();

  String? _generatedContent;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    // Rebuild to update the state of the Generate button (enabled/disabled)
    setState(() {});
  }

  void _generateQR() {
    if (_textController.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _generatedContent = _textController.text.trim();
      _isGenerating = true;
    });
  }

  void _reset() {
    setState(() {
      _generatedContent = null;
      _textController.clear();
      _isGenerating = false;
    });
  }

  void _copyToClipboard() {
    if (_generatedContent == null) return;
    Clipboard.setData(ClipboardData(text: _generatedContent!));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Text copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _shareQR() async {
    if (_generatedContent == null) return;
    await _generatorService.shareQrImage(
      _qrKey,
      'qr_code_${DateTime.now().millisecondsSinceEpoch}',
      _generatedContent!,
    );
  }

  Future<void> _saveQR() async {
    if (_generatedContent == null) return;
    final filename = 'qr_code_${DateTime.now().millisecondsSinceEpoch}';
    final path = await _generatorService.saveQrToDevice(_qrKey, filename);

    if (!mounted) return;

    if (path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('QR Code saved successfully:\n$path'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to save QR Code to device.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isTextEmpty = _textController.text.trim().isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Generate QR',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Text Input Field
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: 'Enter Text or URL',
                hintText: 'https://example.com or any text',
                prefixIcon: const Icon(Icons.link),
                suffixIcon: _textController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _textController.clear(),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
              ),
              maxLines: null,
              keyboardType: TextInputType.multiline,
              enabled: !_isGenerating,
            ),
            const SizedBox(height: 20),

            // Action Button: Generate
            if (!_isGenerating)
              FilledButton.icon(
                onPressed: isTextEmpty ? null : _generateQR,
                icon: const Icon(Icons.qr_code_2),
                label: const Text('Generate QR Code'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

            // Generated QR Display
            if (_isGenerating && _generatedContent != null) ...[
              const SizedBox(height: 10),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: RepaintBoundary(
                    key: _qrKey,
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(8.0),
                      child: QrImageView(
                        data: _generatedContent!,
                        version: QrVersions.auto,
                        size: 200.0,
                        gapless: false,
                        errorStateBuilder: (cxt, err) {
                          return const Center(
                            child: Text(
                              'Failed to generate QR Code',
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _generatedContent!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Option Buttons Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.2,
                children: [
                  OutlinedButton.icon(
                    onPressed: _saveQR,
                    icon: const Icon(Icons.save_alt),
                    label: const Text('Save to device'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _shareQR,
                    icon: const Icon(Icons.share),
                    label: const Text('Share QR'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _copyToClipboard,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy text'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh),
                    label: const Text('New QR'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
