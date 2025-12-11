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
  Future<String> uploadAvatar(File file, String userId) async {
    try {
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
}
