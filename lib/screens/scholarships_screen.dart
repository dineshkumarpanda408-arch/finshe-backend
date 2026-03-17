import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_provider.dart';
import '../models/scholarship_model.dart';
import '../services/firestore_service.dart';

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
  String? _filterType; // Government / Private

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ScholarshipModel> _filter(List<ScholarshipModel> list) {
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
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scholarships'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search scholarships...',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ScholarshipModel>>(
              stream: FirestoreService().getScholarshipsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = _filter(snapshot.data!);
                if (list.isEmpty) {
                  return const Center(child: Text('No scholarships match your filters.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            return Padding(
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

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final saved = app.isScholarshipSaved(scholarship.id);
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          if (scholarship.applicationLink.isNotEmpty) _openUrl(scholarship.applicationLink);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      scholarship.name,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, height: 1.2),
                    ),
                  ),
                  IconButton(
                    icon: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: theme.colorScheme.primary),
                    onPressed: () => app.toggleSavedScholarship(scholarship.id),
                  ),
                ],
              ),
              if (scholarship.provider.isNotEmpty) _row('Provider', scholarship.provider),
              if (scholarship.eligibility.isNotEmpty) _row('Eligibility', scholarship.eligibility),
              if (scholarship.amount.isNotEmpty) _row('Amount', scholarship.amount),
              if (scholarship.deadline.isNotEmpty) _row('Deadline', scholarship.deadline),
              if (scholarship.country.isNotEmpty) _row('Country', scholarship.country),
              if (scholarship.fieldOfStudy.isNotEmpty) _row('Field', scholarship.fieldOfStudy),
              if (scholarship.applicationLink.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: InkWell(
                    onTap: () => _openUrl(scholarship.applicationLink),
                    child: Row(
                      children: [
                        Icon(Icons.open_in_new_rounded, size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                        Expanded(child: Text('Apply here', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
