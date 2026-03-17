import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/scholarship_model.dart';
import '../models/loan_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/ai_service.dart';

const String _keyOpenAiApiKey = 'openai_api_key';

class AppProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();
  final FirestoreService _firestore = FirestoreService();
  final AIService _aiService = AIService();

  UserModel? _currentUser;
  bool _isAdminSession = false;
  List<ScholarshipModel> _scholarships = [];
  List<LoanModel> _loans = [];
  String? _authError;

  UserModel? get currentUser => _currentUser;
  bool get isAdminSession => _isAdminSession;
  List<ScholarshipModel> get scholarships => _scholarships;
  List<LoanModel> get loans => _loans;
  String? get authError => _authError;
  bool get isLoggedIn => _currentUser != null;

  set authError(String? value) {
    _authError = value;
    notifyListeners();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString(_keyOpenAiApiKey);
    if (savedKey != null && savedKey.isNotEmpty) _aiService.openAiApiKey = savedKey;
    _auth.authStateChanges.listen((user) async {
      if (user != null) {
        final profile = await _auth.getUserProfile(user.uid);
        _currentUser = profile;
        _isAdminSession = false;
        if (profile != null) await _refreshSavedState(profile.uid);
      } else {
        _currentUser = null;
        _isAdminSession = false;
      }
      notifyListeners();
    });
  }

  Future<void> _refreshSavedState(String uid) async {
    final profile = await _auth.getUserProfile(uid);
    if (profile != null) _currentUser = profile;
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    _authError = null;
    try {
      final user = await _auth.signInWithGoogle();
      if (user != null) {
        _currentUser = user;
        _isAdminSession = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _authError = _auth.lastError ?? e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInAsAdmin({required String email, required String password}) async {
    _authError = null;
    final user = await _auth.signInAsAdmin(email: email, password: password);
    if (user != null) {
      _currentUser = user;
      _isAdminSession = true;
      notifyListeners();
      return true;
    }
    _authError = _auth.lastError ?? 'Invalid Admin Password';
    notifyListeners();
    return false;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    _isAdminSession = false;
    _scholarships = [];
    _loans = [];
    notifyListeners();
  }

  void setScholarships(List<ScholarshipModel> list) {
    _scholarships = list;
    notifyListeners();
  }

  void setLoans(List<LoanModel> list) {
    _loans = list;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    if (_currentUser == null) return;
    await _refreshSavedState(_currentUser!.uid);
  }

  Future<void> toggleSavedScholarship(String scholarshipId) async {
    if (_currentUser == null) return;
    await _firestore.toggleSavedScholarship(_currentUser!.uid, scholarshipId);
    await refreshUser();
  }

  Future<void> toggleSavedLoan(String loanId) async {
    if (_currentUser == null) return;
    await _firestore.toggleSavedLoan(_currentUser!.uid, loanId);
    await refreshUser();
  }

  bool isScholarshipSaved(String id) => _currentUser?.savedScholarships.contains(id) ?? false;
  bool isLoanSaved(String id) => _currentUser?.savedLoans.contains(id) ?? false;

  Future<void> updatePreferences(UserPreferences prefs) async {
    if (_currentUser == null) return;
    await _firestore.updateUserPreferences(_currentUser!.uid, prefs);
    _currentUser = _currentUser!.copyWith(preferences: prefs);
    notifyListeners();
  }

  Future<AIChatResult> askAI(String query, {List<Map<String, String>>? history}) async {
    return _aiService.answer(
      query: query,
      uid: _currentUser?.uid ?? 'guest',
      preferences: _currentUser?.preferences,
      history: history,
    );
  }

  void setOpenAiApiKey(String? key) {
    _aiService.openAiApiKey = key;
    SharedPreferences.getInstance().then((prefs) {
      if (key == null || key.isEmpty) {
        prefs.remove(_keyOpenAiApiKey);
      } else {
        prefs.setString(_keyOpenAiApiKey, key);
      }
    });
  }

  Future<String?> getOpenAiApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyOpenAiApiKey);
  }

  FirestoreService get firestore => _firestore;
  AIService get aiService => _aiService;
}
