import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user_model.dart';

/// Users state notifier for managing all user accounts
class UsersNotifier extends StateNotifier<List<User>> {
  UsersNotifier() : super([]) {
    _createDefaultAdmin();
  }

  /// Create default admin account
  void _createDefaultAdmin() {
    final now = DateTime.now();
    final email = 'admin@pos.com';
    final password = 'admin123';
    final passwordHash = _hashPassword(password);
    final qrCode = _generateQRCode(email, password);

    final adminUser = User(
      id: 'admin-default',
      email: email,
      name: 'Administrator',
      role: 'Admin',
      createdAt: now,
      lastLogin: now,
      passwordHash: passwordHash,
      qrCode: qrCode,
      qrCodeDownloaded: false,
      mustChangePassword: false, // Admin doesn't need to change password
    );

    state = [adminUser];
  }

  /// Hash password using SHA256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Generate QR code data (email:password combination)
  String _generateQRCode(String email, String password) {
    return '$email:$password';
  }

  /// Add a new user account
  User addUser({
    required String id,
    required String email,
    required String password,
    required String name,
    required String role,
    String? employeeId,
  }) {
    final now = DateTime.now();
    final passwordHash = _hashPassword(password);
    final qrCode = _generateQRCode(email, password);

    final user = User(
      id: id,
      email: email,
      name: name,
      role: role,
      createdAt: now,
      lastLogin: now,
      passwordHash: passwordHash,
      employeeId: employeeId,
      qrCode: qrCode,
      qrCodeDownloaded: false,
      mustChangePassword: true, // Force password change on first login
    );

    state = [...state, user];
    return user;
  }

  /// Mark QR code as downloaded
  void markQRCodeDownloaded(String userId) {
    state = [
      for (final u in state)
        if (u.id == userId) u.copyWith(qrCodeDownloaded: true) else u,
    ];
  }

  /// Change user password
  void changePassword(String userId, String newPassword) {
    final passwordHash = _hashPassword(newPassword);
    state = [
      for (final u in state)
        if (u.id == userId)
          u.copyWith(
            passwordHash: passwordHash,
            qrCode: _generateQRCode(u.email, newPassword),
            mustChangePassword: false,
          )
        else
          u,
    ];
  }

  /// Update user
  void updateUser(User user) {
    state = [
      for (final u in state)
        if (u.id == user.id) user else u,
    ];
  }

  /// Delete user
  void deleteUser(String userId) {
    state = state.where((user) => user.id != userId).toList();
  }

  /// Find user by email
  User? findUserByEmail(String email) {
    try {
      return state.firstWhere((user) => user.email == email);
    } catch (e) {
      return null;
    }
  }

  /// Find user by employee ID
  User? findUserByEmployeeId(String employeeId) {
    try {
      return state.firstWhere((user) => user.employeeId == employeeId);
    } catch (e) {
      return null;
    }
  }

  /// Verify user credentials
  bool verifyCredentials(String email, String password) {
    final user = findUserByEmail(email);
    if (user == null) return false;

    final passwordHash = _hashPassword(password);
    return user.passwordHash == passwordHash;
  }

  /// Verify QR code login
  User? verifyQRCode(String qrCodeData) {
    try {
      final user = state.firstWhere((user) => user.qrCode == qrCodeData);
      return user;
    } catch (e) {
      return null;
    }
  }
}

/// Users provider
final usersProvider = StateNotifierProvider<UsersNotifier, List<User>>((ref) {
  return UsersNotifier();
});
