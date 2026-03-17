/// Scholarship model. Firestore uses Name, Provider, etc. (capitalized).
class ScholarshipModel {
  final String id;
  final String name;
  final String provider;
  final String eligibility;
  final String amount;
  final String deadline;
  final String country;
  final String fieldOfStudy;
  final String applicationLink;
  final String type; // Government / Private

  const ScholarshipModel({
    required this.id,
    required this.name,
    this.provider = '',
    this.eligibility = '',
    this.amount = '',
    this.deadline = '',
    this.country = '',
    this.fieldOfStudy = '',
    this.applicationLink = '',
    this.type = '',
  });

  /// From Firestore doc (fields may be Name, Provider, etc. per your DB).
  factory ScholarshipModel.fromFirestore(String id, Map<String, dynamic> data) {
    String getStr(String key, [String altKey = '']) {
      final v = data[key] ?? data[altKey];
      if (v == null) return '';
      return v.toString().trim();
    }

    return ScholarshipModel(
      id: id,
      name: getStr('Name', 'name'),
      provider: getStr('Provider', 'provider'),
      eligibility: getStr('Eligibility', 'eligibility'),
      amount: getStr('Amount', 'amount'),
      deadline: getStr('Deadline', 'deadline'),
      country: getStr('Country', 'country'),
      fieldOfStudy: getStr('FieldOfStudy', 'fieldOfStudy'),
      applicationLink: getStr('Link', 'applicationLink'),
      type: getStr('Type', 'type'),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'Name': name,
      'Provider': provider,
      'Eligibility': eligibility,
      'Amount': amount,
      'Deadline': deadline,
      'Country': country,
      'FieldOfStudy': fieldOfStudy,
      'Link': applicationLink,
      'Type': type,
    };
  }
}
