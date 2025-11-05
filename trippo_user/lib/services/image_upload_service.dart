import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

/// Image Upload Service
/// Handles uploading images to Firebase Storage for chat, milestones, etc.

class ImageUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  /// Upload a chat image (from user message)
  Future<String> uploadChatImage(String localPath) async {
    final userId = _auth.currentUser?.uid ?? 'anonymous';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uniqueId = _uuid.v4();
    final extension = path.extension(localPath);

    final storageRef = _storage
        .ref()
        .child('chat_images')
        .child(userId)
        .child('${timestamp}_$uniqueId$extension');

    return await _uploadFile(localPath, storageRef);
  }

  /// Upload a milestone image (provider's photo proof)
  Future<String> uploadMilestoneImage(
    String localPath,
    String serviceRequestId,
    String milestoneType,
  ) async {
    final providerId = _auth.currentUser?.uid ?? 'unknown';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uniqueId = _uuid.v4();
    final extension = path.extension(localPath);

    final storageRef = _storage
        .ref()
        .child('milestone_images')
        .child(serviceRequestId)
        .child('${milestoneType}_${timestamp}_$uniqueId$extension');

    return await _uploadFile(localPath, storageRef);
  }

  /// Upload a service request image (issue documentation)
  Future<String> uploadServiceRequestImage(
    String localPath,
    String serviceRequestId,
  ) async {
    final userId = _auth.currentUser?.uid ?? 'anonymous';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uniqueId = _uuid.v4();
    final extension = path.extension(localPath);

    final storageRef = _storage
        .ref()
        .child('service_request_images')
        .child(serviceRequestId)
        .child('${timestamp}_$uniqueId$extension');

    return await _uploadFile(localPath, storageRef);
  }

  /// Upload a profile image
  Future<String> uploadProfileImage(String localPath) async {
    final userId = _auth.currentUser?.uid ?? 'anonymous';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = path.extension(localPath);

    final storageRef = _storage
        .ref()
        .child('profile_images')
        .child('$userId$extension');

    return await _uploadFile(localPath, storageRef);
  }

  /// Generic upload method with progress callback
  Future<String> _uploadFile(
    String localPath,
    Reference storageRef, {
    Function(double)? onProgress,
  }) async {
    try {
      final file = File(localPath);

      if (!await file.exists()) {
        throw ImageUploadException('File not found: $localPath');
      }

      // Create upload task
      final uploadTask = storageRef.putFile(
        file,
        SettableMetadata(
          contentType: _getContentType(localPath),
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
            'uploadedBy': _auth.currentUser?.uid ?? 'anonymous',
          },
        ),
      );

      // Monitor progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress?.call(progress);
      });

      // Wait for completion
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } on FirebaseException catch (e) {
      throw ImageUploadException('Firebase error: ${e.message}');
    } catch (e) {
      throw ImageUploadException('Upload failed: $e');
    }
  }

  /// Delete an image by URL
  Future<void> deleteImage(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } on FirebaseException catch (e) {
      throw ImageUploadException('Delete failed: ${e.message}');
    }
  }

  /// Delete all images in a service request
  Future<void> deleteServiceRequestImages(String serviceRequestId) async {
    try {
      final ref = _storage.ref().child('service_request_images/$serviceRequestId');
      final ListResult result = await ref.listAll();

      for (final item in result.items) {
        await item.delete();
      }
    } on FirebaseException catch (e) {
      throw ImageUploadException('Batch delete failed: ${e.message}');
    }
  }

  /// Get content type from file extension
  String _getContentType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  /// Compress and upload (for large images)
  Future<String> uploadCompressedImage(
    String localPath,
    Reference storageRef, {
    int maxWidth = 1920,
    int maxHeight = 1920,
    int quality = 85,
  }) async {
    // TODO: Add image compression using flutter_image_compress
    // For now, just upload directly
    return await _uploadFile(localPath, storageRef);
  }
}

class ImageUploadException implements Exception {
  final String message;
  ImageUploadException(this.message);

  @override
  String toString() => message;
}
