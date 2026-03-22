/// Loan model. Firestore loans use snake_case (interest_rate, max_loan_amount, etc.).
class LoanModel {
  final String id;
  final String name;
  final String provider;
  final String interestRate;
  final String maxAmount;
  final String eligibility;
  final String applicationLink;
  final String? country;
  final String? loanType;
  final String? collateralRequired;
  final String? insuranceRequired;
  final String? margin;
  final String? processingFee;
  final String? repaymentPeriod;

  const LoanModel({
    required this.id,
    required this.name,
    this.provider = '',
    this.interestRate = '',
    this.maxAmount = '',
    this.eligibility = '',
    this.applicationLink = '',
    this.country,
    this.loanType,
    this.collateralRequired,
    this.insuranceRequired,
    this.margin,
    this.processingFee,
    this.repaymentPeriod,
  });

  factory LoanModel.fromFirestore(String id, Map<String, dynamic> data) {
    String getStr(String key, [String altKey = '']) {
      final v = data[key] ?? data[altKey];
      if (v == null) return '';
      return v.toString().trim();
    }

    return LoanModel(
      id: id,
      name: getStr('name', 'Name').isEmpty ? id : getStr('name', 'Name'),
      provider: getStr('provider', 'Provider'),
      interestRate: getStr('interest_rate', 'interestRate'),
      maxAmount: getStr('max_loan_amount', 'maxAmount'),
      eligibility: getStr('eligibility', 'Eligibility'),
      applicationLink: getStr('applicationLink', 'Link'),
      country: getStr('country', 'Country').isEmpty ? null : getStr('country', 'Country'),
      loanType: getStr('loan_type', 'loanType').isEmpty ? null : getStr('loan_type', 'loanType'),
      collateralRequired: getStr('collateral_required').isEmpty ? null : getStr('collateral_required'),
      insuranceRequired: getStr('insurance_required').isEmpty ? null : getStr('insurance_required'),
      margin: getStr('margin').isEmpty ? null : getStr('margin'),
      processingFee: getStr('processing_fee').isEmpty ? null : getStr('processing_fee'),
      repaymentPeriod: getStr('repayment_period').isEmpty ? null : getStr('repayment_period'),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'provider': provider,
      'interest_rate': interestRate,
      'max_loan_amount': maxAmount,
      'eligibility': eligibility,
      'applicationLink': applicationLink,
      'Link': applicationLink,
      if (country != null && country!.isNotEmpty) 'country': country,
      if (country != null && country!.isNotEmpty) 'Country': country,
      if (loanType != null && loanType!.isNotEmpty) 'loan_type': loanType,
      if (collateralRequired != null && collateralRequired!.isNotEmpty) 'collateral_required': collateralRequired,
      if (insuranceRequired != null && insuranceRequired!.isNotEmpty) 'insurance_required': insuranceRequired,
      if (margin != null && margin!.isNotEmpty) 'margin': margin,
      if (processingFee != null && processingFee!.isNotEmpty) 'processing_fee': processingFee,
      if (repaymentPeriod != null && repaymentPeriod!.isNotEmpty) 'repayment_period': repaymentPeriod,
    };
  }
}
