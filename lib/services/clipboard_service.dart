import 'dart:async';
import 'package:flutter/services.dart';
import '../core/constants.dart';
import '../core/utils/url_utils.dart';

/// Service that monitors the clipboard for new URLs.
///
/// Runs in the foreground while the app is active.
class ClipboardService {
  Timer? _timer;
  String _lastClipboardContent = '';
  final void Function(String url) onNewUrl;

  ClipboardService({required this.onNewUrl});

  /// Starts monitoring the clipboard at regular intervals.
  void startMonitoring() {
    _timer?.cancel();
    _timer = Timer.periodic(
      AppConstants.clipboardPollInterval,
      (_) => _checkClipboard(),
    );
  }

  /// Stops clipboard monitoring.
  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }

  /// Manually checks the clipboard once.
  Future<void> checkClipboardOnce() async {
    await _checkClipboard();
  }

  /// Internal method to check clipboard content.
  Future<void> _checkClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final content = data?.text?.trim() ?? '';

      if (content.isEmpty) return;
      if (content == _lastClipboardContent) return;

      _lastClipboardContent = content;

      // Extract the first valid clean URL
      final extractedUrl = UrlUtils.extractFirstValidUrl(content);
      if (extractedUrl != null) {
        onNewUrl(extractedUrl);
      }
    } catch (_) {
      // Clipboard access may fail silently
    }
  }

  /// Sets the last known clipboard content (e.g., after saving a link).
  void setLastContent(String content) {
    _lastClipboardContent = content;
  }

  /// Returns whether monitoring is active.
  bool get isMonitoring => _timer != null && _timer!.isActive;

  /// Disposes the service.
  void dispose() {
    stopMonitoring();
  }
}
