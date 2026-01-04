import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

/// Authentication state notifier
class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  AuthNotifier() : super(const AsyncValue.data(null));

  /// Login with email and password
  Future<void> login(String email, String password, {User? user}) async {
    state = const AsyncValue.loading();

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 300));

      // If user object is provided (from users provider), use it
      if (user != null) {
        // Update last login time
        final updatedUser = User(
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role,
          createdAt: user.createdAt,
          lastLogin: DateTime.now(),
          passwordHash: user.passwordHash,
          employeeId: user.employeeId,
          qrCode: user.qrCode,
          qrCodeDownloaded: user.qrCodeDownloaded,
          mustChangePassword: user.mustChangePassword,
        );
        state = AsyncValue.data(updatedUser);
      } else if (email.isNotEmpty && password.isNotEmpty) {
        // Fallback for backwards compatibility
        final fallbackUser = User(
          id: '1',
          email: email,
          name: email.split('@').first, // Use email prefix as name
          role: 'User',
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );
        state = AsyncValue.data(fallbackUser);
      } else {
        state = AsyncValue.error('Invalid credentials', StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Logout
  Future<void> logout() async {
    state = const AsyncValue.loading();
    await Future.delayed(const Duration(milliseconds: 500));
    state = const AsyncValue.data(null);
  }

  /// Update user details
  void updateUser(User updatedUser) {
    state = AsyncValue.data(updatedUser);
  }

  /// Get current user
  User? get currentUser {
    return state.valueOrNull;
  }

  /// Check if user is authenticated
  bool get isAuthenticated {
    return state.valueOrNull != null;
  }
}

/// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((
  ref,
) {
  return AuthNotifier();
});

/// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).valueOrNull;
});

/// Is authenticated provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).valueOrNull != null;
});
