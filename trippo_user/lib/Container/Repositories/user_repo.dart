import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../Model/user_model.dart';

/// User Repository
/// Manages user data, roles, and permissions

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _usersCollection = 'users';

  /// Get current user
  Future<AppUser?> getCurrentUser() async {
    final authUser = _auth.currentUser;
    if (authUser == null) return null;

    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(authUser.uid)
          .get();

      if (!doc.exists || doc.data() == null) {
        // Create user if doesn't exist
        final newUser = AppUser(
          id: authUser.uid,
          email: authUser.email ?? '',
          name: authUser.displayName ?? 'User',
          phoneNumber: authUser.phoneNumber,
          profileImageUrl: authUser.photoURL,
          role: UserRole.user, // Default role
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );

        await createUser(newUser);
        return newUser;
      }

      // Update last login
      await _firestore
          .collection(_usersCollection)
          .doc(authUser.uid)
          .update({'lastLoginAt': DateTime.now().toIso8601String()});

      return AppUser.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  /// Stream current user
  Stream<AppUser?> streamCurrentUser() {
    final authUser = _auth.currentUser;
    if (authUser == null) return Stream.value(null);

    return _firestore
        .collection(_usersCollection)
        .doc(authUser.uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return AppUser.fromFirestore(snapshot.data()!, snapshot.id);
    });
  }

  /// Create user
  Future<void> createUser(AppUser user) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(user.id)
          .set(user.toFirestore());
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  /// Update user
  Future<void> updateUser(AppUser user) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(user.id)
          .update(user.toFirestore());
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  /// Update user role (admin only)
  Future<void> updateUserRole(String userId, UserRole role) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .update({'role': role.name});
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  /// Get user by ID
  Future<AppUser?> getUserById(String userId) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();

      if (!doc.exists || doc.data() == null) return null;

      return AppUser.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  /// Get all users (admin only)
  Future<List<AppUser>> getAllUsers({
    UserRole? filterByRole,
    int limit = 100,
  }) async {
    try {
      Query query = _firestore.collection(_usersCollection);

      if (filterByRole != null) {
        query = query.where('role', isEqualTo: filterByRole.name);
      }

      final snapshot = await query.limit(limit).get();

      return snapshot.docs
          .map((doc) => AppUser.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting users: $e');
      return [];
    }
  }

  /// Stream all admins
  Stream<List<AppUser>> streamAdmins() {
    return _firestore
        .collection(_usersCollection)
        .where('role', isEqualTo: UserRole.admin.name)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AppUser.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  /// Check if user has permission
  Future<bool> hasPermission(AdminPermission permission) async {
    final user = await getCurrentUser();
    if (user == null) return false;

    return user.role.permissions.contains(permission);
  }

  /// Check if current user is admin
  Future<bool> isAdmin() async {
    final user = await getCurrentUser();
    return user?.isAdmin ?? false;
  }

  /// Deactivate user (admin only)
  Future<void> deactivateUser(String userId) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .update({'isActive': false});
    } catch (e) {
      throw Exception('Failed to deactivate user: $e');
    }
  }

  /// Activate user (admin only)
  Future<void> activateUser(String userId) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .update({'isActive': true});
    } catch (e) {
      throw Exception('Failed to activate user: $e');
    }
  }

  /// Get user statistics
  Future<Map<String, int>> getUserStats() async {
    try {
      final snapshot = await _firestore.collection(_usersCollection).get();

      final stats = <String, int>{
        'total': snapshot.docs.length,
        'admins': 0,
        'users': 0,
        'providers': 0,
        'active': 0,
        'inactive': 0,
      };

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final role = data['role'] as String?;
        final isActive = data['isActive'] as bool? ?? true;

        if (role != null) {
          stats[role] = (stats[role] ?? 0) + 1;
        }

        if (isActive) {
          stats['active'] = stats['active']! + 1;
        } else {
          stats['inactive'] = stats['inactive']! + 1;
        }
      }

      return stats;
    } catch (e) {
      print('Error getting user stats: $e');
      return {};
    }
  }

  /// Make user an admin (use carefully!)
  Future<void> makeAdmin(String userId) async {
    await updateUserRole(userId, UserRole.admin);
  }
}
