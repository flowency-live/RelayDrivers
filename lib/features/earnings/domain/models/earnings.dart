/// Earnings models mirroring GET /driver/earnings.
///
/// All money values are integers in minor units (pence).

/// A single completed job's earnings line.
class EarningsJob {
  final String jobId;

  /// Completion date, YYYY-MM-DD.
  final String date;

  /// Base fare in pence.
  final int baseFare;

  /// Reimbursable charges in pence (tolls, parking, waiting time).
  final int charges;

  /// baseFare + charges, in pence.
  final int total;

  const EarningsJob({
    required this.jobId,
    required this.date,
    required this.baseFare,
    required this.charges,
    required this.total,
  });

  factory EarningsJob.fromJson(Map<String, dynamic> json) {
    return EarningsJob(
      jobId: json['jobId'] as String? ?? '',
      date: json['date'] as String? ?? '',
      baseFare: (json['baseFare'] as num?)?.toInt() ?? 0,
      charges: (json['charges'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Earnings summary + per-job breakdown for a date range.
class EarningsSummary {
  /// Inclusive from date, YYYY-MM-DD (may be null when unbounded).
  final String? from;

  /// Inclusive to date, YYYY-MM-DD (may be null when unbounded).
  final String? to;

  final String currency;
  final int totalJobs;
  final int completedJobs;

  /// Gross earnings in pence.
  final int grossEarnings;

  /// Sum of base fares in pence.
  final int baseFares;

  /// Sum of reimbursements in pence.
  final int reimbursements;

  final List<EarningsJob> jobs;

  const EarningsSummary({
    this.from,
    this.to,
    this.currency = 'GBP',
    this.totalJobs = 0,
    this.completedJobs = 0,
    this.grossEarnings = 0,
    this.baseFares = 0,
    this.reimbursements = 0,
    this.jobs = const [],
  });

  factory EarningsSummary.fromJson(Map<String, dynamic> json) {
    final range = json['dateRange'] as Map<String, dynamic>?;
    final jobsData = json['jobs'] as List<dynamic>? ?? [];
    return EarningsSummary(
      from: range?['from'] as String?,
      to: range?['to'] as String?,
      currency: json['currency'] as String? ?? 'GBP',
      totalJobs: (json['totalJobs'] as num?)?.toInt() ?? 0,
      completedJobs: (json['completedJobs'] as num?)?.toInt() ?? 0,
      grossEarnings: (json['grossEarnings'] as num?)?.toInt() ?? 0,
      baseFares: (json['baseFares'] as num?)?.toInt() ?? 0,
      reimbursements: (json['reimbursements'] as num?)?.toInt() ?? 0,
      jobs: jobsData
          .map((j) => EarningsJob.fromJson(j as Map<String, dynamic>))
          .toList(),
    );
  }
}
