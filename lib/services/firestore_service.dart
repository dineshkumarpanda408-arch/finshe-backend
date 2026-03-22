import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/scholarship_model.dart';
import '../models/loan_model.dart';
import '../models/notification_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users => _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _scholarships => _firestore.collection('scholarships');
  CollectionReference<Map<String, dynamic>> get _loans => _firestore.collection('loans');
  CollectionReference<Map<String, dynamic>> get _notifications => _firestore.collection('notifications');
  CollectionReference<Map<String, dynamic>> get _queries => _firestore.collection('queries');

  // ---------- Users ----------
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _users.doc(uid).update(data);
  }

  Future<void> updateUserPreferences(String uid, UserPreferences prefs) async {
    await _users.doc(uid).update({'preferences': prefs.toMap()});
  }

  Future<void> toggleSavedScholarship(String uid, String scholarshipId) async {
    final id = scholarshipId.trim();
    if (id.isEmpty) return;
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return;
    var list = UserModel.sanitizeSavedIds(doc.data()?['savedScholarships']);
    if (list.contains(id)) {
      list = list.where((e) => e != id).toList();
    } else {
      list = [...list, id];
    }
    await _users.doc(uid).update({'savedScholarships': list});
  }

  Future<void> toggleSavedLoan(String uid, String loanId) async {
    final id = loanId.trim();
    if (id.isEmpty) return;
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return;
    var list = UserModel.sanitizeSavedIds(doc.data()?['savedLoans']);
    if (list.contains(id)) {
      list = list.where((e) => e != id).toList();
    } else {
      list = [...list, id];
    }
    await _users.doc(uid).update({'savedLoans': list});
  }

  // ---------- Scholarships ----------
  Stream<List<ScholarshipModel>> getScholarshipsStream() {
    return _scholarships.snapshots().map((snap) {
      return snap.docs.map((d) => ScholarshipModel.fromFirestore(d.id, d.data())).toList();
    });
  }

  Future<List<ScholarshipModel>> getScholarshipsOnce() async {
    final snap = await _scholarships.get();
    return snap.docs.map((d) => ScholarshipModel.fromFirestore(d.id, d.data())).toList();
  }

  Future<void> addScholarship(ScholarshipModel s) async {
    await _scholarships.add(s.toFirestore());
  }

  Future<void> updateScholarship(String id, ScholarshipModel s) async {
    await _scholarships.doc(id).update(s.toFirestore());
  }

  Future<void> deleteScholarship(String id) async {
    await _scholarships.doc(id).delete();
  }

  // ---------- Loans ----------
  Stream<List<LoanModel>> getLoansStream() {
    return _loans.snapshots().map((snap) {
      return snap.docs.map((d) => LoanModel.fromFirestore(d.id, d.data())).toList();
    });
  }

  Future<List<LoanModel>> getLoansOnce() async {
    final snap = await _loans.get();
    return snap.docs.map((d) => LoanModel.fromFirestore(d.id, d.data())).toList();
  }

  Future<void> addLoan(LoanModel loan) async {
    await _loans.add(loan.toFirestore());
  }

  Future<void> updateLoan(String id, LoanModel loan) async {
    await _loans.doc(id).update(loan.toFirestore());
  }

  Future<void> deleteLoan(String id) async {
    await _loans.doc(id).delete();
  }


  // ---------- Notifications ----------
  Future<void> sendNotification({
    required String title,
    required String message,
  }) async {
    await _notifications.add({
      'title': title,
      'message': message,
      'date': FieldValue.serverTimestamp(),
      'sentByAdmin': true,
    });
  }

  Stream<List<AppNotification>> getNotificationsStream() {
    return _notifications.orderBy('date', descending: true).limit(50).snapshots().map((snap) {
      return snap.docs.map((d) => AppNotification.fromFirestore(d.id, d.data())).toList();
    });
  }

  Future<void> deleteNotification(String id) async {
    await _notifications.doc(id).delete();
  }

  // ---------- AI queries (log for history) ----------
  Future<void> saveQuery({
    required String uid,
    required String queryText,
    required String responseText,
  }) async {
    await _queries.add({
      'uid': uid,
      'queryText': queryText,
      'responseText': responseText,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
