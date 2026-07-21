import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pos/models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // ✅ UPDATED: Sign up with business-centric structure (NO root users collection)
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

      // Step 2: Create Business document
      final businessData = {
        'name': storeName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'ownerId': uid,
        'isActive': true,
      };

      final businessRef = await _firestore.collection('businesses').add(businessData);
      final businessId = businessRef.id;

      // Step 3: Create AppUser
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

      // Step 4: Add user to business's users sub-collection (NO root users collection)
      await businessRef.collection('users').doc(uid).set({
        'id': uid,
        'name': name,
        'email': email,
        'role': role,
        'phone': phone,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Step 5: Add to lightweight lookup collection for quick businessId retrieval
      await _firestore.collection('userBusinessLookup').doc(uid).set({
        'businessId': businessId,
        'role': role,
        'email': email,
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Step 6: Create business settings
      await businessRef.collection('settings').doc('store_settings').set({
        'currency': 'PKR',
        'country': 'Pakistan',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return appUser;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ✅ UPDATED: Sign in using lookup collection
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

      // ✅ Get business ID from lookup collection
      final lookupDoc = await _firestore
          .collection('userBusinessLookup')
          .doc(uid)
          .get();

      if (!lookupDoc.exists) {
        throw Exception('User business not found');
      }

      final lookupData = lookupDoc.data() as Map<String, dynamic>;
      final businessId = lookupData['businessId'] as String;

      if (businessId == null) {
        throw Exception('Business not found for user');
      }

      // ✅ Get user data from business's users sub-collection
      final userDoc = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User data not found in business');
      }

      var data = userDoc.data() as Map<String, dynamic>;
      
      // Check if user is active
      if (data['isActive'] == false) {
        await _auth.signOut();
        throw Exception('Account has been deactivated');
      }

      // Add businessId to the data
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

  // ✅ UPDATED: Get current user data from lookup and business
  Future<AppUser?> getCurrentUserData() async {
    User? user = _auth.currentUser;
    if (user == null) return null;

    try {
      final uid = user.uid;

      // ✅ Get business ID from lookup
      final lookupDoc = await _firestore
          .collection('userBusinessLookup')
          .doc(uid)
          .get();

      if (!lookupDoc.exists) {
        print('⚠️ No lookup found for user: $uid');
        return null;
      }

      final lookupData = lookupDoc.data() as Map<String, dynamic>;
      final businessId = lookupData['businessId'] as String;

      if (businessId == null) {
        print('⚠️ No businessId in lookup for user: $uid');
        return null;
      }

      // ✅ Get user data from business's users sub-collection
      final userDoc = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        print('⚠️ User document not found in business: $uid');
        return null;
      }

      var data = userDoc.data() as Map<String, dynamic>;
      data['businessId'] = businessId;

      return AppUser.fromMap(data, uid);
    } catch (e) {
      print('❌ Error getting user data: $e');
      return null;
    }
  }

  // ✅ UPDATED: Update user profile in business
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      // Get business ID from lookup
      final lookupDoc = await _firestore
          .collection('userBusinessLookup')
          .doc(userId)
          .get();

      if (!lookupDoc.exists) {
        throw Exception('User not found');
      }

      final businessId = lookupDoc.data()?['businessId'] as String;

      if (businessId == null) {
        throw Exception('Business not found');
      }

      // Update in business's users sub-collection
      await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('users')
          .doc(userId)
          .update(data);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // ✅ UPDATED: Get all users from business
  Future<List<AppUser>> getAllUsers() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Not authenticated');
      }

      // Get business ID from lookup
      final lookupDoc = await _firestore
          .collection('userBusinessLookup')
          .doc(currentUser.uid)
          .get();

      if (!lookupDoc.exists) {
        throw Exception('User business not found');
      }

      final businessId = lookupDoc.data()?['businessId'] as String;

      if (businessId == null) {
        throw Exception('Business not found');
      }

      // Get all users from business
      final snapshot = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('users')
          .get();

      return snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['businessId'] = businessId;
        return AppUser.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get users: $e');
    }
  }

  // ✅ UPDATED: Update user role in business
  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      // Get business ID from lookup
      final lookupDoc = await _firestore
          .collection('userBusinessLookup')
          .doc(userId)
          .get();

      if (!lookupDoc.exists) {
        throw Exception('User not found');
      }

      final businessId = lookupDoc.data()?['businessId'] as String;

      if (businessId == null) {
        throw Exception('Business not found');
      }

      // If changing to manager, check if manager already exists
      if (newRole == 'manager') {
        final existingManager = await _firestore
            .collection('businesses')
            .doc(businessId)
            .collection('users')
            .where('role', isEqualTo: 'manager')
            .limit(1)
            .get();

        if (existingManager.docs.isNotEmpty && existingManager.docs.first.id != userId) {
          throw Exception('This business already has a manager. Only one manager is allowed.');
        }
      }

      // Update in business's users sub-collection
      await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('users')
          .doc(userId)
          .update({
            'role': newRole,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Update in lookup collection
      await _firestore
          .collection('userBusinessLookup')
          .doc(userId)
          .update({
            'role': newRole,
          });
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  // ✅ UPDATED: Toggle user active status
  Future<void> toggleUserActive(String userId, bool isActive) async {
    try {
      // Get business ID from lookup
      final lookupDoc = await _firestore
          .collection('userBusinessLookup')
          .doc(userId)
          .get();

      if (!lookupDoc.exists) {
        throw Exception('User not found');
      }

      final businessId = lookupDoc.data()?['businessId'] as String;

      if (businessId == null) {
        throw Exception('Business not found');
      }

      // Update in business's users sub-collection
      await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('users')
          .doc(userId)
          .update({
            'isActive': isActive,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to toggle user status: $e');
    }
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
          return 'Email is already registered.';
        case 'invalid-email':
          return 'Invalid email address.';
        case 'weak-password':
          return 'Password is too weak.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        default:
          return error.message ?? 'An error occurred.';
      }
    }
    return error.toString();
  }
}