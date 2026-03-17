import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/loan_model.dart';
import '../services/firestore_service.dart';

class LoansScreen extends StatelessWidget {
  const LoansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loans')),
      body: StreamBuilder<List<LoanModel>>(
        stream: FirestoreService().getLoansStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snapshot.data!;
          if (list.isEmpty) {
            return const Center(child: Text('No loans available yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, i) => _LoanCard(loan: list[i]),
          );
        },
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  final LoanModel loan;

  const _LoanCard({required this.loan});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final saved = app.isLoanSaved(loan.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    loan.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
                  onPressed: () => app.toggleSavedLoan(loan.id),
                ),
              ],
            ),
            if (loan.provider.isNotEmpty) _row('Provider', loan.provider),
            if (loan.interestRate.isNotEmpty) _row('Interest Rate', loan.interestRate),
            if (loan.maxAmount.isNotEmpty) _row('Max Amount', loan.maxAmount),
            if (loan.eligibility.isNotEmpty) _row('Eligibility', loan.eligibility),
            if (loan.country != null && loan.country!.isNotEmpty) _row('Country', loan.country!),
            if (loan.loanType != null) _row('Loan Type', loan.loanType!),
            if (loan.repaymentPeriod != null) _row('Repayment', loan.repaymentPeriod!),
            if (loan.applicationLink.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Apply: ${loan.applicationLink}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
              ),
          ],
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
          SizedBox(width: 100, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
