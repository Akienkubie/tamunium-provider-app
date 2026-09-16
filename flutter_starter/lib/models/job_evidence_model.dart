class JobEvidenceModel {
  final String id;
  final String jobId;
  final String storagePath;
  final String evidenceType;
  final String? caption;
  final DateTime createdAt;
  final String? signedUrl;

  const JobEvidenceModel({
    required this.id,
    required this.jobId,
    required this.storagePath,
    required this.evidenceType,
    required this.createdAt,
    this.caption,
    this.signedUrl,
  });

  factory JobEvidenceModel.fromJson(Map<String, dynamic> json, {String? signedUrl}) {
    return JobEvidenceModel(
      id: json['id'] as String,
      jobId: json['job_id'] as String,
      storagePath: json['storage_path'] as String,
      evidenceType: json['evidence_type'] as String? ?? 'completion',
      caption: json['caption'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      signedUrl: signedUrl,
    );
  }
}
