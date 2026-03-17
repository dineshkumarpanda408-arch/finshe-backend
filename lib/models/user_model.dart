/// User model matching Firestore users collection.
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // 'user' | 'admin'
  final List<String> savedScholarships;
  final List<String> savedLoans;
  final UserPreferences? preferences;
  final bool subscriptionStatus;
  final String? lastLoginDate;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.savedScholarships = const [],
    this.savedLoans = const [],
    this.preferences,
    this.subscriptionStatus = false,
    this.lastLoginDate,
  });

  bool get isAdmin => role == 'admin';

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'uid': uid,
      'role': role,
      'savedScholarships': savedScholarships,
      'savedLoans': savedLoans,
      'preferences': preferences?.toMap(),
      'subscriptionStatus': subscriptionStatus,
      'lastLoginDate': lastLoginDate ?? DateTime.now().toIso8601String(),
    };
  }

  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    final prefs = map['preferences'];
    return UserModel(
      uid: id,
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      role: map['role']?.toString() ?? 'user',
      savedScholarships: List<String>.from(map['savedScholarships'] ?? []),
      savedLoans: List<String>.from(map['savedLoans'] ?? []),
      preferences: prefs is Map ? UserPreferences.fromMap(Map.from(prefs)) : null,
      subscriptionStatus: map['subscriptionStatus'] == true,
      lastLoginDate: map['lastLoginDate']?.toString(),
    );
  }

  UserModel copyWith({
    String? name,
    List<String>? savedScholarships,
    List<String>? savedLoans,
    UserPreferences? preferences,
    bool? subscriptionStatus,
    String? lastLoginDate,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      role: role,
      savedScholarships: savedScholarships ?? this.savedScholarships,
      savedLoans: savedLoans ?? this.savedLoans,
      preferences: preferences ?? this.preferences,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
    );
  }
}

class UserPreferences {
  final String? country;
  final String? degree;
  final String? fieldOfStudy;

  const UserPreferences({this.country, this.degree, this.fieldOfStudy});

  Map<String, dynamic> toMap() {
    return {
      if (country != null && country!.isNotEmpty) 'country': country,
      if (degree != null && degree!.isNotEmpty) 'degree': degree,
      if (fieldOfStudy != null && fieldOfStudy!.isNotEmpty) 'fieldOfStudy': fieldOfStudy,
    };
  }

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      country: map['country']?.toString(),
      degree: map['degree']?.toString(),
      fieldOfStudy: map['fieldOfStudy']?.toString(),
    );
  }

  UserPreferences copyWith({String? country, String? degree, String? fieldOfStudy}) {
    return UserPreferences(
      country: country ?? this.country,
      degree: degree ?? this.degree,
      fieldOfStudy: fieldOfStudy ?? this.fieldOfStudy,
    );
  }
}
