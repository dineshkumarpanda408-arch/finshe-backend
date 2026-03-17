import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/scholarship_model.dart';
import '../models/loan_model.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _firestore = FirestoreService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Scholarships', icon: Icon(Icons.school_rounded)),
            Tab(text: 'Loans', icon: Icon(Icons.account_balance_rounded)),
            Tab(text: 'Notifications', icon: Icon(Icons.notifications_rounded)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AdminScholarshipsTab(firestore: _firestore),
          _AdminLoansTab(firestore: _firestore),
          _AdminNotificationsTab(firestore: _firestore),
        ],
      ),
    );
  }
}

class _AdminScholarshipsTab extends StatelessWidget {
  final FirestoreService firestore;

  const _AdminScholarshipsTab({required this.firestore});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ScholarshipModel>>(
      stream: firestore.getScholarshipsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final list = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FilledButton.icon(
              onPressed: () => _showAddScholarship(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add scholarship'),
            ),
            const SizedBox(height: 16),
            ...list.map((s) => ListTile(
                  title: Text(s.name),
                  subtitle: Text('${s.provider} · ${s.country}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit_rounded), onPressed: () => _showEditScholarship(context, s)),
                      IconButton(icon: const Icon(Icons.delete_rounded), onPressed: () => _confirmDeleteScholarship(context, s)),
                    ],
                  ),
                )),
          ],
        );
      },
    );
  }

  void _showAddScholarship(BuildContext context) {
    _showScholarshipForm(context, null);
  }

  void _showEditScholarship(BuildContext context, ScholarshipModel s) {
    _showScholarshipForm(context, s);
  }

  Future<void> _showScholarshipForm(BuildContext context, ScholarshipModel? existing) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final provider = TextEditingController(text: existing?.provider ?? '');
    final eligibility = TextEditingController(text: existing?.eligibility ?? '');
    final amount = TextEditingController(text: existing?.amount ?? '');
    final deadline = TextEditingController(text: existing?.deadline ?? '');
    final country = TextEditingController(text: existing?.country ?? '');
    final fieldOfStudy = TextEditingController(text: existing?.fieldOfStudy ?? '');
    final link = TextEditingController(text: existing?.applicationLink ?? '');
    final type = TextEditingController(text: existing?.type ?? '');
    final firestore = this.firestore;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add scholarship' : 'Edit scholarship'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Name *')),
              TextField(controller: provider, decoration: const InputDecoration(labelText: 'Provider')),
              TextField(controller: eligibility, decoration: const InputDecoration(labelText: 'Eligibility')),
              TextField(controller: amount, decoration: const InputDecoration(labelText: 'Amount')),
              TextField(controller: deadline, decoration: const InputDecoration(labelText: 'Deadline')),
              TextField(controller: country, decoration: const InputDecoration(labelText: 'Country')),
              TextField(controller: fieldOfStudy, decoration: const InputDecoration(labelText: 'Field of study')),
              TextField(controller: link, decoration: const InputDecoration(labelText: 'Application link')),
              TextField(controller: type, decoration: const InputDecoration(labelText: 'Type (Government/Private)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final nameStr = name.text.trim();
              if (nameStr.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
                return;
              }
              final model = ScholarshipModel(
                id: existing?.id ?? '',
                name: nameStr,
                provider: provider.text.trim(),
                eligibility: eligibility.text.trim(),
                amount: amount.text.trim(),
                deadline: deadline.text.trim(),
                country: country.text.trim(),
                fieldOfStudy: fieldOfStudy.text.trim(),
                applicationLink: link.text.trim(),
                type: type.text.trim(),
              );
              try {
                if (existing != null) {
                  await firestore.updateScholarship(existing.id, model);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scholarship updated')));
                  }
                } else {
                  await firestore.addScholarship(model);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scholarship added')));
                  }
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e'), backgroundColor: Theme.of(context).colorScheme.error),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteScholarship(BuildContext context, ScholarshipModel s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete scholarship?'),
        content: Text('Delete "${s.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await firestore.deleteScholarship(s.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scholarship deleted')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $e'), backgroundColor: Theme.of(context).colorScheme.error),
          );
        }
      }
    }
  }
}

class _AdminLoansTab extends StatelessWidget {
  final FirestoreService firestore;

  const _AdminLoansTab({required this.firestore});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LoanModel>>(
      stream: firestore.getLoansStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final list = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FilledButton.icon(
              onPressed: () => _showAddLoan(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add loan'),
            ),
            const SizedBox(height: 16),
            ...list.map((l) => ListTile(
                  title: Text(l.name),
                  subtitle: Text('${l.interestRate} · ${l.maxAmount}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit_rounded), onPressed: () => _showEditLoan(context, l)),
                      IconButton(icon: const Icon(Icons.delete_rounded), onPressed: () => _confirmDeleteLoan(context, l)),
                    ],
                  ),
                )),
          ],
        );
      },
    );
  }

  void _showAddLoan(BuildContext context) {
    _showLoanForm(context, null);
  }

  void _showEditLoan(BuildContext context, LoanModel l) {
    _showLoanForm(context, l);
  }

  Future<void> _showLoanForm(BuildContext context, LoanModel? existing) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final provider = TextEditingController(text: existing?.provider ?? '');
    final interestRate = TextEditingController(text: existing?.interestRate ?? '');
    final maxAmount = TextEditingController(text: existing?.maxAmount ?? '');
    final eligibility = TextEditingController(text: existing?.eligibility ?? '');
    final link = TextEditingController(text: existing?.applicationLink ?? '');
    final firestore = this.firestore;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add loan' : 'Edit loan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Name *')),
              TextField(controller: provider, decoration: const InputDecoration(labelText: 'Provider')),
              TextField(controller: interestRate, decoration: const InputDecoration(labelText: 'Interest rate')),
              TextField(controller: maxAmount, decoration: const InputDecoration(labelText: 'Max amount')),
              TextField(controller: eligibility, decoration: const InputDecoration(labelText: 'Eligibility')),
              TextField(controller: link, decoration: const InputDecoration(labelText: 'Application link')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final model = LoanModel(
                id: existing?.id ?? '',
                name: name.text.trim(),
                provider: provider.text.trim(),
                interestRate: interestRate.text.trim(),
                maxAmount: maxAmount.text.trim(),
                eligibility: eligibility.text.trim(),
                applicationLink: link.text.trim(),
              );
              if (existing != null) {
                await firestore.updateLoan(existing.id, model);
              } else {
                await firestore.addLoan(model);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteLoan(BuildContext context, LoanModel l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete loan?'),
        content: Text('Delete "${l.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) await firestore.deleteLoan(l.id);
  }
}

class _AdminNotificationsTab extends StatelessWidget {
  final FirestoreService firestore;

  const _AdminNotificationsTab({required this.firestore});

  @override
  Widget build(BuildContext context) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Send a notification to all users:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(
          controller: titleController,
          decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: messageController,
          decoration: const InputDecoration(labelText: 'Message', border: OutlineInputBorder()),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () async {
            final title = titleController.text.trim();
            final message = messageController.text.trim();
            if (title.isEmpty || message.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter title and message')));
              return;
            }
            await firestore.sendNotification(title: title, message: message);
            await NotificationService.show(title, message);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification sent')));
              titleController.clear();
              messageController.clear();
            }
          },
          icon: const Icon(Icons.send_rounded),
          label: const Text('Send notification'),
        ),
      ],
    );
  }
}
