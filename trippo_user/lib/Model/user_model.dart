import 'package:cloud_firestore/cloud_firestore.dart';

/// User Model with Role-Based Access Control
/// Supports admin, user, and provider roles

class AppUser {
  final String id; // Firebase Auth UID
  final String email;
  final String name;
  final String? phoneNumber;
  final String? profileImageUrl;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.phoneNumber,
    this.profileImageUrl,
    required this.role,
    required this.createdAt,
    this.lastLoginAt,
    this.isActive = true,
    this.metadata,
  });

  factory AppUser.fromFirestore(Map<String, dynamic> data, String id) {
    return AppUser(
      id: id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phoneNumber: data['phoneNumber'],
      profileImageUrl: data['profileImageUrl'],
      role: UserRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => UserRole.user,
      ),
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      lastLoginAt: data['lastLoginAt'] != null
          ? DateTime.parse(data['lastLoginAt'])
          : null,
      isActive: data['isActive'] ?? true,
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'role': role.name,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? name,
    String? phoneNumber,
    String? profileImageUrl,
    UserRole? role,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isProvider => role == UserRole.provider;
  bool get isRegularUser => role == UserRole.user;
}

/// User Role Enum
enum UserRole {
  admin,    // Full access to admin dashboard
  user,     // Regular app user
  provider, // Service provider
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.user:
        return 'User';
      case UserRole.provider:
        return 'Service Provider';
    }
  }

  String get icon {
    switch (this) {
      case UserRole.admin:
        return '👨‍💼';
      case UserRole.user:
        return '👤';
      case UserRole.provider:
        return '🔧';
    }
  }

  List<AdminPermission> get permissions {
    switch (this) {
      case UserRole.admin:
        return AdminPermission.values; // All permissions
      case UserRole.provider:
        return []; // No admin permissions
      case UserRole.user:
        return []; // No admin permissions
    }
  }
}

/// Admin Permission Enum
enum AdminPermission {
  viewApplications,
  approveApplications,
  rejectApplications,
  manageUsers,
  viewStatistics,
  editAppConfig,
  viewBackgroundChecks,
  verifyLicenses,
  manageProviders,
  viewAllServiceRequests,
}

extension AdminPermissionExtension on AdminPermission {
  String get displayName {
    switch (this) {
      case AdminPermission.viewApplications:
        return 'View Applications';
      case AdminPermission.approveApplications:
        return 'Approve Applications';
      case AdminPermission.rejectApplications:
        return 'Reject Applications';
      case AdminPermission.manageUsers:
        return 'Manage Users';
      case AdminPermission.viewStatistics:
        return 'View Statistics';
      case AdminPermission.editAppConfig:
        return 'Edit App Configuration';
      case AdminPermission.viewBackgroundChecks:
        return 'View Background Checks';
      case AdminPermission.verifyLicenses:
        return 'Verify Licenses';
      case AdminPermission.manageProviders:
        return 'Manage Providers';
      case AdminPermission.viewAllServiceRequests:
        return 'View All Service Requests';
    }
  }
}
