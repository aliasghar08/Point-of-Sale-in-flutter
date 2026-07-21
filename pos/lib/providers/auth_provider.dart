import 'package:flutter/material.dart';
import 'package:pos/models/user.dart';
import 'package:pos/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  AppUser? _currentUser;
  bool _isLoading = false;
  String? _error;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get isOwner => _currentUser?.isOwner ?? false;
  bool get isManager => _currentUser?.isManager ?? false;
  bool get canManageInventory => _currentUser?.canManageInventory ?? false;
  bool get canManageUsers => _currentUser?.canManageUsers ?? false;
  
  // ✅ Helper to get business ID
  String? get businessId => _currentUser?.businessId;

  // Initialize auth state
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authService.getCurrentUserData();
      if (_currentUser != null) {
        print('✅ User loaded: ${_currentUser!.name}');
        print('✅ Business ID: ${_currentUser!.businessId}');
        print('✅ Role: ${_currentUser!.role}');
      }
    } catch (e) {
      _error = e.toString();
      print('❌ Init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ Sign up with business structure
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
      _currentUser = await _authService.signUp(
        email: email,
        password: password,
        name: name,
        role: role,
        phone: phone,
        storeName: storeName,
      );
      
      if (_currentUser != null) {
        print('✅ Signup successful!');
        print('✅ User: ${_currentUser!.name}');
        print('✅ Business ID: ${_currentUser!.businessId}');
        print('✅ Role: ${_currentUser!.role}');
      }
      
      return _currentUser != null;
    } catch (e) {
      _error = e.toString();
      print('❌ Signup error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign in
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService.signIn(
        email: email,
        password: password,
      );
      
      if (_currentUser != null) {
        print('✅ Signin successful!');
        print('✅ User: ${_currentUser!.name}');
        print('✅ Business ID: ${_currentUser!.businessId}');
        print('✅ Role: ${_currentUser!.role}');
      }
      
      return _currentUser != null;
    } catch (e) {
      _error = e.toString();
      print('❌ Signin error: $e');
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
      print('✅ Signout successful');
    } catch (e) {
      _error = e.toString();
      print('❌ Signout error: $e');
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

  // Update current user
  void updateUser(AppUser user) {
    _currentUser = user;
    notifyListeners();
  }
  
  // ✅ Check if user has a business
  bool get hasBusiness => _currentUser?.businessId != null;
  
  // ✅ Get user's role display name
  String get roleDisplay => _currentUser?.roleDisplay ?? 'User';
}