import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pos/models/user.dart';
import 'package:pos/services/firebase_service.dart';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // ✅ UPDATED: Sign up perfectly synced with FirebaseService architecture
  Future<AppUser?> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    required String phone,
    required String storeName,
  }) async {
    try {
      // Step 1: Create Firebase Auth user
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user == null) throw Exception('Failed to create user');

      final uid = user.uid;

      // Update Firebase Auth profile
      await user.updateDisplayName(name);

      // ✅ Step 2: Determine if creating or joining a business
      String businessId;
      DocumentReference businessRef;

      if (role == 'owner') {
        // Owner creates a brand new business
        final businessData = {
          'name': storeName,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'ownerId': uid,
          'isActive': true,
        };

        businessRef = await _firestore
            .collection('businesses')
            .add(businessData);
        businessId = businessRef.id;

        // Create default business settings ONLY for the new business
        await businessRef.collection('settings').doc('store_settings').set({
          'currency': 'PKR',
          'country': 'Pakistan',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Manager/Worker joins an existing business
        final businessQuery = await _firestore
            .collection('businesses')
            .where('name', isEqualTo: storeName)
            .limit(1)
            .get();

        if (businessQuery.docs.isEmpty) {
          // If they somehow bypass the UI validation, catch it here
          throw Exception(
            'Business "$storeName" not found. Please check spelling or contact the owner.',
          );
        }

        businessId = businessQuery.docs.first.id;
        businessRef = _firestore.collection('businesses').doc(businessId);
      }

      // Step 3: Create AppUser object
      AppUser appUser = AppUser(
        id: uid,
        email: email,
        name: name,
        role: role,
        phone: phone,
        businessId: businessId,
        createdAt: DateTime.now(),
        isActive: true,
      );

      // Step 4: Add to business's MEMBERS sub-collection
      await businessRef.collection('members').doc(uid).set({
        'id': uid,
        'name': name,
        'email': email,
        'role': role,
        'phone': phone,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Step 5: Add to ROOT users collection (FirebaseService relies on this for fast startup)
      await _firestore.collection('users').doc(uid).set({
        'businessId': businessId,
        'role': role,
        'email': email,
        'name': name,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Step 6: Add to lightweight lookup collection
      await _firestore.collection('userBusinessLookup').doc(uid).set({
        'businessId': businessId,
        'role': role,
        'email': email,
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return appUser;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ✅ UPDATED: Sign in using lookup collection and MEMBERS sub-collection
  Future<AppUser?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user == null) throw Exception('Failed to sign in');

      final uid = user.uid;

      // Get business ID from lookup collection with self-healing fallbacks
      String? businessId;
      final lookupDoc = await _firestore
          .collection('userBusinessLookup')
          .doc(uid)
          .get();

      if (lookupDoc.exists) {
        final lookupData = lookupDoc.data() as Map<String, dynamic>;
        businessId = lookupData['businessId'] as String?;
      }

      // Fallback 1: Check root users collection
      if (businessId == null || businessId.isEmpty) {
        final rootUserDoc = await _firestore.collection('users').doc(uid).get();
        if (rootUserDoc.exists) {
          businessId = rootUserDoc.data()?['businessId'] as String?;
        }
      }

      // Fallback 2: Check if user owns a business
      if (businessId == null || businessId.isEmpty) {
        final ownedBizQuery = await _firestore
            .collection('businesses')
            .where('ownerId', isEqualTo: uid)
            .limit(1)
            .get();
        if (ownedBizQuery.docs.isNotEmpty) {
          businessId = ownedBizQuery.docs.first.id;
        }
      }

      if (businessId == null || businessId.isEmpty) {
        throw Exception('No store or business linked to this account.');
      }

      // Get user data from business's MEMBERS sub-collection
      final memberRef = _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('members')
          .doc(uid);
      var userDoc = await memberRef.get();

      // Self-heal member document if missing for owner
      if (!userDoc.exists) {
        final bizDoc = await _firestore.collection('businesses').doc(businessId).get();
        if (bizDoc.exists && bizDoc.data()?['ownerId'] == uid) {
          await memberRef.set({
            'id': uid,
            'name': user.displayName ?? 'Store Owner',
            'email': user.email ?? '',
            'role': 'owner',
            'phone': user.phoneNumber ?? '',
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          userDoc = await memberRef.get();
        } else {
          throw Exception('User data not found in business.');
        }
      }

      // Self-heal lookup document if missing
      if (!lookupDoc.exists) {
        await _firestore.collection('userBusinessLookup').doc(uid).set({
          'businessId': businessId,
          'role': userDoc.data()?['role'] ?? 'owner',
          'email': user.email ?? '',
          'name': user.displayName ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      var data = userDoc.data() as Map<String, dynamic>;

      // Check if user is active
      if (data['isActive'] == false) {
        await _auth.signOut();
        throw Exception('Account has been deactivated by the owner');
      }

      data['businessId'] = businessId;

      return AppUser.fromMap(data, uid);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      debugPrint('✅ Password reset email sent to $email');
    } catch (e) {
      debugPrint('❌ Password reset error: $e');
      throw _handleAuthError(e);
    }
  }

  // ✅ UPDATED: Get current user data from MEMBERS sub-collection with self-healing
  Future<AppUser?> getCurrentUserData() async {
    User? user = _auth.currentUser;
    if (user == null) return null;

    try {
      final uid = user.uid;

      String? businessId;
      final lookupDoc = await _firestore
          .collection('userBusinessLookup')
          .doc(uid)
          .get();

      if (lookupDoc.exists) {
        final lookupData = lookupDoc.data() as Map<String, dynamic>;
        businessId = lookupData['businessId'] as String?;
      }

      if (businessId == null || businessId.isEmpty) {
        final rootUserDoc = await _firestore.collection('users').doc(uid).get();
        if (rootUserDoc.exists) {
          businessId = rootUserDoc.data()?['businessId'] as String?;
        }
      }

      if (businessId == null || businessId.isEmpty) {
        final ownedBiz = await _firestore
            .collection('businesses')
            .where('ownerId', isEqualTo: uid)
            .limit(1)
            .get();
        if (ownedBiz.docs.isNotEmpty) {
          businessId = ownedBiz.docs.first.id;
        }
      }

      if (businessId == null || businessId.isEmpty) return null;

      // Get from MEMBERS
      final userDoc = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('members')
          .doc(uid)
          .get();

      if (!userDoc.exists) return null;

      var data = userDoc.data() as Map<String, dynamic>;
      data['businessId'] = businessId;

      return AppUser.fromMap(data, uid);
    } catch (e) {
      return null;
    }
  }

  // ✅ UPDATED: Update user profile safely across all collections
  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      final lookupDoc = await _firestore
          .collection('userBusinessLookup')
          .doc(userId)
          .get();
      if (!lookupDoc.exists) throw Exception('User not found');

      final businessId = lookupDoc.data()?['businessId'] as String;

      data['updatedAt'] = FieldValue.serverTimestamp();

      // Update in MEMBERS
      await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('members')
          .doc(userId)
          .update(data);

      // Keep root users in sync
      await _firestore.collection('users').doc(userId).update(data);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // ===========================================================================
  // 🚀 DELEGATED METHODS
  // These previously duplicated logic. Now they route directly to FirebaseService.
  // ===========================================================================

  Future<List<AppUser>> getAllUsers() async {
    final businessId = await _firebaseService.getCurrentBusinessId();
    if (businessId == null) throw Exception('Business not found');

    // Use the optimized FirebaseService method
    final rawUsers = await _firebaseService.getBusinessUsers(businessId);

    return rawUsers.map((data) {
      data['businessId'] = businessId;
      return AppUser.fromMap(data, data['id']);
    }).toList();
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    final businessId = await _firebaseService.getCurrentBusinessId();
    if (businessId == null) throw Exception('Business not found');

    // Delegate to FirebaseService
    await _firebaseService.updateUserRoleInBusiness(
      businessId: businessId,
      userId: userId,
      newRole: newRole,
    );
  }

  Future<void> toggleUserActive(String userId, bool isActive) async {
    final businessId = await _firebaseService.getCurrentBusinessId();
    if (businessId == null) throw Exception('Business not found');

    // Delegate to FirebaseService
    await _firebaseService.toggleUserActiveInBusiness(
      businessId: businessId,
      userId: userId,
      isActive: isActive,
    );
  }

  /// Permanently deletes current user account and cleans up associated cloud records.
  /// Complies with Apple App Store Guideline 5.1.1(v) for in-app account deletion.
  Future<void> deleteAccount({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found to delete.');
    }

    final uid = user.uid;

    try {
      // Step 1: Reauthenticate if password is provided
      if (password != null && password.isNotEmpty && user.email != null) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      }

      // Step 2: Retrieve business ID from lookup or user doc
      String? businessId;
      try {
        final lookupDoc =
            await _firestore.collection('userBusinessLookup').doc(uid).get();
        if (lookupDoc.exists) {
          businessId = lookupDoc.data()?['businessId'] as String?;
        }
      } catch (_) {}

      if (businessId == null) {
        try {
          final userDoc = await _firestore.collection('users').doc(uid).get();
          if (userDoc.exists) {
            businessId = userDoc.data()?['businessId'] as String?;
          }
        } catch (_) {}
      }

      // Step 3: Remove user from business members if businessId exists
      if (businessId != null && businessId.isNotEmpty) {
        try {
          await _firestore
              .collection('businesses')
              .doc(businessId)
              .collection('members')
              .doc(uid)
              .delete();
        } catch (e) {
          debugPrint('⚠️ Warning deleting from business members: $e');
        }
      }

      // Step 4: Remove user lookup and user root doc
      try {
        await _firestore.collection('userBusinessLookup').doc(uid).delete();
      } catch (e) {
        debugPrint('⚠️ Warning deleting userBusinessLookup: $e');
      }

      try {
        await _firestore.collection('users').doc(uid).delete();
      } catch (e) {
        debugPrint('⚠️ Warning deleting user doc: $e');
      }

      // Step 5: Delete Firebase Auth user
      await user.delete();
      debugPrint('✅ Account successfully deleted for uid: $uid');
    } catch (e) {
      if (e is FirebaseAuthException && e.code == 'requires-recent-login') {
        throw Exception(
          'For security, please verify your credentials to confirm account deletion.',
        );
      }
      throw _handleAuthError(e);
    }
  }

  // Error handler
  String _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No account found with this email. Please check your email or sign up.';
        case 'wrong-password':
          return 'Incorrect password. Please try again or reset your password.';
        case 'invalid-credential':
          return 'Invalid credentials. The email or password you entered is incorrect.';
        case 'user-disabled':
          return 'This user account has been disabled. Please contact support.';
        case 'email-already-in-use':
          return 'This email address is already registered. Please sign in instead.';
        case 'invalid-email':
          return 'Invalid email address format. Please enter a valid email.';
        case 'weak-password':
          return 'Password is too weak. Please use at least 6 characters.';
        case 'operation-not-allowed':
          return 'Email/password sign-in is not enabled in Firebase Authentication.';
        case 'too-many-requests':
          return 'Too many failed login attempts. Access temporarily disabled for security. Please try again later.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        default:
          return error.message ?? 'An authentication error occurred (${error.code}).';
      }
    }
    final msg = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
    return msg;
  }
}
