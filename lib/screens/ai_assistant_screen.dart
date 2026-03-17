import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/scholarship_model.dart';
import '../models/loan_model.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

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
          // No always-on "unreachable" banner: we only show an error after an actual failed request.
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.psychology_rounded, size: 72, color: theme.colorScheme.primary.withValues(alpha: 0.7)),
                          const SizedBox(height: 20),
                          Text(
                            'Ask about scholarships and loans',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'e.g. "Scholarships for women in Germany" or "Low interest loans for masters in USA"',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Powered by the FinShe cloud backend. We combine your saved data, global knowledge, and live web results to answer your questions.',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline, fontStyle: FontStyle.italic),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _messages.length + (_loading ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == _messages.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            children: [
                              SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                              SizedBox(width: 12),
                              Text('Thinking...'),
                            ],
                          ),
                        );
                      }
                      return _ChatBubble(bubble: _messages[i]);
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Ask about scholarships or loans...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _loading ? null : _send,
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
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
    return Align(
      alignment: bubble.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        decoration: BoxDecoration(
          color: bubble.isUser ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MarkdownBody(
              data: bubble.text,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: theme.textTheme.bodyLarge,
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
                    child: Text('• ${s.name} (${s.provider})', style: theme.textTheme.bodySmall),
                  )),
            ],
            if (bubble.loans.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...bubble.loans.take(3).map((l) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• ${l.name} (${l.interestRate})', style: theme.textTheme.bodySmall),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
