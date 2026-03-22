import 'package:url_launcher/url_launcher.dart';

String normalizeHttpUrl(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return '';
  if (t.startsWith('http://') || t.startsWith('https://')) return t;
  return 'https://$t';
}

Future<void> openExternalHttpUrl(String raw) async {
  final n = normalizeHttpUrl(raw);
  if (n.isEmpty) return;
  final uri = Uri.tryParse(n);
  if (uri == null) return;
  try {
    final ok = await canLaunchUrl(uri);
    if (ok) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
  } catch (_) {}
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}
}
