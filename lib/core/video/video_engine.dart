import 'package:flutter/services.dart';
import 'package:glass_video_editor/core/models/clip.dart';

class VideoEngine {
  VideoEngine({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('com.glass.videoeditor/video_engine');

  final MethodChannel _channel;

  Future<String?> pickVideo() async {
    final result = await _channel.invokeMethod<String>('pickVideo');
    return result;
  }

  Future<int?> probeDurationMs(String path) async {
    final result = await _channel.invokeMethod<int>('probeDuration', {'path': path});
    return result;
  }

  Future<String?> export({
    required String projectId,
    required List<Clip> clips,
    required int width,
    required int height,
    required int fps,
  }) async {
    final result = await _channel.invokeMethod<String>('export', {
      'projectId': projectId,
      'width': width,
      'height': height,
      'fps': fps,
      'clips': clips.map((c) => c.toJson()).toList(),
    });
    return result;
  }
}
