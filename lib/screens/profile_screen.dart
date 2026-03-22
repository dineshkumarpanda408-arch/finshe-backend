import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/backend_config.dart';
import '../providers/app_provider.dart';
import '../models/user_model.dart';
import '../models/scholarship_model.dart';
import '../models/loan_model.dart';
import '../models/notification_model.dart';
import '../services/firestore_service.dart';
import '../theme/finshe_theme.dart';

class ProfileScreen extends StatelessWidget {
  /// Called when the user taps "See all". Pass the target tab index:
  /// 0 = Scholarships, 1 = Loans.
  final void Function(int tabIndex)? onNavigate;

  const ProfileScreen({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final user = app.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: FinsheColors.bg,
        body: Center(
          child: Text('Not signed in', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
      );
    }
    final theme = Theme.of(context);
    final initials = user.name.trim().isNotEmpty
        ? user.name.trim().split(RegExp(r'\s+')).map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : '?';
    return Scaffold(
      backgroundColor: FinsheColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 28),
                  decoration: const BoxDecoration(
                    gradient: FinsheColors.gradientPurplePink,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'User Profile',
                                style: theme.textTheme.labelLarge?.copyWith(color: Colors.white.withValues(alpha: 0.75), fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Your journey',
                                style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                        Material(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: const CircleBorder(),
                          child: IconButton(
                            icon: const Icon(Icons.logout_rounded, color: Colors.white),
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
                        ),
                      ],
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -34),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFFD54F), width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 44,
                          backgroundColor: FinsheColors.card,
                          child: Text(
                            initials,
                            style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.name,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          user.email,
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (user.role == 'admin')
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Chip(
                            label: const Text('Admin'),
                            backgroundColor: FinsheColors.accentPurple.withValues(alpha: 0.35),
                            labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            sliver: SliverToBoxAdapter(
              child: _SavedStatsRow(
                savedScholarshipIds: user.savedScholarships,
                savedLoanIds: user.savedLoans,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: _AnnouncementsSection()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Material(
                color: FinsheColors.card,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('My Preferences', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: Colors.white)),
                          const Spacer(),
                          TextButton(
                            onPressed: () => _editPreferences(context, app, user),
                            child: Text('Edit', style: TextStyle(color: FinsheColors.accentLavender, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _preferenceChips(user.preferences),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Material(
                color: FinsheColors.card,
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  children: [
                    _MenuRow(
                      icon: Icons.tune_rounded,
                      title: 'Preferences',
                      subtitle: _prefsSummary(user.preferences),
                      onTap: () => _editPreferences(context, app, user),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Row(
                children: [
                  Text('Saved Scholarships', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: Colors.white)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => onNavigate?.call(0),
                    child: Text('See all', style: theme.textTheme.labelLarge?.copyWith(color: FinsheColors.accentLavender, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SavedScholarshipsList(uid: user.uid, savedIds: user.savedScholarships),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Row(
                children: [
                  Text('Saved Loans', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: Colors.white)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => onNavigate?.call(1),
                    child: Text('See all', style: theme.textTheme.labelLarge?.copyWith(color: FinsheColors.accentLavender, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              child: _SavedLoansList(uid: user.uid, savedIds: user.savedLoans),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _preferenceChips(UserPreferences? p) {
    final parts = <String>[];
    if (p != null) {
      if (p.country != null && p.country!.isNotEmpty) parts.add(p.country!);
      if (p.degree != null && p.degree!.isNotEmpty) parts.add(p.degree!);
      if (p.fieldOfStudy != null && p.fieldOfStudy!.isNotEmpty) parts.add(p.fieldOfStudy!);
    }
    if (parts.isEmpty) {
      return [
        Chip(
          label: const Text('Not set'),
          backgroundColor: FinsheColors.cardMuted,
          side: BorderSide(color: FinsheColors.outlineSoft.withValues(alpha: 0.7)),
          labelStyle: const TextStyle(color: Colors.white70),
        ),
      ];
    }
    return parts
        .map(
          (t) => Chip(
            avatar: const Icon(Icons.check_rounded, size: 16, color: FinsheColors.accentPurple),
            label: Text(t),
            backgroundColor: FinsheColors.accentLavender.withValues(alpha: 0.14),
            side: BorderSide(color: FinsheColors.accentPurple.withValues(alpha: 0.35)),
            labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        )
        .toList();
  }

  String _prefsSummary(UserPreferences? p) {
    if (p == null) return 'Not set';
    final parts = <String>[];
    if (p.country != null && p.country!.isNotEmpty) parts.add(p.country!);
    if (p.degree != null && p.degree!.isNotEmpty) parts.add(p.degree!);
    if (p.fieldOfStudy != null && p.fieldOfStudy!.isNotEmpty) parts.add(p.fieldOfStudy!);
    return parts.isEmpty ? 'Not set' : parts.join(' · ');
  }

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

/// Stats match the lists below: only IDs that still exist in Firestore collections count.
/// Raw [UserModel] lists can contain stale IDs (deleted items), which previously inflated totals.
class _SavedStatsRow extends StatelessWidget {
  final List<String> savedScholarshipIds;
  final List<String> savedLoanIds;

  const _SavedStatsRow({
    required this.savedScholarshipIds,
    required this.savedLoanIds,
  });

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    return StreamBuilder<List<ScholarshipModel>>(
      stream: fs.getScholarshipsStream(),
      builder: (context, schSnap) {
        return StreamBuilder<List<LoanModel>>(
          stream: fs.getLoansStream(),
          builder: (context, loanSnap) {
            final loading = !schSnap.hasData || !loanSnap.hasData;
            if (loading) {
              return Row(
                children: [
                  Expanded(child: _StatTile(value: '…', label: 'Saved', emphasize: false)),
                  const SizedBox(width: 10),
                  Expanded(child: _StatTile(value: '…', label: 'Loans', emphasize: false)),
                  const SizedBox(width: 10),
                  Expanded(child: _StatTile(value: '…', label: 'Total', emphasize: true)),
                ],
              );
            }
            final schSet = savedScholarshipIds.toSet();
            final loanSet = savedLoanIds.toSet();
            final nSch = schSnap.data!.where((s) => schSet.contains(s.id)).length;
            final nLoan = loanSnap.data!.where((l) => loanSet.contains(l.id)).length;
            final nTotal = nSch + nLoan;
            return Row(
              children: [
                Expanded(child: _StatTile(value: '$nSch', label: 'Saved', emphasize: false)),
                const SizedBox(width: 10),
                Expanded(child: _StatTile(value: '$nLoan', label: 'Loans', emphasize: false)),
                const SizedBox(width: 10),
                Expanded(child: _StatTile(value: '$nTotal', label: 'Total', emphasize: true)),
              ],
            );
          },
        );
      },
    );
  }
}

class _AnnouncementsSection extends StatefulWidget {
  const _AnnouncementsSection();

  @override
  State<_AnnouncementsSection> createState() => _AnnouncementsSectionState();
}

class _AnnouncementsSectionState extends State<_AnnouncementsSection> {
  /// IDs currently being deleted — disables the button to prevent double-taps.
  final Set<String> _deleting = {};

  static String _formatDate(DateTime? d) {
    if (d == null) return '';
    final l = d.toLocal();
    final mm = l.month.toString().padLeft(2, '0');
    final dd = l.day.toString().padLeft(2, '0');
    final hh = l.hour.toString().padLeft(2, '0');
    final min = l.minute.toString().padLeft(2, '0');
    return '${l.year}-$mm-$dd $hh:$min';
  }

  Future<void> _deleteNotification(String id) async {
    setState(() => _deleting.add(id));
    try {
      await FirestoreService().deleteNotification(id);
    } finally {
      if (mounted) setState(() => _deleting.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: StreamBuilder<List<AppNotification>>(
        stream: FirestoreService().getNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Material(
              color: FinsheColors.card,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Could not load announcements.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return Material(
              color: FinsheColors.card,
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }
          final list = snapshot.data!;
          return Material(
            color: FinsheColors.card,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.campaign_rounded, color: FinsheColors.accentLavender, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Announcements',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Notices from admins appear here for all signed-in users.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  if (list.isEmpty)
                    Text(
                      'No announcements yet.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    )
                  else
                    ...list.map(
                      (n) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    n.title,
                                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: Colors.white),
                                  ),
                                ),
                                // ── Delete button ──────────────────────────────
                                SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: _deleting.contains(n.id)
                                      ? Padding(
                                          padding: const EdgeInsets.all(6),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        )
                                      : IconButton(
                                          padding: EdgeInsets.zero,
                                          icon: Icon(
                                            Icons.delete_outline_rounded,
                                            size: 18,
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                          tooltip: 'Delete',
                                          onPressed: () => _deleteNotification(n.id),
                                        ),
                                ),
                              ],
                            ),
                            if (_formatDate(n.date).isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  _formatDate(n.date),
                                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                ),
                              ),
                            if (n.message.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  n.message,
                                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.92), height: 1.4),
                                ),
                              ),
                            if (n != list.last)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Divider(height: 1, color: FinsheColors.outlineSoft.withValues(alpha: 0.45)),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final bool emphasize;

  const _StatTile({required this.value, required this.label, required this.emphasize});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: FinsheColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FinsheColors.outlineSoft.withValues(alpha: 0.65)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: emphasize ? const Color(0xFFFFD54F) : Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool showChevron;

  const _MenuRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.25),
                ),
              ],
            ),
          ),
          if (showChevron) Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
    if (onTap == null) return child;
    return InkWell(onTap: onTap, child: child);
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
          children: saved
              .map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SavedItemCard(
                    title: s.name,
                    subtitle: s.provider,
                    trailing: s.amount.isNotEmpty ? s.amount : '',
                    icon: Icons.school_rounded,
                  ),
                ),
              )
              .toList(),
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
          children: saved
              .map(
                (l) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SavedItemCard(
                    title: l.name,
                    subtitle: l.provider,
                    trailing: l.interestRate.isNotEmpty ? l.interestRate : '',
                    icon: Icons.account_balance_rounded,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _SavedItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailing;
  final IconData icon;

  const _SavedItemCard({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: FinsheColors.card,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: FinsheColors.accentPurple.withValues(alpha: 0.28),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    softWrap: true,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  if (subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        subtitle,
                        softWrap: true,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  if (trailing.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        trailing,
                        softWrap: true,
                        style: theme.textTheme.bodySmall?.copyWith(color: FinsheColors.accentLavender, fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.bookmark_rounded, color: FinsheColors.accentLavender.withValues(alpha: 0.85), size: 20),
          ],
        ),
      ),
    );
  }
}
