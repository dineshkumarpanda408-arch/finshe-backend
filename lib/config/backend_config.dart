import 'package:http/http.dart' as http;

/// Cloud backend used by the app.
///
/// This is intentionally NOT user-configurable: the app targets the deployed
/// backend so it works on mobile data / any network without Wi‑Fi setup.
const String defaultBaseUrl = 'https://finshe-backend.onrender.com';

class BackendConfig {
  static const String baseUrl = defaultBaseUrl;

  static Future<String> getBaseUrl() async => baseUrl;

  /// Returns `null` when reachable, otherwise a short error message.
  ///
  /// The backend exposes a health check at GET `/`.
  static Future<String?> testConnection([String url = baseUrl]) async {
    try {
      final uri = Uri.parse(url);
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode >= 200 && res.statusCode < 300) return null;
      return 'HTTP ${res.statusCode}';
    } catch (e) {
      return e.toString();
    }
  }

  // Legacy API kept to avoid breaking old code paths. No-ops by design.
  static Future<void> setBaseUrl(String _) async {}
  static Future<void> resetToDefault() async {}
}

