import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/backend_config.dart';
import '../providers/app_provider.dart';
import '../models/user_model.dart';
import '../models/scholarship_model.dart';
import '../models/loan_model.dart';
import '../services/firestore_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final user = app.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign out')),
                  ],
                ),
              );
              if (confirm == true && context.mounted) await app.signOut();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(user.email, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  if (user.role == 'admin') Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Chip(label: const Text('Admin'), backgroundColor: Theme.of(context).colorScheme.primaryContainer),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.tune_rounded),
            title: const Text('Preferences'),
            subtitle: Text(_prefsSummary(user.preferences)),
            onTap: () => _editPreferences(context, app, user),
          ),
          ListTile(
            leading: const Icon(Icons.smart_toy_rounded),
            title: const Text('AI Assistant'),
            subtitle: const Text('Uses the FinShe cloud backend + live web data. No extra setup needed.'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('AI is already enabled via the FinShe backend.'),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.cloud_rounded),
            title: const Text('Backend'),
            subtitle: Text(
              BackendConfig.baseUrl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const Divider(),
          const Text('Saved Scholarships', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _SavedScholarshipsList(uid: user.uid, savedIds: user.savedScholarships),
          const SizedBox(height: 16),
          const Text('Saved Loans', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _SavedLoansList(uid: user.uid, savedIds: user.savedLoans),
        ],
      ),
    );
  }

  String _prefsSummary(UserPreferences? p) {
    if (p == null) return 'Not set';
    final parts = <String>[];
    if (p.country != null && p.country!.isNotEmpty) parts.add(p.country!);
    if (p.degree != null && p.degree!.isNotEmpty) parts.add(p.degree!);
    if (p.fieldOfStudy != null && p.fieldOfStudy!.isNotEmpty) parts.add(p.fieldOfStudy!);
    return parts.isEmpty ? 'Not set' : parts.join(' · ');
  }

  // OpenAI key UI is no longer needed because AI now goes through the FinShe backend.

  Future<void> _editPreferences(BuildContext context, AppProvider app, UserModel user) async {
    await showDialog(
      context: context,
      builder: (ctx) => _PreferencesDialog(
        initial: user.preferences,
        onSave: (prefs) {
          app.updatePreferences(prefs);
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

class _PreferencesDialog extends StatefulWidget {
  final UserPreferences? initial;
  final void Function(UserPreferences) onSave;

  const _PreferencesDialog({this.initial, required this.onSave});

  @override
  State<_PreferencesDialog> createState() => _PreferencesDialogState();
}

class _PreferencesDialogState extends State<_PreferencesDialog> {
  late final TextEditingController _countryController;
  late final TextEditingController _degreeController;
  late final TextEditingController _fieldController;

  @override
  void initState() {
    super.initState();
    _countryController = TextEditingController(text: widget.initial?.country ?? '');
    _degreeController = TextEditingController(text: widget.initial?.degree ?? '');
    _fieldController = TextEditingController(text: widget.initial?.fieldOfStudy ?? '');
  }

  @override
  void dispose() {
    _countryController.dispose();
    _degreeController.dispose();
    _fieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit preferences'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: const InputDecoration(labelText: 'Country'), controller: _countryController),
            TextField(decoration: const InputDecoration(labelText: 'Degree (e.g. Undergraduate, Masters)'), controller: _degreeController),
            TextField(decoration: const InputDecoration(labelText: 'Field of study'), controller: _fieldController),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            widget.onSave(UserPreferences(
              country: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
              degree: _degreeController.text.trim().isEmpty ? null : _degreeController.text.trim(),
              fieldOfStudy: _fieldController.text.trim().isEmpty ? null : _fieldController.text.trim(),
            ));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _SavedScholarshipsList extends StatelessWidget {
  final String uid;
  final List<String> savedIds;

  const _SavedScholarshipsList({required this.uid, required this.savedIds});

  @override
  Widget build(BuildContext context) {
    if (savedIds.isEmpty) {
      return Text('None', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant));
    }
    return StreamBuilder<List<ScholarshipModel>>(
      stream: FirestoreService().getScholarshipsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final all = snapshot.data!;
        final saved = all.where((s) => savedIds.contains(s.id)).toList();
        if (saved.isEmpty) return const Text('None');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: saved.map((s) => ListTile(
            dense: true,
            title: Text(s.name),
            subtitle: s.provider.isNotEmpty ? Text(s.provider) : null,
          )).toList(),
        );
      },
    );
  }
}

class _SavedLoansList extends StatelessWidget {
  final String uid;
  final List<String> savedIds;

  const _SavedLoansList({required this.uid, required this.savedIds});

  @override
  Widget build(BuildContext context) {
    if (savedIds.isEmpty) {
      return Text('None', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant));
    }
    return StreamBuilder<List<LoanModel>>(
      stream: FirestoreService().getLoansStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final all = snapshot.data!;
        final saved = all.where((l) => savedIds.contains(l.id)).toList();
        if (saved.isEmpty) return const Text('None');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: saved.map((l) => ListTile(
            dense: true,
            title: Text(l.name),
            subtitle: l.provider.isNotEmpty ? Text(l.provider) : null,
          )).toList(),
        );
      },
    );
  }
}
