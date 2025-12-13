import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/models/team.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _supabase;
  final Dio _dio;
  final FlutterSecureStorage _storage;

  SupabaseAuthRepository(this._supabase)
      : _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl)),
        _storage = const FlutterSecureStorage();

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

  // ========== Team Authentication (Backend API) ==========

  /// Team login with email and password
  Future<TeamAuthResult> teamLogin(String email, String password) async {
    try {
      // Get current user token for authorization
      final session = currentSession;
      if (session == null) {
        throw Exception('User must be logged in first');
      }

      final response = await _dio.post(
        ApiConfig.authTeamLogin,
        data: {
          'email': email,
          'password': password,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
          },
        ),
      );

      final teamToken = response.data['teamToken'] as String;
      final teamData = response.data['team'] as Map<String, dynamic>;
      final team = Team.fromLoginResponse(teamData);

      // Save team token
      await _storage.write(key: 'team_token', value: teamToken);

      return TeamAuthResult(team: team, teamToken: teamToken);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Geçersiz email veya şifre');
      }
      throw Exception('Takım girişi başarısız: ${e.message}');
    } catch (e) {
      throw Exception('Takım girişi başarısız: ${e.toString()}');
    }
  }

  /// Team logout
  Future<void> teamLogout() async {
    try {
      final teamToken = await _storage.read(key: 'team_token');
      if (teamToken == null) return;

      await _dio.post(
        ApiConfig.authTeamLogout,
        options: Options(
          headers: {
            'Authorization': 'Bearer $teamToken',
          },
        ),
      );

      await _storage.delete(key: 'team_token');
    } catch (e) {
      // Continue even if logout fails
      await _storage.delete(key: 'team_token');
    }
  }

  /// Get stored team token
  Future<String?> getTeamToken() async {
    return await _storage.read(key: 'team_token');
  }

  /// Register team credentials (after team creation)
  Future<void> registerTeamCredentials({
    required String teamId,
    required String email,
    required String password,
  }) async {
    try {
      final session = currentSession;
      if (session == null) {
        throw Exception('User must be logged in');
      }

      await _dio.post(
        '/auth/team/register',
        data: {
          'teamId': teamId,
          'email': email,
          'password': password,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
          },
        ),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception(e.response?.data['message'] ?? 'Takım credentials kayıt edilemedi');
      }
      throw Exception('Takım credentials kayıt edilemedi: ${e.message}');
    } catch (e) {
      throw Exception('Takım credentials kayıt edilemedi: ${e.toString()}');
    }
  }
}

/// Team authentication result
class TeamAuthResult {
  final Team team;
  final String teamToken;

  TeamAuthResult({required this.team, required this.teamToken});
}
