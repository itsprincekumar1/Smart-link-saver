import 'dart:async';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../core/utils/url_utils.dart';

/// Service that wraps [ReceiveSharingIntent] to provide
/// a clean stream of valid URLs shared from other apps.
class ShareIntentService {
  StreamSubscription<List<SharedMediaFile>>? _subscription;
  final _urlController = StreamController<String>.broadcast();

  /// Stream of valid URLs shared while the app is in memory.
  Stream<String> get sharedUrlStream => _urlController.stream;

  /// Starts listening for share intents received while the app is running.
  void startListening() {
    _subscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen((List<SharedMediaFile> files) {
      final url = _extractUrl(files);
      if (url != null) {
        _urlController.add(url);
      }
    }, onError: (err) {
      // Silently ignore stream errors
    });
  }

  /// Gets the initial shared URL when the app was launched via a share intent.
  /// Returns `null` if the app was opened normally.
  Future<String?> getInitialSharedUrl() async {
    try {
      final files = await ReceiveSharingIntent.instance.getInitialMedia();
      final url = _extractUrl(files);
      // Tell the library we're done processing this intent
      ReceiveSharingIntent.instance.reset();
      return url;
    } catch (_) {
      return null;
    }
  }

  /// Extracts the first valid URL from shared media files.
  String? _extractUrl(List<SharedMediaFile> files) {
    for (final file in files) {
      // SharedMediaFile.path contains the shared text for text/* shares
      final text = file.path.trim();
      if (text.isEmpty) continue;

      // The shared text might contain a URL directly
      if (UrlUtils.isValidUrl(text)) {
        return text;
      }

      // Or it might contain text with a URL embedded — try to extract it
      final urlMatch = RegExp(
        r'https?://[^\s]+',
        caseSensitive: false,
      ).firstMatch(text);
      if (urlMatch != null) {
        return urlMatch.group(0);
      }
    }
    return null;
  }

  /// Cleans up resources.
  void dispose() {
    _subscription?.cancel();
    _urlController.close();
  }
}
