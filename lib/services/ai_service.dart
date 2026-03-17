import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/backend_config.dart';
import '../models/scholarship_model.dart';
import '../models/loan_model.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

/// Combines Firestore data with the FinShe backend (OpenRouter + web search).
/// The backend is the primary brain; local logic is only a safety fallback.
class AIService {
  final FirestoreService _firestore = FirestoreService();

  // Render (and similar hosts) can cold-start; keep this lenient for mobile.
  static const _timeout = Duration(seconds: 90);
  static const _maxRetries = 3;
  static const _backendBaseUrl = BackendConfig.baseUrl;

  /// Optional legacy fields if you still want to call OpenAI directly in future.
  String? openAiApiKey;
  String? serpApiKey;

  Future<AIChatResult> answer({
    required String query,
    required String uid,
    UserPreferences? preferences,
    List<Map<String, String>>? history,
  }) async {
    // AI Assistant should ONLY use the cloud backend (web + models),
    // and MUST NOT return results from the app database.
    final backendResponse = await _callBackend(
      query: query,
      preferences: preferences,
      history: history,
      sessionId: uid,
    );

    final backendOk = backendResponse?.trim().isNotEmpty == true;
    final responseText = backendOk ? backendResponse!.trim() : _buildTextResponse(query);

    await _firestore.saveQuery(uid: uid, queryText: query, responseText: responseText);

    return AIChatResult(
      responseText: responseText,
      scholarships: const [],
      loans: const [],
      backendReachable: backendOk,
    );
  }

  Future<String?> _callBackend({
    required String query,
    UserPreferences? preferences,
    List<Map<String, String>>? history,
    String? sessionId,
  }) async {
    final uri = Uri.parse('$_backendBaseUrl/api/chat');

    final body = {
      'message': query,
      'sessionId': sessionId,
      'history': history ?? [],
      'context': {
        'preferences': preferences?.toMap() ?? {},
      },
    };

    for (var attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final res = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
            .timeout(_timeout);

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          return data['reply']?.toString();
        }
        // Surface backend errors (e.g. OpenRouter auth issues) to the app
        // so it's clear the server is reachable but misconfigured/busy.
        try {
          final data = jsonDecode(res.body);
          final err = data is Map ? (data['error']?.toString() ?? data['message']?.toString()) : null;
          if (err != null && err.trim().isNotEmpty) {
            return 'Backend error (HTTP ${res.statusCode}): $err';
          }
        } catch (_) {
          // ignore parse errors; we'll retry or return null below
        }
      } catch (_) {
        if (attempt < _maxRetries) {
          await Future<void>.delayed(Duration(milliseconds: 500 * attempt));
        }
      }
    }
    return null;
  }

  String _buildTextResponse(String query) {
    final lowerQuery = query.toLowerCase();

    const greetings = ['hi', 'hello', 'hey', 'hii', 'hola'];
    if (greetings.any((g) => lowerQuery == g || lowerQuery.startsWith('$g '))) {
      return 'Hi! I’m the FinShe assistant. Ask me anything about scholarships, education loans, budgeting, or your academic plans.';
    }

    return 'I can’t reach the FinShe cloud AI right now. Please check your internet connection and try again.';
  }
}

class AIChatResult {
  final String responseText;
  final List<ScholarshipModel> scholarships;
  final List<LoanModel> loans;
  final bool backendReachable;

  AIChatResult({
    required this.responseText,
    this.scholarships = const [],
    this.loans = const [],
    this.backendReachable = true,
  });
}
