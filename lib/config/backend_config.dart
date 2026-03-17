import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Backend server configuration for FinShe AI.
/// Update [defaultBaseUrl] when your laptop's IP changes (run `ipconfig` on Windows).
const String baseUrl = 'http://10.78.148.144:3000';
const String defaultBaseUrl = 'http://10.78.148.144:3000';
const String _prefKey = 'finshe_backend_base_url';

class BackendConfig {
  /// Tests if the server is reachable. Returns null on success, or error message on failure.
  static Future<String?> testConnection(String baseUrl) async {
    try {
      final uri = Uri.parse(baseUrl.replaceAll(RegExp(r'/$'), ''));
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) return null;
      return 'Server returned ${res.statusCode}';
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('connection refused')) {
        return 'Connection refused – Server not running or Windows Firewall blocking. Run allow_server_firewall.ps1 as Administrator.';
      }
      if (msg.contains('connection timed out') || msg.contains('timed out')) {
        return 'Timed out – Windows Firewall likely blocking. Run allow_server_firewall.ps1 as Administrator.';
      }
      if (msg.contains('network is unreachable') || msg.contains('unreachable')) {
        return 'Network unreachable – Phone and laptop on different Wi‑Fi? Disable mobile data on phone.';
      }
      if (msg.contains('failed host lookup') || msg.contains('nodename')) {
        return 'Invalid address – Check the IP is correct.';
      }
      return e.toString().replaceAll(RegExp(r'^.*?Exception:?\s*'), '').split('\n').first;
    }
  }
  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKey) ?? defaultBaseUrl;
  }

  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    if (url.trim().isEmpty) {
      await prefs.remove(_prefKey);
    } else {
      final trimmed = url.trim();
      if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
        await prefs.setString(_prefKey, 'http://$trimmed');
      } else {
        await prefs.setString(_prefKey, trimmed.replaceAll(RegExp(r'/$'), ''));
      }
    }
  }

  static Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }
}
