import 'dart:io';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/api_config.dart';
import '../../../core/models/post.dart';

class PostsRepository {
  final SupabaseClient _supabase;
  final Dio _dio;

  PostsRepository(this._supabase)
      : _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));

  String? get _accessToken => _supabase.auth.currentSession?.accessToken;

  Map<String, String> get _authHeaders => {
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  // Get feed posts
  Future<List<Post>> getFeed({int limit = 20, int offset = 0}) async {
    try {
      final response = await _dio.get(
        '/posts/feed',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      final data = response.data['data'] as List;
      final posts = <Post>[];
      
      for (final json in data) {
        try {
          posts.add(Post.fromJson(json));
        } catch (e) {
          print('Error parsing post: $e');
          print('Post data: $json');
        }
      }
      
      return posts;
    } catch (e) {
      throw Exception('Feed yüklenemedi: $e');
    }
  }

  // Get posts by specific user
  Future<List<Post>> getUserPosts(String userId, {String type = 'all', int limit = 20, int offset = 0}) async {
    try {
      final response = await _dio.get(
        '/posts/user/$userId',
        queryParameters: {'type': type, 'limit': limit, 'offset': offset},
      );

      final data = response.data['data'] as List;
      final posts = <Post>[];
      
      for (final json in data) {
        try {
          posts.add(Post.fromJson(json));
        } catch (e) {
          print('Error parsing user post: $e');
        }
      }
      
      return posts;
    } catch (e) {
      throw Exception('Kullanıcı postları yüklenemedi: $e');
    }
  }

  // Create post (text only for now)
  Future<Post> createPost({
    required String content,
    MediaType mediaType = MediaType.none,
    String? mediaUrl,
    String? mediaThumbnailUrl,
    String? contextType, // 'user' or 'team'
    String? contextId,
  }) async {
    try {
      print('Creating post with contextType: $contextType, contextId: $contextId');
      print('Auth token present: ${_accessToken != null}');
      
      final response = await _dio.post(
        '/posts',
        data: {
          'content': content,
          'mediaType': mediaType.name,
          if (mediaUrl != null) 'mediaUrl': mediaUrl,
          if (mediaThumbnailUrl != null) 'mediaThumbnailUrl': mediaThumbnailUrl,
        },
        options: Options(
          headers: {
            ..._authHeaders,
            if (contextType != null) 'x-context-type': contextType,
            if (contextId != null) 'x-context-id': contextId,
          },
        ),
      );

      print('Post created successfully: ${response.data}');
      return Post.fromJson(response.data['data']);
    } on DioException catch (e) {
      print('DioException: ${e.response?.statusCode} - ${e.response?.data}');
      throw Exception('Post oluşturulamadı: ${e.response?.data ?? e.message}');
    } catch (e) {
      print('General error: $e');
      throw Exception('Post oluşturulamadı: $e');
    }
  }

  // Toggle like
  Future<bool> toggleLike(String postId) async {
    try {
      final response = await _dio.post(
        '/posts/$postId/like',
        options: Options(headers: _authHeaders),
      );
      return response.data['liked'] as bool;
    } catch (e) {
      throw Exception('Like işlemi başarısız: $e');
    }
  }

  // Check if post is liked by current user
  Future<bool> isLiked(String postId) async {
    try {
      final response = await _dio.get(
        '/posts/$postId/liked',
        options: Options(headers: _authHeaders),
      );
      return response.data['liked'] as bool;
    } catch (e) {
      return false;
    }
  }

  // Get comments
  Future<List<Comment>> getComments(String postId, {int limit = 20, int offset = 0}) async {
    try {
      final response = await _dio.get(
        '/posts/$postId/comments',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      final data = response.data['data'] as List;
      return data.map((json) => Comment.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Yorumlar yüklenemedi: $e');
    }
  }

  // Add comment
  Future<Comment> addComment(String postId, String content) async {
    try {
      final response = await _dio.post(
        '/posts/$postId/comments',
        data: {'content': content},
        options: Options(headers: _authHeaders),
      );
      return Comment.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Yorum eklenemedi: $e');
    }
  }

  // Upload media to Supabase Storage
  Future<String> uploadMedia(File file, {required String authorType, required String authorId}) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = file.path.split('.').last.toLowerCase();
    final isVideo = ['mp4', 'mov', 'avi'].contains(extension);
    final folder = isVideo ? 'videos' : 'images';
    final path = '$folder/$authorType/$authorId/$timestamp.$extension';

    final bytes = await file.readAsBytes();
    
    await _supabase.storage.from('posts').uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        contentType: isVideo ? 'video/$extension' : 'image/$extension',
      ),
    );

    return _supabase.storage.from('posts').getPublicUrl(path);
  }

  // Delete post
  Future<void> deletePost(String postId) async {
    try {
      await _dio.delete(
        '/posts/$postId',
        options: Options(headers: _authHeaders),
      );
    } catch (e) {
      throw Exception('Post silinemedi: $e');
    }
  }
}
