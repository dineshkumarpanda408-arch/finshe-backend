import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime? date;
  final bool sentByAdmin;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    this.date,
    this.sentByAdmin = true,
  });

  factory AppNotification.fromFirestore(String id, Map<String, dynamic> data) {
    final ts = data['date'];
    DateTime? d;
    if (ts != null) {
      if (ts is Timestamp) d = ts.toDate();
      else if (ts is DateTime) d = ts;
      else if (ts is String) d = DateTime.tryParse(ts);
    }
    return AppNotification(
      id: id,
      title: data['title']?.toString() ?? '',
      message: data['message']?.toString() ?? '',
      date: d,
      sentByAdmin: data['sentByAdmin'] == true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'date': date ?? DateTime.now(),
      'sentByAdmin': sentByAdmin,
    };
  }
}
