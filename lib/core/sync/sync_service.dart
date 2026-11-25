import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:glass_video_editor/core/models/project.dart';

class SyncService {
  SyncService({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _storage = storage,
        _auth = auth;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  Future<String> signInAnonymously() async {
    final cred = await _auth.signInAnonymously();
    return cred.user!.uid;
  }

  String get uid => _auth.currentUser?.uid ?? 'local';

  Future<void> uploadProject(Project project) async {
    final mediaUrls = <String, String>{};
    for (final clip in project.clips) {
      final ref = _storage.ref('media/$uid/${project.id}/${clip.id}.mp4');
      await ref.putFile(File(clip.path));
      mediaUrls[clip.id] = await ref.getDownloadURL();
    }
    final json = project.toJson();
    json['mediaUrls'] = mediaUrls;
    await _firestore.collection('projects').doc(project.id).set({
      ...json,
      'owner': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Project?> downloadProject(String projectId) async {
    final doc = await _firestore.collection('projects').doc(projectId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    data.remove('owner');
    data.remove('updatedAt');
    return Project.fromJson(Map<String, dynamic>.from(data));
  }

  Stream<List<Project>> watchProjects() {
    return _firestore
        .collection('projects')
        .where('owner', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Project.fromJson(Map<String, dynamic>.from(d.data())))
            .toList());
  }

  Future<String> shareLink(String projectId) async {
    final token = base64Url.encode(utf8.encode('$projectId:$uid'));
    return 'https://glasseditor.app/s/$token';
  }
}
