import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/job_evidence_model.dart';

class JobEvidenceRepository {
  final SupabaseClient _client;
  JobEvidenceRepository(this._client);

  Future<JobEvidenceModel> uploadCompletionPhoto({
    required String jobId,
    required XFile file,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('You must be signed in.');
    final bytes = await file.readAsBytes();
    final extension = file.name.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
    final path = '${user.id}/$jobId/${DateTime.now().millisecondsSinceEpoch}.$extension';
    final storage = _client.storage.from('job-evidence');
    await storage.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: 'image/$extension', upsert: false),
    );
    final row = await _client.from('job_evidence').insert({
      'job_id': jobId,
      'uploaded_by': user.id,
      'evidence_type': 'completion',
      'storage_path': path,
    }).select().single();
    final signedUrl = await storage.createSignedUrl(path, 3600);
    return JobEvidenceModel.fromJson(row, signedUrl: signedUrl);
  }

  Future<List<JobEvidenceModel>> listForJob(String jobId) async {
    final rows = await _client
        .from('job_evidence')
        .select()
        .eq('job_id', jobId)
        .order('created_at');
    final storage = _client.storage.from('job-evidence');
    final evidence = <JobEvidenceModel>[];
    for (final row in rows) {
      final path = row['storage_path'] as String;
      final signedUrl = await storage.createSignedUrl(path, 3600);
      evidence.add(JobEvidenceModel.fromJson(row, signedUrl: signedUrl));
    }
    return evidence;
  }
}
