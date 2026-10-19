import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pos/models/user.dart';
import 'package:pos/models/product.dart';
import 'package:pos/services/auth_service.dart';
import 'package:pos/services/firebase_service.dart';
import 'package:pos/services/cache_service.dart';
import 'package:pos/services/sample_data_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseService _firebaseService = FirebaseService();

  AppUser? _currentUser;
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _error;
  bool _isUnlocked = false; // Biometric unlock state

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get isUnlocked => _isUnlocked;
  bool get isOwner => _currentUser?.isOwner ?? false;
  bool get isManager => _currentUser?.isManager ?? false;
  bool get canManageInventory => _currentUser?.canManageInventory ?? false;
  bool get canManageUsers => _currentUser?.canManageUsers ?? false;

  // ✅ Helper to get business ID
  String? get businessId => _currentUser?.businessId;
  String? get currentBusinessId => businessId;

  // Initialize auth state
  Future<void> init() async {
    _isInitializing = true;
    notifyListeners();

    try {
      _currentUser = await _authService.getCurrentUserData();
      if (_currentUser != null) {
        debugPrint('✅ User loaded: ${_currentUser!.name}');
        debugPrint('✅ Business ID: ${_currentUser!.businessId}');
        debugPrint('✅ Role: ${_currentUser!.role}');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Init error: $e');
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  // ✅ Sign up - Creates Firebase Auth user and business/member records
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    required String phone,
    required String storeName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.signUp(
        email: email,
        password: password,
        name: name,
        role: role,
        phone: phone,
        storeName: storeName,
      );

      if (user != null) {
        debugPrint('✅ Signup successful for ${user.email} (Business: ${user.businessId})');
        // Sign out immediately so user signs in cleanly through LoginScreen
        await _authService.signOut();
        _currentUser = null;
        return true;
      }
      throw Exception('Failed to create account');
    } catch (e) {
      _error = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      debugPrint('❌ Signup error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ Complete signup after email verification
  Future<bool> completeSignup({
    required String email,
    required String password,
    required String name,
    required String role,
    required String phone,
    required String storeName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Sign in to get the user
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        throw Exception('User not found');
      }

      // Check if email is verified
      await firebaseUser.reload();
      if (!firebaseUser.emailVerified) {
        throw Exception('Email not verified. Please verify your email first.');
      }

      // Create business and user data
      final businessId = await _firebaseService.createBusiness(storeName);

      if (businessId.isEmpty) {
        throw Exception('Failed to create business');
      }

      // Add user to business members
      await _firebaseService.addUserToBusiness(
        userId: firebaseUser.uid,
        email: email,
        name: name,
        role: role,
        phone: phone,
        businessId: businessId,
      );

      // Get the updated user data
      _currentUser = await _authService.getCurrentUserData();

      // Sign out after signup
      await _authService.signOut();
      _currentUser = null;

      debugPrint('✅ Signup completed successfully!');
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Complete signup error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign in
  Future<bool> signIn({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService.signIn(
        email: email,
        password: password,
      );

      if (_currentUser != null) {
        debugPrint('✅ Signin successful!');
        debugPrint('✅ User: ${_currentUser!.name}');
        debugPrint('✅ Business ID: ${_currentUser!.businessId}');
        debugPrint('✅ Role: ${_currentUser!.role}');
      }

      return _currentUser != null;
    } catch (e) {
      _error = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      debugPrint('❌ Signin error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _currentUser = null;
      debugPrint('✅ Signout successful');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Signout error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      debugPrint('❌ Send password reset error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Sign in as a demo store owner for testing and app evaluation
  Future<bool> signInDemo() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = AppUser(
        id: 'demo-cashier-owner',
        name: 'Demo Store Owner',
        email: 'demo@poshub.app',
        role: 'owner',
        businessId: 'demo_business_store',
        phone: '+1 555-0199',
        createdAt: DateTime.now(),
        isActive: true,
      );

      final cache = CacheService();
      if (cache.allProducts.isEmpty) {
        final demoItems = SampleDataService.sampleProducts
            .map((m) => Product.fromMap(m, 'demo_${m['sku']}'))
            .toList();
        cache.setProducts(demoItems);
      }
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      _isInitializing = false;
      notifyListeners();
    }
  }

  // Update current user
  void updateUser(AppUser user) {
    _currentUser = user;
    notifyListeners();
  }

  // Unlock biometrics
  void unlock() {
    _isUnlocked = true;
    notifyListeners();
  }

  // ✅ Check if user has a business
  bool get hasBusiness => _currentUser?.businessId != null;

  // ✅ Get user's role display name
  String get roleDisplay => _currentUser?.roleDisplay ?? 'User';

  /// Permanently delete account and clear local state (Apple App Store Guideline 5.1.1(v))
  Future<bool> deleteAccount({String? password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.deleteAccount(password: password);
      _currentUser = null;
      _isUnlocked = false;
      debugPrint('✅ Account deleted successfully');
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('❌ Account deletion error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
