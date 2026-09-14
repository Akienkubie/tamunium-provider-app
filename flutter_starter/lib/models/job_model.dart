/// Mirrors the `jobs` table.
class JobModel {
  final String id; // e.g. JOB-001
  final String? requestId;
  final String? jobType;
  final String status; // offered, accepted, in_progress, completed, cancelled, disputed
  final String priority; // low, normal, high, emergency
  final String? serviceCategoryId;
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;
  final DateTime? actualStart;
  final DateTime? actualEnd;
  final String? assignedProviderId;
  final String? estateId;
  final String? pricingType;
  final double? rateAmount;
  final String? providerNotes;

  JobModel({
    required this.id,
    this.requestId,
    this.jobType,
    required this.status,
    required this.priority,
    this.serviceCategoryId,
    this.scheduledStart,
    this.scheduledEnd,
    this.actualStart,
    this.actualEnd,
    this.assignedProviderId,
    this.estateId,
    this.pricingType,
    this.rateAmount,
    this.providerNotes,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseTs(dynamic v) => v == null ? null : DateTime.tryParse(v as String);
    return JobModel(
      id: json['id'] as String,
      requestId: json['request_id'] as String?,
      jobType: json['job_type'] as String?,
      status: json['status'] as String? ?? 'offered',
      priority: json['priority'] as String? ?? 'normal',
      serviceCategoryId: json['service_category_id'] as String?,
      scheduledStart: parseTs(json['scheduled_start']),
      scheduledEnd: parseTs(json['scheduled_end']),
      actualStart: parseTs(json['actual_start']),
      actualEnd: parseTs(json['actual_end']),
      assignedProviderId: json['assigned_provider_id'] as String?,
      estateId: json['estate_id'] as String?,
      pricingType: json['pricing_type'] as String?,
      rateAmount: (json['rate_amount'] as num?)?.toDouble(),
      providerNotes: json['provider_notes'] as String?,
    );
  }
}
