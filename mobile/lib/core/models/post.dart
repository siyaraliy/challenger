import 'package:equatable/equatable.dart';

enum MediaType { image, video, none }

class Post extends Equatable {
  final String id;
  final String authorType; // 'user' or 'team'
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String content;
  final MediaType mediaType;
  final String? mediaUrl;
  final String? mediaThumbnailUrl;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;
  final bool isLiked; // Local state for current user

  const Post({
    required this.id,
    required this.authorType,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.content,
    this.mediaType = MediaType.none,
    this.mediaUrl,
    this.mediaThumbnailUrl,
    this.likesCount = 0,
    this.commentsCount = 0,
    required this.createdAt,
    this.isLiked = false,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      authorType: (json['authorType'] ?? json['author_type']) as String,
      authorId: (json['authorId'] ?? json['author_id']) as String,
      authorName: (json['authorName'] ?? json['author_name']) as String? ?? 'Unknown',
      authorAvatar: (json['authorAvatar'] ?? json['author_avatar']) as String?,
      content: json['content'] as String,
      mediaType: _parseMediaType(json['mediaType'] ?? json['media_type']),
      mediaUrl: (json['mediaUrl'] ?? json['media_url']) as String?,
      mediaThumbnailUrl: (json['mediaThumbnailUrl'] ?? json['media_thumbnail_url']) as String?,
      likesCount: (json['likesCount'] ?? json['likes_count']) as int? ?? 0,
      commentsCount: (json['commentsCount'] ?? json['comments_count']) as int? ?? 0,
      createdAt: DateTime.parse((json['createdAt'] ?? json['created_at']) as String),
    );
  }

  static MediaType _parseMediaType(String? type) {
    switch (type) {
      case 'image':
        return MediaType.image;
      case 'video':
        return MediaType.video;
      default:
        return MediaType.none;
    }
  }

  Post copyWith({
    String? id,
    String? authorType,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? content,
    MediaType? mediaType,
    String? mediaUrl,
    String? mediaThumbnailUrl,
    int? likesCount,
    int? commentsCount,
    DateTime? createdAt,
    bool? isLiked,
  }) {
    return Post(
      id: id ?? this.id,
      authorType: authorType ?? this.authorType,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      content: content ?? this.content,
      mediaType: mediaType ?? this.mediaType,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaThumbnailUrl: mediaThumbnailUrl ?? this.mediaThumbnailUrl,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      createdAt: createdAt ?? this.createdAt,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dk önce';
    } else {
      return 'Şimdi';
    }
  }

  @override
  List<Object?> get props => [
        id,
        authorType,
        authorId,
        authorName,
        content,
        mediaType,
        mediaUrl,
        likesCount,
        commentsCount,
        createdAt,
        isLiked,
      ];
}

class Comment extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String? ?? 'Unknown',
      userAvatar: json['userAvatar'] as String?,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  List<Object?> get props => [id, userId, userName, content, createdAt];
}
