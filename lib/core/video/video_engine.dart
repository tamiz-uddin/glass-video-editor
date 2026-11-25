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
