import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import '../../../core/config/api_config.dart';
import '../../../core/models/post.dart';

class PostsRepository {
  final SupabaseClient _supabase;
  final Dio _dio;
  
  final _postCreatedController = StreamController<void>.broadcast();
  Stream<void> get onPostCreated => _postCreatedController.stream;

  PostsRepository(this._supabase)
      : _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));

  String? get _accessToken => _supabase.auth.currentSession?.accessToken;

  // Create post - directly to Supabase
  Future<Post> createPost({
    required String content,
    MediaType mediaType = MediaType.none,
    String? mediaUrl,
    String? mediaThumbnailUrl,
    String? contextType, // 'user' or 'team'
    String? contextId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // Determine author type and id
      final authorType = contextType ?? 'user';
      final authorId = contextId ?? userId;

      print('Creating post: authorType=$authorType, authorId=$authorId');

      final postData = {
        'author_type': authorType,
        'author_id': authorId,
        'content': content,
        'media_type': mediaType == MediaType.none ? 'none' : mediaType.name,
        if (mediaUrl != null) 'media_url': mediaUrl,
        if (mediaThumbnailUrl != null) 'media_thumbnail_url': mediaThumbnailUrl,
      };

      final response = await _supabase
          .from('posts')
          .insert(postData)
          .select()
          .single();

      print('Post created successfully: $response');

      // Get user profile for author info
      final profile = await _supabase
          .from('profiles')
          .select('full_name, avatar_url')
          .eq('id', authorId)
          .maybeSingle();

      final result = <String, dynamic>{
        ...Map<String, dynamic>.from(response),
        'author_name': profile?['full_name'] ?? 'Anonim',
        'author_avatar': profile?['avatar_url'],
      };
      
      // Notify listeners
      _postCreatedController.add(null);

      return Post.fromJson(result);
    } catch (e) {
      print('Create post error: $e');
      throw Exception('Post oluşturulamadı: $e');
    }
  }

  Map<String, String> get _authHeaders => {
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  // Get feed posts - directly from Supabase (bypass backend if not running)
  Future<List<Post>> getFeed({int limit = 20, int offset = 0}) async {
    try {
      print('Fetching feed from Supabase...');
      
      // Simple query without joins
      final response = await _supabase
          .from('posts')
          .select('*')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      print('Feed response: ${response.length} posts');

      final posts = <Post>[];
      
      for (final json in response as List) {
        try {
          final authorType = json['author_type'] as String?;
          final authorId = json['author_id'] as String?;
          String? authorName;
          String? authorAvatar;
          
          // Fetch author info separately
          if (authorType == 'user' && authorId != null) {
            final profile = await _supabase
                .from('profiles')
                .select('full_name, avatar_url')
                .eq('id', authorId)
                .maybeSingle();
            authorName = profile?['full_name'];
            authorAvatar = profile?['avatar_url'];
          } else if (authorType == 'team' && authorId != null) {
            final team = await _supabase
                .from('teams')
                .select('name, logo_url')
                .eq('id', authorId)
                .maybeSingle();
            authorName = team?['name'];
            authorAvatar = team?['logo_url'];
          }
          
          final postData = <String, dynamic>{
            ...Map<String, dynamic>.from(json as Map),
            'author_name': authorName ?? 'Anonim',
            'author_avatar': authorAvatar,
          };
          
          posts.add(Post.fromJson(postData));
        } catch (e) {
          print('Error parsing post: $e');
          print('Post data: $json');
        }
      }
      
      print('Parsed ${posts.length} posts successfully');
      return posts;
    } catch (e) {
      print('Supabase feed error: $e');
      return [];
    }
  }


  // Get posts by specific user - directly from Supabase
  Future<List<Post>> getUserPosts(String userId, {String type = 'all', int limit = 20, int offset = 0}) async {
    try {
      print('Fetching user posts: userId=$userId, type=$type');
      
      // Simple query without joins
      var query = _supabase
          .from('posts')
          .select('*')
          .eq('author_id', userId);
      
      // Filter by type if specified
      if (type == 'media') {
        // query = query.or('media_type.eq.image,media_type.eq.video');
      } else if (type == 'text') {
        // query = query.or('media_type.is.null,media_type.eq.none');
      } else if (type == 'user') {
        query = query.eq('author_type', 'user');
      } else if (type == 'team') {
        query = query.eq('author_type', 'team');
      }
      
      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      print('User posts response: ${response.length} posts');

      final posts = <Post>[];
      
      for (final json in response as List) {
        try {
          final authorType = json['author_type'] as String?;
          final authorId = json['author_id'] as String?;
          String? authorName;
          String? authorAvatar;
          
          // Fetch author info
          if (authorType == 'user' && authorId != null) {
            final profile = await _supabase
                .from('profiles')
                .select('full_name, avatar_url')
                .eq('id', authorId)
                .maybeSingle();
            authorName = profile?['full_name'];
            authorAvatar = profile?['avatar_url'];
          } else if (authorType == 'team' && authorId != null) {
            final team = await _supabase
                .from('teams')
                .select('name, logo_url')
                .eq('id', authorId)
                .maybeSingle();
            authorName = team?['name'];
            authorAvatar = team?['logo_url'];
          }
          
          final postData = <String, dynamic>{
            ...Map<String, dynamic>.from(json as Map),
            'author_name': authorName ?? 'Anonim',
            'author_avatar': authorAvatar,
          };
          
          final post = Post.fromJson(postData);

          // Client-side filtering because Supabase OR syntax can be tricky with nulls
          if (type == 'media') {
            if (post.mediaType == MediaType.image || post.mediaType == MediaType.video) {
              posts.add(post);
            }
          } else if (type == 'text') {
            if (post.mediaType == null || post.mediaType == MediaType.none) {
              posts.add(post);
            }
          } else {
            posts.add(post);
          }
        } catch (e) {
          print('Error parsing user post: $e');
        }
      }
      
      print('Parsed ${posts.length} user posts');
      return posts;
    } catch (e) {
      print('Supabase user posts error: $e');
      return [];
    }
  }



  // Toggle like - directly to Supabase
  Future<bool> toggleLike(String postId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // Check if already liked
      final existing = await _supabase
          .from('post_likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        // Unlike - delete the like
        await _supabase
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);
        return false;
      } else {
        // Like - insert new like
        await _supabase
            .from('post_likes')
            .insert({'post_id': postId, 'user_id': userId});
        return true;
      }
    } catch (e) {
      print('Toggle like error: $e');
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

  // Get comments - directly from Supabase
  Future<List<Comment>> getComments(String postId, {int limit = 20, int offset = 0}) async {
    try {
      final response = await _supabase
          .from('post_comments')
          .select('id, user_id, content, created_at')
          .eq('post_id', postId)
          .order('created_at', ascending: true)
          .range(offset, offset + limit - 1);

      final comments = <Comment>[];
      for (final json in response as List) {
        // Fetch user info
        final userId = json['user_id'] as String;
        final profile = await _supabase
            .from('profiles')
            .select('full_name, avatar_url')
            .eq('id', userId)
            .maybeSingle();

        comments.add(Comment(
          id: json['id'] as String,
          userId: userId,
          userName: profile?['full_name'] ?? 'Anonim',
          userAvatar: profile?['avatar_url'] as String?,
          content: json['content'] as String,
          createdAt: DateTime.parse(json['created_at'] as String),
        ));
      }
      return comments;
    } catch (e) {
      print('Get comments error: $e');
      throw Exception('Yorumlar yüklenemedi: $e');
    }
  }

  // Add comment - directly to Supabase
  Future<Comment> addComment(String postId, String content) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      final response = await _supabase
          .from('post_comments')
          .insert({
            'post_id': postId,
            'user_id': userId,
            'content': content,
          })
          .select()
          .single();

      // Fetch user info for the new comment
      final profile = await _supabase
          .from('profiles')
          .select('full_name, avatar_url')
          .eq('id', userId)
          .maybeSingle();

      return Comment(
        id: response['id'] as String,
        userId: userId,
        userName: profile?['full_name'] ?? 'Anonim',
        userAvatar: profile?['avatar_url'] as String?,
        content: response['content'] as String,
        createdAt: DateTime.parse(response['created_at'] as String),
      );
    } catch (e) {
      print('Add comment error: $e');
      throw Exception('Yorum eklenemedi: $e');
    }
  }

  // Upload media to Supabase Storage
  Future<String> uploadMedia(File file, {required String authorType, required String authorId}) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = file.path.split('.').last.toLowerCase();
    final isVideo = ['mp4', 'mov', 'avi'].contains(extension);
    
    // 1. Size Validation (Max 500MB)
    final sizeInBytes = await file.length();
    final sizeInMB = sizeInBytes / (1024 * 1024);
    if (sizeInMB > 500) {
      throw Exception('Video boyutu 500MB\'dan büyük olamaz.');
    }

    // 2. Duration Validation (Max 60s)
    if (isVideo) {
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      final duration = controller.value.duration;
      await controller.dispose();
      
      if (duration.inSeconds > 60) {
        throw Exception('Video süresi 60 saniyeden uzun olamaz.');
      }
    }

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

  // Delete comment - directly from Supabase
  Future<void> deleteComment(String commentId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // Check if user owns the comment
      final comment = await _supabase
          .from('post_comments')
          .select('user_id')
          .eq('id', commentId)
          .maybeSingle();

      if (comment == null) {
        throw Exception('Yorum bulunamadı');
      }

      if (comment['user_id'] != userId) {
        throw Exception('Sadece kendi yorumlarınızı silebilirsiniz');
      }

      await _supabase
          .from('post_comments')
          .delete()
          .eq('id', commentId);
    } catch (e) {
      print('Delete comment error: $e');
      throw Exception('Yorum silinemedi: $e');
    }
  }
}
