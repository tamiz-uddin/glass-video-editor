import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class AiService {
  AiService({required this.baseUrl, this.apiKey});

  final String baseUrl;
  final String? apiKey;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (apiKey != null) 'Authorization': 'Bearer $apiKey',
      };

  Future<String?> enhance({
    required String jobId,
    required String videoPath,
    required String op,
  }) async {
    final uri = Uri.parse('$baseUrl/v1/enhance');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(_headers)
      ..fields['jobId'] = jobId
      ..fields['op'] = op
      ..files.add(await http.MultipartFile.fromPath('video', videoPath));
    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode != 200) return null;
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    return decoded['outputPath'] as String?;
  }

  Future<bool> upscale({required String jobId, required String videoPath}) =>
      _postJob(jobId: jobId, videoPath: videoPath, op: 'upscale');

  Future<bool> denoise({required String jobId, required String videoPath}) =>
      _postJob(jobId: jobId, videoPath: videoPath, op: 'denoise');

  Future<bool> enhanceVoice({required String jobId, required String videoPath}) =>
      _postJob(jobId: jobId, videoPath: videoPath, op: 'voice_enhance');

  Future<bool> _postJob({
    required String jobId,
    required String videoPath,
    required String op,
  }) async {
    final exists = await File(videoPath).exists();
    if (!exists) return false;
    final res = await enhance(jobId: jobId, videoPath: videoPath, op: op);
    return res != null;
  }
}
