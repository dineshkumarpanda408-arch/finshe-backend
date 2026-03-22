import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/scholarship_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../theme/finshe_theme.dart';
import '../utils/url_utils.dart';

class ScholarshipsScreen extends StatefulWidget {
  const ScholarshipsScreen({super.key});

  @override
  State<ScholarshipsScreen> createState() => _ScholarshipsScreenState();
}

class _ScholarshipsScreenState extends State<ScholarshipsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _filterDegree;
  String? _filterCountry;
  String? _filterField;
  String? _filterType;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesUserPreferences(ScholarshipModel s, UserPreferences? p) {
    if (p == null) return true;
    if (p.country != null && p.country!.trim().isNotEmpty) {
      final t = p.country!.trim().toLowerCase();
      final hay = '${s.country} ${s.eligibility} ${s.name} ${s.fieldOfStudy}'.toLowerCase();
      if (!hay.contains(t)) return false;
    }
    if (p.degree != null && p.degree!.trim().isNotEmpty) {
      final t = p.degree!.trim().toLowerCase();
      final hay = '${s.fieldOfStudy} ${s.eligibility} ${s.name}'.toLowerCase();
      if (!hay.contains(t)) return false;
    }
    if (p.fieldOfStudy != null && p.fieldOfStudy!.trim().isNotEmpty) {
      final t = p.fieldOfStudy!.trim().toLowerCase();
      final hay = '${s.fieldOfStudy} ${s.eligibility} ${s.name}'.toLowerCase();
      if (!hay.contains(t)) return false;
    }
    return true;
  }

  List<ScholarshipModel> _filter(List<ScholarshipModel> list, UserPreferences? prefs) {
    var out = list;
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      out = out.where((s) {
        return s.name.toLowerCase().contains(q) ||
            s.provider.toLowerCase().contains(q) ||
            s.country.toLowerCase().contains(q) ||
            s.fieldOfStudy.toLowerCase().contains(q) ||
            s.eligibility.toLowerCase().contains(q) ||
            s.type.toLowerCase().contains(q);
      }).toList();
    }
    if (_filterDegree != null && _filterDegree!.isNotEmpty) {
      final term = _filterDegree!.toLowerCase();
      out = out.where((s) => s.fieldOfStudy.toLowerCase().contains(term) || s.eligibility.toLowerCase().contains(term) || s.name.toLowerCase().contains(term)).toList();
    }
    if (_filterCountry != null && _filterCountry!.isNotEmpty) {
      final term = _filterCountry!.toLowerCase();
      out = out.where((s) => s.country.toLowerCase().contains(term)).toList();
    }
    if (_filterField != null && _filterField!.isNotEmpty) {
      final term = _filterField!.toLowerCase();
      out = out.where((s) => s.fieldOfStudy.toLowerCase().contains(term)).toList();
    }
    if (_filterType != null && _filterType!.isNotEmpty) {
      final term = _filterType!.toLowerCase();
      out = out.where((s) => s.type.toLowerCase().contains(term) || s.provider.toLowerCase().contains(term)).toList();
    }
    out = out.where((s) => _matchesUserPreferences(s, prefs)).toList();
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefs = context.watch<AppProvider>().currentUser?.preferences;
    return Scaffold(
      backgroundColor: FinsheColors.bg,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: FinsheColors.gradientHeader,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: FinsheColors.accentPurple.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scholarships',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Empowering your education journey',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Material(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: const CircleBorder(),
                          child: IconButton(
                            icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
                            onPressed: () => _showFilterSheet(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search scholarships, majors...',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
                        prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.75)),
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.22),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ScholarshipModel>>(
              stream: FirestoreService().getScholarshipsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = _filter(snapshot.data!, prefs);
                if (list.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No scholarships match your filters.',
                        style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    return _ScholarshipCard(scholarship: list[i]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filters', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _filterDegree,
                    decoration: const InputDecoration(labelText: 'Degree / Field'),
                    items: ['Any', 'Undergraduate', 'Postgraduate', 'Doctorate', 'Doctrate', 'Engineering', 'MBA'].map((s) => DropdownMenuItem(value: s == 'Any' ? null : s, child: Text(s))).toList(),
                    onChanged: (v) => setModalState(() => _filterDegree = v),
                  ),
                  DropdownButtonFormField<String>(
                    value: _filterCountry,
                    decoration: const InputDecoration(labelText: 'Country'),
                    items: ['Any', 'India', 'USA', 'Germany', 'UK', 'Canada', 'Australia'].map((s) => DropdownMenuItem(value: s == 'Any' ? null : s, child: Text(s))).toList(),
                    onChanged: (v) => setModalState(() => _filterCountry = v),
                  ),
                  DropdownButtonFormField<String>(
                    value: _filterType,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: ['Any', 'Government', 'Private'].map((s) => DropdownMenuItem(value: s == 'Any' ? null : s, child: Text(s))).toList(),
                    onChanged: (v) => setModalState(() => _filterType = v),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _filterDegree = null;
                            _filterCountry = null;
                            _filterField = null;
                            _filterType = null;
                          });
                          setState(() {
                            _filterDegree = null;
                            _filterCountry = null;
                            _filterField = null;
                            _filterType = null;
                          });
                          Navigator.pop(ctx);
                        },
                        child: const Text('Clear'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () {
                          setState(() {}); // Refresh list with current filter values
                          Navigator.pop(ctx);
                        },
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}


class _ScholarshipCard extends StatelessWidget {
  final ScholarshipModel scholarship;

  const _ScholarshipCard({required this.scholarship});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final saved = app.isScholarshipSaved(scholarship.id);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: FinsheColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: FinsheColors.outlineSoft.withValues(alpha: 0.65)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            if (scholarship.applicationLink.isNotEmpty) openExternalHttpUrl(scholarship.applicationLink);
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          colors: [
                            FinsheColors.accentPurple.withValues(alpha: 0.45),
                            FinsheColors.accentPink.withValues(alpha: 0.35),
                          ],
                        ),
                      ),
                      child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            scholarship.name,
                            softWrap: true,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          if (scholarship.provider.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                scholarship.provider,
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        color: FinsheColors.accentLavender,
                      ),
                      onPressed: () => app.toggleSavedScholarship(scholarship.id),
                    ),
                  ],
                ),
                if (scholarship.amount.isNotEmpty || scholarship.deadline.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (scholarship.amount.isNotEmpty) ...[
                        _InfoChip(
                          icon: Icons.payments_rounded,
                          label: scholarship.amount,
                          foreground: FinsheColors.accentLavender,
                        ),
                      ],
                      if (scholarship.amount.isNotEmpty && scholarship.deadline.isNotEmpty) const SizedBox(height: 8),
                      if (scholarship.deadline.isNotEmpty)
                        _InfoChip(
                          icon: Icons.calendar_today_rounded,
                          label: scholarship.deadline,
                          foreground: FinsheColors.accentPink,
                        ),
                    ],
                  ),
                ],
                if (scholarship.eligibility.isNotEmpty) _row(context, 'Eligibility', scholarship.eligibility),
                if (scholarship.country.isNotEmpty) _row(context, 'Country', scholarship.country),
                if (scholarship.fieldOfStudy.isNotEmpty) _row(context, 'Field', scholarship.fieldOfStudy),
                if (scholarship.applicationLink.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            FinsheColors.accentPurple,
                            FinsheColors.accentPurple.withValues(alpha: 0.85),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: FinsheColors.accentPurple.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => openExternalHttpUrl(scholarship.applicationLink),
                        child: const Text('Apply Now', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              '$label:',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color foreground;

  const _InfoChip({required this.icon, required this.label, required this.foreground});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: FinsheColors.cardMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FinsheColors.outlineSoft.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 16, color: foreground),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              softWrap: true,
              style: TextStyle(color: foreground, fontWeight: FontWeight.w600, fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
