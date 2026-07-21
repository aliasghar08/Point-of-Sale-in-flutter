import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String email;
  final String name;
  final String role; // 'owner', 'manager', 'worker'
  final String phone;
  final String? businessId; // Reference to the business
  final DateTime createdAt;
  final bool isActive;
  final String? profileImageUrl;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phone = '',
    this.businessId,
    required this.createdAt,
    this.isActive = true,
    this.profileImageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'phone': phone,
      'businessId': businessId,
      'createdAt': createdAt,
      'isActive': isActive,
      'profileImageUrl': profileImageUrl,
    };
  }

  // ✅ Updated: fromMap with optional businessId override
  factory AppUser.fromMap(Map<String, dynamic> map, String id, {String? businessId}) {
    return AppUser(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'worker',
      phone: map['phone'] ?? '',
      // Use provided businessId or get from map
      businessId: businessId ?? map['businessId'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
      profileImageUrl: map['profileImageUrl'],
    );
  }

  // ✅ Helper to create from business user document
  factory AppUser.fromBusinessUser(Map<String, dynamic> map, String id, String businessId) {
    return AppUser(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'worker',
      phone: map['phone'] ?? '',
      businessId: businessId,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
      profileImageUrl: map['profileImageUrl'],
    );
  }

  // Role-based permission checks
  bool get isOwner => role == 'owner';
  bool get isManager => role == 'manager' || role == 'owner';
  bool get isWorker => role == 'worker' || role == 'manager' || role == 'owner';
  bool get canManageInventory => role == 'owner' || role == 'manager';
  bool get canManageUsers => role == 'owner';
  bool get canViewReports => role == 'owner' || role == 'manager';
  bool get canProcessSales => true; // All roles can process sales

  String get roleDisplay {
    switch (role) {
      case 'owner':
        return 'Store Owner';
      case 'manager':
        return 'Manager';
      case 'worker':
        return 'Worker';
      default:
        return 'User';
    }
  }
  
  // ✅ Helper to check if user belongs to a business
  bool get hasBusiness => businessId != null && businessId!.isNotEmpty;
}