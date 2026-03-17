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

  static const _timeout = Duration(seconds: 30);
  static const _maxRetries = 3;

  /// Optional legacy fields if you still want to call OpenAI directly in future.
  String? openAiApiKey;
  String? serpApiKey;

  Future<AIChatResult> answer({
    required String query,
    required String uid,
    UserPreferences? preferences,
    List<Map<String, String>>? history,
  }) async {
    final scholarships = await _firestore.getScholarshipsOnce();
    final loans = await _firestore.getLoansOnce();

    String responseText;
    List<ScholarshipModel> matchedScholarships = [];
    List<LoanModel> matchedLoans = [];

    // 1) Match from Firestore
    final q = query.toLowerCase();
    matchedScholarships = scholarships.where((s) {
      if (s.name.toLowerCase().contains(q)) return true;
      if (s.country.toLowerCase().contains(q)) return true;
      if (s.fieldOfStudy.toLowerCase().contains(q)) return true;
      if (s.eligibility.toLowerCase().contains(q)) return true;
      if (s.provider.toLowerCase().contains(q)) return true;
      if (s.type.toLowerCase().contains(q)) return true;
      return false;
    }).toList();

    matchedLoans = loans.where((l) {
      if (l.name.toLowerCase().contains(q)) return true;
      if (l.country?.toLowerCase().contains(q) ?? false) return true;
      if (l.interestRate.toLowerCase().contains(q)) return true;
      if (l.maxAmount.toLowerCase().contains(q)) return true;
      if (l.loanType?.toLowerCase().contains(q) ?? false) return true;
      return false;
    }).toList();

    // 2) If no filter match, take all for "show me scholarships/loans" type queries
    if (matchedScholarships.isEmpty && matchedLoans.isEmpty) {
      if (q.contains('scholarship')) matchedScholarships = scholarships;
      if (q.contains('loan')) matchedLoans = loans;
    }

    // 3) Call FinShe backend (Node.js + OpenRouter + web search).
    // If backend fails for any reason, fall back to a minimal DB-only / generic message.
    final backendResponse = await _callBackend(
      query: query,
      scholarships: matchedScholarships,
      loans: matchedLoans,
      preferences: preferences,
      history: history,
    );

    final backendOk = backendResponse?.trim().isNotEmpty == true;
    responseText = backendOk
        ? backendResponse!.trim()
        : _buildTextResponse(matchedScholarships, matchedLoans, query);

    await _firestore.saveQuery(uid: uid, queryText: query, responseText: responseText);

    return AIChatResult(
      responseText: responseText,
      scholarships: matchedScholarships,
      loans: matchedLoans,
      backendReachable: backendOk,
    );
  }

  Future<String?> _callBackend({
    required String query,
    required List<ScholarshipModel> scholarships,
    required List<LoanModel> loans,
    UserPreferences? preferences,
    List<Map<String, String>>? history,
  }) async {
    final baseUrl = await BackendConfig.getBaseUrl();
    final uri = Uri.parse('$baseUrl/api/chat');

    final body = {
      'message': query,
      'history': history ?? [],
      'context': {
        'preferences': preferences?.toMap() ?? {},
        'scholarships': scholarships.take(20).map((s) {
          return {
            'name': s.name,
            'provider': s.provider,
            'eligibility': s.eligibility,
            'amount': s.amount,
            'deadline': s.deadline,
            'country': s.country,
            'fieldOfStudy': s.fieldOfStudy,
            'applicationLink': s.applicationLink,
            'type': s.type,
          };
        }).toList(),
        'loans': loans.take(20).map((l) {
          return {
            'name': l.name,
            'provider': l.provider,
            'interestRate': l.interestRate,
            'maxAmount': l.maxAmount,
            'eligibility': l.eligibility,
            'applicationLink': l.applicationLink,
            'country': l.country,
            'loanType': l.loanType,
            'repaymentPeriod': l.repaymentPeriod,
          };
        }).toList(),
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
      } catch (_) {
        if (attempt < _maxRetries) {
          await Future<void>.delayed(Duration(milliseconds: 500 * attempt));
        }
      }
    }
    return null;
  }

  Future<String?> _callOpenAI({
    required String query,
    required List<ScholarshipModel> scholarships,
    required List<LoanModel> loans,
    UserPreferences? preferences,
  }) async {
    try {
      final dbScholarships = scholarships.take(15).map((s) => '${s.name} (${s.provider}, ${s.country}, ${s.amount}, ${s.deadline})').join('; ');
      final dbLoans = loans.take(10).map((l) => '${l.name} (${l.interestRate}, ${l.maxAmount})').join('; ');
      final payload = {
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content': 'You are a helpful assistant for women seeking scholarships and education loans worldwide. '
                'Answer using BOTH (1) your general knowledge about global scholarships, loans, deadlines, and opportunities '
                'and (2) the database entries provided. Give concrete names, providers, amounts, deadlines, and application links when you know them. '
                'Prefer opportunities relevant to women and education. Be concise; use bullet points for multiple options.',
          },
          {
            'role': 'user',
            'content': 'User preferences: country ${preferences?.country ?? "any"}, '
                'degree ${preferences?.degree ?? "any"}, field ${preferences?.fieldOfStudy ?? "any"}.\n\n'
                'Question: $query\n\n'
                'Database entries to include if relevant:\n'
                'Scholarships: $dbScholarships\n'
                'Loans: $dbLoans',
          },
        ],
      };
      final res = await http.post(
        Uri.parse('$baseUrl/api/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAiApiKey',
        },
        body: jsonEncode(payload),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['choices']?[0]?['message']?['content']?.toString();
      }
    } catch (_) {}
    return null;
  }

  String _buildTextResponse(
    List<ScholarshipModel> scholarships,
    List<LoanModel> loans,
    String query,
  ) {
    final lowerQuery = query.toLowerCase();

    // For very generic chat like "hi", "hello", "hey", answer like a friendly assistant
    // instead of showing the "no matches in database" message.
    const greetings = ['hi', 'hello', 'hey', 'hii', 'hola'];
    if (scholarships.isEmpty &&
        loans.isEmpty &&
        greetings.any((g) => lowerQuery == g || lowerQuery.startsWith('$g '))) {
      return 'Hi! I’m the FinShe assistant. '
          'You can ask me anything about scholarships, education loans, budgeting, or your academic plans, '
          'and I’ll try to guide you using both our database and global knowledge.';
    }

    final buf = StringBuffer();
    if (scholarships.isNotEmpty || loans.isNotEmpty) {
      buf.writeln(
        '⚠️ Could not reach the AI server. Results below are from our local database and may not match your query (e.g. year, eligibility).\n'
        'Phone and laptop must be on the same Wi‑Fi. Set Server URL in Profile.\n',
      );
    }
    if (scholarships.isNotEmpty) {
      buf.writeln('Here are some scholarships that may match:\n');
      for (var i = 0; i < scholarships.length && i < 8; i++) {
        final s = scholarships[i];
        buf.writeln('• ${s.name} (${s.provider})');
        if (s.amount.isNotEmpty) buf.writeln('  Amount: ${s.amount}');
        if (s.deadline.isNotEmpty) buf.writeln('  Deadline: ${s.deadline}');
        if (s.country.isNotEmpty) buf.writeln('  Country: ${s.country}');
        buf.writeln('');
      }
    }
    if (loans.isNotEmpty) {
      buf.writeln('Here are some education loans:\n');
      for (var i = 0; i < loans.length && i < 5; i++) {
        final l = loans[i];
        buf.writeln('• ${l.name} (${l.provider})');
        if (l.interestRate.isNotEmpty) buf.writeln('  Interest: ${l.interestRate}');
        if (l.maxAmount.isNotEmpty) buf.writeln('  Max amount: ${l.maxAmount}');
        buf.writeln('');
      }
    }
    if (buf.isEmpty) {
      buf.writeln(
        'I\'m having trouble reaching the FinShe AI server.\n\n'
        'To fix:\n'
        '1. Ensure your phone and laptop are on the SAME Wi‑Fi (not mobile data)\n'
        '2. Start the server on your laptop: node server.js\n'
        '3. In Profile → Server URL, enter your laptop\'s IP (run ipconfig to find it) e.g. http://10.78.148.144:3000\n'
        '4. Run allow_server_firewall.ps1 as Administrator',
      );
    }
    return buf.toString().trim();
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
