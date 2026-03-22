import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/scholarship_model.dart';
import '../models/loan_model.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/finshe_theme.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_Bubble> _messages = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    _controller.clear();
    setState(() {
      _messages.add(_Bubble(isUser: true, text: query));
      _loading = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });

    final app = context.read<AppProvider>();
    // History = previous turns only (exclude current user message we just added)
    final history = _messages.length > 1
        ? _messages.sublist(0, _messages.length - 1).map((b) => {
              'role': b.isUser ? 'user' : 'assistant',
              'content': b.text,
            }).toList()
        : <Map<String, String>>[];
    final result = await app.askAI(query, history: history);

    if (!mounted) return;
    setState(() {
      _messages.add(_Bubble(
        isUser: false,
        text: result.responseText,
        scholarships: result.scholarships,
        loans: result.loans,
      ));
      _loading = false;
    });
    if (!result.backendReachable && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cloud AI is temporarily unreachable. Please try again.'),
          duration: Duration(seconds: 4),
        ),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: FinsheColors.bg,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('AI Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline_rounded),
            tooltip: 'Example: Scholarships for women in Germany',
            onPressed: () {
              _controller.text = 'Scholarships for women studying engineering in Germany';
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Material(
              color: FinsheColors.card,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFB020), Color(0xFFFF6B35)],
                        ),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FinShe AI',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: FinsheColors.emerald,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Always active to help',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _messages.isEmpty
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: FinsheColors.accentPurple.withValues(alpha: 0.2),
                                ),
                                child: Icon(Icons.psychology_rounded, size: 72, color: FinsheColors.accentLavender.withValues(alpha: 0.95)),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Ask about scholarships and loans',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'e.g. "Scholarships for women in Germany" or "Low interest loans for masters in USA"',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.4),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Powered by the FinShe cloud backend. We combine your saved data, global knowledge, and live web results to answer your questions.',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline, fontStyle: FontStyle.italic, height: 1.35),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _messages.length + (_loading ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == _messages.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: FinsheColors.accentPurple.withValues(alpha: 0.95),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text('Thinking...', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        );
                      }
                      return _ChatBubble(bubble: _messages[i]);
                    },
                  ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: FinsheColors.cardMuted,
              border: Border(top: BorderSide(color: FinsheColors.outlineSoft.withValues(alpha: 0.5))),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Ask about scholarships or loans...',
                        prefixIcon: Icon(Icons.auto_fix_high_rounded, color: theme.colorScheme.onSurfaceVariant),
                        suffixIcon: Icon(Icons.mic_none_rounded, color: theme.colorScheme.onSurfaceVariant),
                        filled: true,
                        fillColor: FinsheColors.bg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: FinsheColors.outlineSoft.withValues(alpha: 0.7)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: FinsheColors.accentPurple, width: 1.2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: FinsheColors.accentPurple,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _loading ? null : _send,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble {
  final bool isUser;
  final String text;
  final List<ScholarshipModel> scholarships;
  final List<LoanModel> loans;

  _Bubble({required this.isUser, required this.text, this.scholarships = const [], this.loans = const []});
}

class _ChatBubble extends StatelessWidget {
  final _Bubble bubble;

  const _ChatBubble({required this.bubble});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = bubble.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        decoration: BoxDecoration(
          gradient: isUser
              ? LinearGradient(
                  colors: [
                    FinsheColors.accentPurple,
                    FinsheColors.accentPurple.withValues(alpha: 0.88),
                  ],
                )
              : null,
          color: isUser ? null : FinsheColors.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 6),
            bottomRight: Radius.circular(isUser ? 6 : 18),
          ),
          border: isUser ? null : Border.all(color: FinsheColors.outlineSoft.withValues(alpha: 0.55)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MarkdownBody(
              data: bubble.text,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: theme.textTheme.bodyLarge?.copyWith(
                  color: isUser ? Colors.white : theme.colorScheme.onSurface,
                  height: 1.45,
                ),
              ),
              onTapLink: (text, href, title) async {
                if (href != null) {
                  final uri = Uri.parse(href);
                  await launchUrl(uri);
                }
              },
            ),
            if (bubble.scholarships.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...bubble.scholarships.take(3).map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${s.name} (${s.provider})',
                      style: theme.textTheme.bodySmall?.copyWith(color: isUser ? Colors.white.withValues(alpha: 0.9) : theme.colorScheme.onSurfaceVariant),
                    ),
                  )),
            ],
            if (bubble.loans.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...bubble.loans.take(3).map((l) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${l.name} (${l.interestRate})',
                      style: theme.textTheme.bodySmall?.copyWith(color: isUser ? Colors.white.withValues(alpha: 0.9) : theme.colorScheme.onSurfaceVariant),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
