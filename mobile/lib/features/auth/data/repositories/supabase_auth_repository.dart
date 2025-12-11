import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _supabase;

  SupabaseAuthRepository(this._supabase);

  @override
  Future<void> login(String email, String password) async {
    await signInWithEmail(email, password);
  }

  @override
  Future<void> register(String email, String password, String fullName) async {
    await signUpWithEmail(email, password, {'full_name': fullName});
  }

  @override
  Future<void> logout() async {
    await signOut();
  }

  @override
  Future<bool> isAuthenticated() async {
    return currentUser != null;
  }

  @override
  Future<String?> getCurrentUserId() async {
    return currentUser?.id;
  }

  @override
  Future<void> loginAsGuest() async {
    await signInAnonymously();
  }

  // ========== Supabase Specific Methods ==========

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      throw Exception('Giriş başarısız: ${e.toString()}');
    }
  }

  /// Sign up with email, password and metadata
  Future<AuthResponse> signUpWithEmail(
    String email,
    String password,
    Map<String, dynamic> metadata,
  ) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': metadata['full_name'],
          'role': metadata['role'] ?? 'player', // Default role
        },
      );
      return response;
    } catch (e) {
      throw Exception('Kayıt başarısız: ${e.toString()}');
    }
  }

  /// Sign in anonymously (Guest mode)
  Future<AuthResponse> signInAnonymously() async {
    try {
      final response = await _supabase.auth.signInAnonymously();
      return response;
    } catch (e) {
      throw Exception('Misafir girişi başarısız: ${e.toString()}');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Çıkış başarısız: ${e.toString()}');
    }
  }

  /// Get current user
  User? get currentUser {
    return _supabase.auth.currentUser;
  }

  /// Get current session
  Session? get currentSession {
    return _supabase.auth.currentSession;
  }

  /// Check if user is anonymous
  bool get isAnonymous {
    final user = currentUser;
    if (user == null) return false;
    return user.isAnonymous;
  }

  /// Get user metadata
  Map<String, dynamic>? get userMetadata {
    return currentUser?.userMetadata;
  }

  /// Update user metadata
  Future<UserResponse> updateUserMetadata(Map<String, dynamic> metadata) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(data: metadata),
      );
      return response;
    } catch (e) {
      throw Exception('Profil güncelleme başarısız: ${e.toString()}');
    }
  }

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges {
    return _supabase.auth.onAuthStateChange;
  }
}
