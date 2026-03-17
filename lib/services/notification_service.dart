import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: android);
    await _plugin.initialize(initSettings, onDidReceiveNotificationResponse: _onSelect);
  }

  static void _onSelect(NotificationResponse response) {
    // Handle tap: could navigate to Scholarships/Loans tab
  }

  static Future<void> show(String title, String body) async {
    const android = AndroidNotificationDetails(
      'finshe_channel',
      'Finshe Notifications',
      channelDescription: 'Scholarship and loan updates',
      importance: Importance.defaultImportance,
    );
    const details = NotificationDetails(android: android);
    await _plugin.show(DateTime.now().millisecondsSinceEpoch % 0x7FFFFFFF, title, body, details);
  }
}
