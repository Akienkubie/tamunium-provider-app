/// Mirrors the `dispatches` table — the offer made to a provider
/// before a job is confirmed as theirs.
class DispatchModel {
  final String id;
  final String requestId;
  final String providerId;
  final double? matchScore;
  final double? distanceKm;
  final String dispatchStatus; // pending, offered, accepted, rejected, expired, cancelled
  final DateTime? offerSentAt;

  DispatchModel({
    required this.id,
    required this.requestId,
    required this.providerId,
    this.matchScore,
    this.distanceKm,
    required this.dispatchStatus,
    this.offerSentAt,
  });

  factory DispatchModel.fromJson(Map<String, dynamic> json) {
    return DispatchModel(
      id: json['id'] as String,
      requestId: json['request_id'] as String,
      providerId: json['provider_id'] as String,
      matchScore: (json['match_score'] as num?)?.toDouble(),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      dispatchStatus: json['dispatch_status'] as String? ?? 'pending',
      offerSentAt: json['offer_sent_at'] == null
          ? null
          : DateTime.tryParse(json['offer_sent_at'] as String),
    );
  }
}
