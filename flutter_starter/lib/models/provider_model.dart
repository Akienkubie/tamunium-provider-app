/// Mirrors the `providers` table.
class ProviderModel {
  final String id; // e.g. PRV-001
  final String? userId;
  final String fullName;
  final String? phone;
  final String status;
  final String careerLevel;
  final double overallRating;
  final int jobsCompleted;
  final String currentAvailability; // available, busy, offline, on_leave
  final String verificationStatus;
  final String? photoUrl;

  ProviderModel({
    required this.id,
    this.userId,
    required this.fullName,
    this.phone,
    required this.status,
    required this.careerLevel,
    required this.overallRating,
    required this.jobsCompleted,
    required this.currentAvailability,
    required this.verificationStatus,
    this.photoUrl,
  });

  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    return ProviderModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String?,
      status: json['status'] as String? ?? 'active',
      careerLevel: json['career_level'] as String? ?? 'entry',
      overallRating: (json['overall_rating'] as num?)?.toDouble() ?? 0,
      jobsCompleted: (json['jobs_completed'] as num?)?.toInt() ?? 0,
      currentAvailability:
          json['current_availability'] as String? ?? 'offline',
      verificationStatus: json['verification_status'] as String? ?? 'pending',
      photoUrl: json['photo_url'] as String?,
    );
  }
}
