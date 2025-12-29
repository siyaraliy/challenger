import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/models/user_profile.dart';

class ProfileRepository {
  final SupabaseClient _supabase;

  ProfileRepository(this._supabase);

  /// Get user profile by ID
  Future<UserProfile?> getProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      return UserProfile.fromJson(response);
    } catch (e) {
      throw Exception('Profil getirilemedi: ${e.toString()}');
    }
  }

  /// Update user profile
  Future<void> updateProfile(UserProfile profile) async {
    try {
      await _supabase
          .from('profiles')
          .update(profile.toJson())
          .eq('id', profile.id);
    } catch (e) {
      throw Exception('Profil güncellenemedi: ${e.toString()}');
    }
  }

  /// Upload avatar to Supabase Storage and return public URL
  /// Note: userId should be obtained from current authenticated user
  Future<String> uploadAvatar(File file) async {
    try {
      // Get current user ID from Supabase auth
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      final fileExt = file.path.split('.').last;
      final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await _supabase.storage.from('avatars').upload(
            fileName,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      // Get public URL
      final publicUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);
      
      return publicUrl;
    } catch (e) {
      throw Exception('Avatar yüklenemedi: ${e.toString()}');
    }
  }

  /// Create profile (called after user signs up)
  Future<void> createProfile(String userId, String fullName) async {
    try {
      final profile = UserProfile(
        id: userId,
        fullName: fullName,
        createdAt: DateTime.now(),
      );

      await _supabase.from('profiles').insert(profile.toJson());
    } catch (e) {
      throw Exception('Profil oluşturulamadı: ${e.toString()}');
    }
  }

  /// Delete avatar from storage
  Future<void> deleteAvatar(String avatarUrl) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(avatarUrl);
      final filePath = uri.pathSegments.last;
      
      await _supabase.storage.from('avatars').remove([filePath]);
    } catch (e) {
      throw Exception('Avatar silinemedi: ${e.toString()}');
    }
  }

  /// Follow a user
  Future<void> followUser(String targetUserId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      await _supabase.from('follows').insert({
        'follower_id': currentUserId,
        'following_id': targetUserId,
      });
    } catch (e) {
      throw Exception('Takip edilemedi: ${e.toString()}');
    }
  }

  /// Unfollow a user
  Future<void> unfollowUser(String targetUserId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      await _supabase
          .from('follows')
          .delete()
          .eq('follower_id', currentUserId)
          .eq('following_id', targetUserId);
    } catch (e) {
      throw Exception('Takipten çıkılamadı: ${e.toString()}');
    }
  }

  /// Check if following a user
  Future<bool> isFollowing(String targetUserId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return false;

      final response = await _supabase
          .from('follows')
          .select()
          .eq('follower_id', currentUserId)
          .eq('following_id', targetUserId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      // Fail silently for check
      return false;
    }
  }

  /// Get list of followers for a user
  Future<List<UserProfile>> getFollowers(String userId) async {
    try {
      final response = await _supabase
          .from('follows')
          .select('follower_id')
          .eq('following_id', userId);

      final ids = (response as List)
          .map((e) => e['follower_id'] as String)
          .toList();
      
      print('Followers fetch: found ${ids.length} IDs for user $userId');
      
      if (ids.isEmpty) return [];

      final profilesResponse = await _supabase
          .from('profiles')
          .select()
          .inFilter('id', ids);

      print('Followers fetch: found ${profilesResponse.length} profiles for ${ids.length} IDs');

      return (profilesResponse as List)
          .map((e) => UserProfile.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Takipçiler getirilemedi: ${e.toString()}');
    }
  }

  /// Get list of users that a user is following
  Future<List<UserProfile>> getFollowing(String userId) async {
    try {
      final response = await _supabase
          .from('follows')
          .select('following_id')
          .eq('follower_id', userId);

      final ids = (response as List)
          .map((e) => e['following_id'] as String)
          .toList();
      
      print('Following fetch: found ${ids.length} IDs for user $userId');
      
      if (ids.isEmpty) return [];

      final profilesResponse = await _supabase
          .from('profiles')
          .select()
          .inFilter('id', ids);

      print('Following fetch: found ${profilesResponse.length} profiles for ${ids.length} IDs');

      return (profilesResponse as List)
          .map((e) => UserProfile.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Takip edilenler getirilemedi: ${e.toString()}');
    }
  }

  /// Search profiles by name
  Future<List<UserProfile>> searchProfiles(String query) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .ilike('full_name', '%$query%')
          .limit(20);

      return (response as List)
          .map((e) => UserProfile.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Kullanıcı aranamadı: ${e.toString()}');
    }
  }
}
