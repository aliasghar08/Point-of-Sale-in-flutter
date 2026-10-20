import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Service managing Firebase Cloud Storage uploads for product images,
/// receipts, branding assets, and user avatars under the Blaze plan.
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  FirebaseStorage get _storage => FirebaseStorage.instance;

  /// Detect MIME content type from file extension
  String _getContentType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }

  /// Uploads a product catalog image to Firebase Cloud Storage.
  /// 
  /// Path: `businesses/{businessId}/products/{productId}/{timestamp}_{filename}`
  /// Returns the permanent public download URL, or null if upload fails.
  Future<String?> uploadProductImage({
    required String businessId,
    required String productId,
    required File file,
  }) async {
    try {
      if (!file.existsSync()) {
        debugPrint('⚠️ StorageService: Image file does not exist at ${file.path}');
        return null;
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final path = 'businesses/$businessId/products/$productId/$fileName';
      final ref = _storage.ref().child(path);

      final metadata = SettableMetadata(
        contentType: _getContentType(file.path),
        customMetadata: {
          'businessId': businessId,
          'productId': productId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      debugPrint('🚀 StorageService: Uploading product image to $path...');
      final uploadTask = await ref.putFile(file, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      debugPrint('✅ StorageService: Image uploaded successfully! URL: $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e) {
      debugPrint('❌ StorageService: Firebase Storage error: [${e.code}] ${e.message}');
      return null;
    } catch (e) {
      debugPrint('❌ StorageService: Unexpected upload error: $e');
      return null;
    }
  }

  /// Uploads business logo / receipt header image
  Future<String?> uploadStoreLogo({
    required String businessId,
    required File file,
  }) async {
    try {
      if (!file.existsSync()) return null;

      final fileName = 'logo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'businesses/$businessId/branding/$fileName';
      final ref = _storage.ref().child(path);

      final metadata = SettableMetadata(
        contentType: _getContentType(file.path),
        customMetadata: {
          'businessId': businessId,
          'type': 'store_logo',
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final uploadTask = await ref.putFile(file, metadata);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('❌ StorageService: Error uploading store logo: $e');
      return null;
    }
  }

  /// Uploads user profile avatar
  Future<String?> uploadUserAvatar({
    required String userId,
    required File file,
  }) async {
    try {
      if (!file.existsSync()) return null;

      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'users/$userId/avatar/$fileName';
      final ref = _storage.ref().child(path);

      final metadata = SettableMetadata(
        contentType: _getContentType(file.path),
        customMetadata: {
          'userId': userId,
          'type': 'user_avatar',
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final uploadTask = await ref.putFile(file, metadata);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('❌ StorageService: Error uploading avatar: $e');
      return null;
    }
  }

  /// Deletes an image from Cloud Storage using its download URL
  Future<bool> deleteImageByUrl(String imageUrl) async {
    try {
      if (!imageUrl.contains('firebasestorage.googleapis.com')) {
        return false;
      }
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      debugPrint('🗑️ StorageService: Deleted file from Cloud Storage: $imageUrl');
      return true;
    } catch (e) {
      debugPrint('⚠️ StorageService: Failed to delete image ($imageUrl): $e');
      return false;
    }
  }
}
