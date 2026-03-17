import 'package:flutter/material.dart'; import 'package:provider/provider.dart'; import '../providers/app_provider.dart'; import '../models/user_model.dart'; import '../models/scholarship_model.dart'; import '../models/loan_model.dart'; import '../services/firestore_service.dart';

class ProfileScreen extends StatelessWidget { const ProfileScreen({super.key});

@override Widget build(BuildContext context) { final app = context.watch<AppProvider>(); final user = app.currentUser;

if (user == null) {
  return const Scaffold(body: Center(child: Text('Not signed in')));
}

final theme = Theme.of(context);

return Scaffold(
  body: SafeArea(
    child: Column(
      children: [
        // 🔥 Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withOpacity(0.7),
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40),
              ),
              const SizedBox(height: 12),
              Text(user.name,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              Text(user.email,
                  style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // ✅ Preferences (FIXED)
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.tune),
                  title: const Text('Preferences'),
                  subtitle: Text(_prefsSummary(user.preferences)),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _editPreferences(context, app, user),
                ),
              ),

              const SizedBox(height: 12),

              // ✅ Saved Scholarships (FIXED)
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: ExpansionTile(
                  leading: const Icon(Icons.bookmark),
                  title: const Text('Saved Scholarships'),
                  children: [
                    _SavedScholarshipsList(
                      uid: user.uid,
                      savedIds: user.savedScholarships,
                    )
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ✅ Saved Loans (FIXED)
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: ExpansionTile(
                  leading: const Icon(Icons.account_balance),
                  title: const Text('Saved Loans'),
                  children: [
                    _SavedLoansList(
                      uid: user.uid,
                      savedIds: user.savedLoans,
                    )
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 🔴 Logout
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () async {
                  await app.signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
);

}

String _prefsSummary(UserPreferences? p) { if (p == null) return 'Not set'; final parts = <String>[]; if (p.country != null && p.country!.isNotEmpty) parts.add(p.country!); if (p.degree != null && p.degree!.isNotEmpty) parts.add(p.degree!); if (p.fieldOfStudy != null && p.fieldOfStudy!.isNotEmpty) parts.add(p.fieldOfStudy!); return parts.isEmpty ? 'Not set' : parts.join(' · '); }

Future<void> _editPreferences( BuildContext context, AppProvider app, UserModel user) async { await showDialog( context: context, builder: (ctx) => _PreferencesDialog( initial: user.preferences, onSave: (prefs) { app.updatePreferences(prefs); Navigator.pop(ctx); }, ), ); } }

// ✅ SAME OLD WORKING LISTS (UNCHANGED) class _SavedScholarshipsList extends StatelessWidget { final String uid; final List<String> savedIds;

const _SavedScholarshipsList( {required this.uid, required this.savedIds});

@override Widget build(BuildContext context) { if (savedIds.isEmpty) return const Padding( padding: EdgeInsets.all(12), child: Text('No saved scholarships'), );

return StreamBuilder<List<ScholarshipModel>>(
stream: FirestoreService().getScholarshipsStream(),
builder: (context, snapshot) {
if (!snapshot.hasData) return const Padding(
padding: EdgeInsets.all(12),
child: CircularProgressIndicator(),
);
final saved = snapshot.data!
    .where((s) => savedIds.contains(s.id))
    .toList();

return Column(
children: saved
    .map((s) => ListTile(
title: Text(s.name),
subtitle:
s.provider.isNotEmpty ? Text(s.provider) : null,
))
    .toList(),
);
},
);

} }

class _SavedLoansList extends StatelessWidget { final String uid; final List<String> savedIds;

const _SavedLoansList({required this.uid, required this.savedIds});

@override Widget build(BuildContext context) { if (savedIds.isEmpty) return const Padding( padding: EdgeInsets.all(12), child: Text('No saved loans'), );

return StreamBuilder<List<LoanModel>>(
stream: FirestoreService().getLoansStream(),
builder: (context, snapshot) {
if (!snapshot.hasData) return const Padding(
padding: EdgeInsets.all(12),
child: CircularProgressIndicator(),
);
final saved = snapshot.data!
    .where((l) => savedIds.contains(l.id))
    .toList();

return Column(
children: saved
    .map((l) => ListTile(
title: Text(l.name),
subtitle:
l.provider.isNotEmpty ? Text(l.provider) : null,
))
    .toList(),
);
},
);

} }

class _PreferencesDialog extends StatefulWidget { final UserPreferences? initial; final void Function(UserPreferences) onSave;

const _PreferencesDialog({this.initial, required this.onSave});

@override State<_PreferencesDialog> createState() => _PreferencesDialogState(); }

class _PreferencesDialogState extends State<_PreferencesDialog> { late final TextEditingController _countryController; late final TextEditingController _degreeController; late final TextEditingController _fieldController;

@override void initState() { super.initState(); _countryController = TextEditingController(text: widget.initial?.country ?? ''); _degreeController = TextEditingController(text: widget.initial?.degree ?? ''); _fieldController = TextEditingController( text: widget.initial?.fieldOfStudy ?? ''); }

@override Widget build(BuildContext context) { return AlertDialog( title: const Text('Edit Preferences'), content: Column( mainAxisSize: MainAxisSize.min, children: [ TextField(controller: _countryController, decoration: const InputDecoration(labelText: 'Country')), TextField(controller: _degreeController, decoration: const InputDecoration(labelText: 'Degree')), TextField(controller: _fieldController, decoration: const InputDecoration(labelText: 'Field')), ], ), actions: [ TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), ElevatedButton( onPressed: () { widget.onSave(UserPreferences( country: _countryController.text.trim(), degree: _degreeController.text.trim(), fieldOfStudy: _fieldController.text.trim(), )); }, child: const Text('Save'), ) ], ); } }