import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pos/models/user.dart';
import 'package:pos/services/firebase_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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

        businessRef = await _firestore.collection('businesses').add(businessData);
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
          throw Exception('Business "$storeName" not found. Please check spelling or contact the owner.');
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

      // Get business ID from lookup collection
      final lookupDoc = await _firestore
          .collection('userBusinessLookup')
          .doc(uid)
          .get();

      if (!lookupDoc.exists) {
        throw Exception('User business not found');
      }

      final lookupData = lookupDoc.data() as Map<String, dynamic>;
      final businessId = lookupData['businessId'] as String;

      // Get user data from business's MEMBERS sub-collection
      final userDoc = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('members')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User data not found in business');
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

  // ✅ UPDATED: Get current user data from MEMBERS sub-collection
  Future<AppUser?> getCurrentUserData() async {
    User? user = _auth.currentUser;
    if (user == null) return null;

    try {
      final uid = user.uid;

      final lookupDoc = await _firestore
          .collection('userBusinessLookup')
          .doc(uid)
          .get();

      if (!lookupDoc.exists) return null;

      final lookupData = lookupDoc.data() as Map<String, dynamic>;
      final businessId = lookupData['businessId'] as String;

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
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      final lookupDoc = await _firestore.collection('userBusinessLookup').doc(userId).get();
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
      newRole: newRole
    );
  }

  Future<void> toggleUserActive(String userId, bool isActive) async {
    final businessId = await _firebaseService.getCurrentBusinessId();
    if (businessId == null) throw Exception('Business not found');
    
    // Delegate to FirebaseService
    await _firebaseService.toggleUserActiveInBusiness(
      businessId: businessId, 
      userId: userId, 
      isActive: isActive
    );
  }

  // Error handler
  String _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'email-already-in-use':
          return 'Email is already registered. Try logging in.';
        case 'invalid-email':
          return 'Invalid email address format.';
        case 'weak-password':
          return 'Password is too weak. Use at least 6 characters.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please try again later.';
        default:
          return error.message ?? 'An authentication error occurred.';
      }
    }
    return error.toString();
  }
}