import 'package:flutter/material.dart';
import '../models/scholarship_model.dart';
import '../models/loan_model.dart';
import '../services/firestore_service.dart';
import '../theme/finshe_theme.dart';

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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: FinsheColors.bg,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: FinsheColors.gradientHeader,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
          ),
        ),
        title: Text('Admin Panel', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.65),
          indicatorColor: FinsheColors.accentLavender,
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
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => _showAddScholarship(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add scholarship'),
              ),
            ),
            const SizedBox(height: 16),
            ...list.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: FinsheColors.card,
                    borderRadius: BorderRadius.circular(18),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
                      subtitle: Text('${s.provider} · ${s.country}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit_rounded), onPressed: () => _showEditScholarship(context, s)),
                          IconButton(icon: Icon(Icons.delete_rounded, color: Theme.of(context).colorScheme.error), onPressed: () => _confirmDeleteScholarship(context, s)),
                        ],
                      ),
                    ),
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
              TextField(
                controller: link,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Application link',
                  hintText: 'https://example.com/apply',
                ),
              ),
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
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => _showAddLoan(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add loan'),
              ),
            ),
            const SizedBox(height: 16),
            ...list.map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: FinsheColors.card,
                    borderRadius: BorderRadius.circular(18),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      title: Text(l.name, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
                      subtitle: Text('${l.interestRate} · ${l.maxAmount}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit_rounded), onPressed: () => _showEditLoan(context, l)),
                          IconButton(icon: Icon(Icons.delete_rounded, color: Theme.of(context).colorScheme.error), onPressed: () => _confirmDeleteLoan(context, l)),
                        ],
                      ),
                    ),
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
    final country = TextEditingController(text: existing?.country ?? '');
    final loanType = TextEditingController(text: existing?.loanType ?? '');
    final repaymentPeriod = TextEditingController(text: existing?.repaymentPeriod ?? '');
    final collateral = TextEditingController(text: existing?.collateralRequired ?? '');
    final insurance = TextEditingController(text: existing?.insuranceRequired ?? '');
    final margin = TextEditingController(text: existing?.margin ?? '');
    final processingFee = TextEditingController(text: existing?.processingFee ?? '');
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
              TextField(
                controller: link,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Application link',
                  hintText: 'https://...',
                ),
              ),
              TextField(controller: country, decoration: const InputDecoration(labelText: 'Country')),
              TextField(controller: loanType, decoration: const InputDecoration(labelText: 'Loan type')),
              TextField(controller: repaymentPeriod, decoration: const InputDecoration(labelText: 'Repayment period')),
              TextField(controller: collateral, decoration: const InputDecoration(labelText: 'Collateral required')),
              TextField(controller: insurance, decoration: const InputDecoration(labelText: 'Insurance required')),
              TextField(controller: margin, decoration: const InputDecoration(labelText: 'Margin')),
              TextField(controller: processingFee, decoration: const InputDecoration(labelText: 'Processing fee')),
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
                country: country.text.trim().isEmpty ? null : country.text.trim(),
                loanType: loanType.text.trim().isEmpty ? null : loanType.text.trim(),
                collateralRequired: collateral.text.trim().isEmpty ? null : collateral.text.trim(),
                insuranceRequired: insurance.text.trim().isEmpty ? null : insurance.text.trim(),
                margin: margin.text.trim().isEmpty ? null : margin.text.trim(),
                processingFee: processingFee.text.trim().isEmpty ? null : processingFee.text.trim(),
                repaymentPeriod: repaymentPeriod.text.trim().isEmpty ? null : repaymentPeriod.text.trim(),
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
        Material(
          color: FinsheColors.card,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Send a notification to all users:', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 14),
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
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () async {
                      final title = titleController.text.trim();
                      final message = messageController.text.trim();
                      if (title.isEmpty || message.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter title and message')));
                        return;
                      }
                      await firestore.sendNotification(title: title, message: message);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Notice saved. Everyone sees it under Profile → Announcements in the app. '
                              'System push alerts require Firebase Cloud Messaging setup.',
                            ),
                          ),
                        );
                        titleController.clear();
                        messageController.clear();
                      }
                    },
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Send notification'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
