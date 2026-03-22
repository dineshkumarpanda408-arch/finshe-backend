import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/loan_model.dart';
import '../services/firestore_service.dart';
import '../theme/finshe_theme.dart';
import '../utils/url_utils.dart';

class LoansScreen extends StatelessWidget {
  const LoansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: FinsheColors.bg,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  FinsheColors.accentPurple.withValues(alpha: 0.95),
                  const Color(0xFF4C1D95),
                  FinsheColors.accentPink.withValues(alpha: 0.55),
                ],
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: FinsheColors.accentPink.withValues(alpha: 0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Education Loans',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Fuel Your Dreams',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Low-interest financial support for your education journey.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<LoanModel>>(
              stream: FirestoreService().getLoansStream(),
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
                final list = snapshot.data!;
                if (list.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No loans available yet.',
                        style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: list.length,
                  itemBuilder: (context, i) => _LoanCard(loan: list[i]),
                );
              },
            ),
          ),
        ],
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: FinsheColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: FinsheColors.outlineSoft.withValues(alpha: 0.65)),
        ),
        clipBehavior: Clip.antiAlias,
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
                      color: FinsheColors.accentPurple.withValues(alpha: 0.35),
                    ),
                    child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loan.name,
                          softWrap: true,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        if (loan.provider.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              loan.provider,
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
                    onPressed: () => app.toggleSavedLoan(loan.id),
                  ),
                ],
              ),
              if (loan.interestRate.isNotEmpty || loan.maxAmount.isNotEmpty) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (loan.interestRate.isNotEmpty)
                      Expanded(
                        child: _MetricChip(
                          label: 'Interest Rate',
                          value: loan.interestRate,
                          valueColor: FinsheColors.emerald,
                        ),
                      ),
                    if (loan.interestRate.isNotEmpty && loan.maxAmount.isNotEmpty) const SizedBox(width: 10),
                    if (loan.maxAmount.isNotEmpty)
                      Expanded(
                        child: _MetricChip(
                          label: 'Max Amount',
                          value: loan.maxAmount,
                          valueColor: Colors.white,
                        ),
                      ),
                  ],
                ),
              ],
              if (loan.eligibility.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: FinsheColors.outlineSoft.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          loan.eligibility,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (loan.country != null && loan.country!.isNotEmpty) _row(theme, 'Country', loan.country!),
              if (loan.loanType != null && loan.loanType!.isNotEmpty) _row(theme, 'Loan Type', loan.loanType!),
              if (loan.repaymentPeriod != null && loan.repaymentPeriod!.isNotEmpty) _row(theme, 'Repayment', loan.repaymentPeriod!),
              if (loan.collateralRequired != null && loan.collateralRequired!.isNotEmpty) _row(theme, 'Collateral', loan.collateralRequired!),
              if (loan.insuranceRequired != null && loan.insuranceRequired!.isNotEmpty) _row(theme, 'Insurance', loan.insuranceRequired!),
              if (loan.margin != null && loan.margin!.isNotEmpty) _row(theme, 'Margin', loan.margin!),
              if (loan.processingFee != null && loan.processingFee!.isNotEmpty) _row(theme, 'Processing fee', loan.processingFee!),
              if (loan.applicationLink.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: () => openExternalHttpUrl(loan.applicationLink),
                      child: Text(
                        'Apply: ${loan.applicationLink}',
                        softWrap: true,
                        style: theme.textTheme.bodySmall?.copyWith(color: FinsheColors.accentLavender, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _MetricChip({required this.label, required this.value, required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: FinsheColors.accentLavender.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FinsheColors.outlineSoft.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            softWrap: true,
            style: TextStyle(color: valueColor, fontWeight: FontWeight.w800, fontSize: 14, height: 1.25),
          ),
        ],
      ),
    );
  }
}
