import 'package:flutter/services.dart';
import 'package:glass_video_editor/core/models/project.dart';

class VideoEngine {
  VideoEngine({MethodChannel? channel, EventChannel? progressChannel})
      : _channel =
            channel ?? const MethodChannel('com.glass.videoeditor/video_engine'),
        _progressChannel = progressChannel ??
            const EventChannel('com.glass.videoeditor/export_progress');

  final MethodChannel _channel;
  final EventChannel _progressChannel;

  Future<List<String>> pickVideos() async {
    final result = await _channel.invokeListMethod<String>('pickVideos');
    return result ?? const [];
  }

  Future<int?> probeDurationMs(String path) async {
    return _channel.invokeMethod<int>('probeDuration', {'path': path});
  }

  Future<void> setFfmpegPath(String path) async {
    await _channel.invokeMethod('setFfmpegPath', {'path': path});
  }

  Future<String?> removeBackground({required String clipId, required String path}) async {
    return _channel.invokeMethod<String>('removeBackground', {'clipId': clipId, 'path': path});
  }

  Future<String?> tts(String text, {String lang = 'en'}) async {
    return _channel.invokeMethod<String>('tts', {'text': text, 'lang': lang});
  }

  Future<List<int>> detectBeats(String path) async {
    final result = await _channel.invokeListMethod<int>('detectBeats', {'path': path});
    return result?.map((e) => e ?? 0).toList() ?? const [];
  }

  Future<List<Map<String, dynamic>>> transcribe(String path) async {
    final result = await _channel.invokeListMethod<Map>('transcribe', {'path': path});
    return result
            ?.map((m) => Map<String, dynamic>.from(m))
            .toList() ??
        const [];
  }

  Stream<double> exportProgress(String jobId) {
    return _progressChannel
        .receiveBroadcastStream({'jobId': jobId})
        .map((event) => (event as num).toDouble());
  }

  Future<String?> export({
    required String jobId,
    required Project project,
    required int width,
    required int height,
    required int fps,
  }) async {
    return _channel.invokeMethod<String>('export', {
      'jobId': jobId,
      'project': project.toJson(),
      'width': width,
      'height': height,
      'fps': fps,
    });
  }
}
