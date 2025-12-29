import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/post.dart';
import 'video_player_widget.dart';
import 'video_feed_item.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onLikeTap;
  final VoidCallback? onCommentTap;
  final VoidCallback? onChallengeTap;
  final VoidCallback? onShareTap;
  final bool showChallengeButton;

  const PostCard({
    super.key,
    required this.post,
    this.onLikeTap,
    this.onCommentTap,
    this.onChallengeTap,
    this.onShareTap,
    this.showChallengeButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                GestureDetector( // Wrapped the avatar and name/timeAgo section
                  onTap: () {
                    if (post.authorType == 'user') {
                      context.push('/user/${post.authorId}');
                    } else {
                      // Handle team profile navigation if needed (e.g. /team-profile-view/:teamId)
                      // For now, only user profile is requested
                    }
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: post.authorType == 'team' 
                            ? theme.colorScheme.primary 
                            : Colors.grey,
                        backgroundImage: post.authorAvatar != null 
                            ? NetworkImage(post.authorAvatar!) 
                            : null,
                        child: post.authorAvatar == null 
                            ? Icon(
                                post.authorType == 'team' ? Icons.shield : Icons.person,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      if (post.authorType == 'team') ...[
                        const SizedBox(width: 6),
                        Icon(Icons.verified, size: 16, color: theme.colorScheme.primary),
                      ],
                      const SizedBox(width: 8),
                      Text(
                        post.timeAgo,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: Colors.grey),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          
          // Media
          if (post.mediaType != MediaType.none && post.mediaUrl != null)
            _buildMedia(context, post),
          
          // Actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _ActionButton(
                      icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                      label: '${post.likesCount}',
                      color: post.isLiked ? Colors.red : Colors.white70,
                      onTap: onLikeTap,
                    ),
                    const SizedBox(width: 16),
                    _ActionButton(
                      icon: Icons.chat_bubble_outline,
                      label: '${post.commentsCount}',
                      onTap: onCommentTap,
                    ),
                    const SizedBox(width: 16),
                    _ActionButton(
                      icon: Icons.send, // Share icon
                      label: '', // No label for share usually
                      onTap: onShareTap,
                    ),
                    const Spacer(),
                    // DEBUG: Always show button for team posts
                    if (post.authorType == 'team')
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onChallengeTap,
                          borderRadius: BorderRadius.circular(20),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: const Text(
                                'Meydan Oku',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  post.content,
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedia(BuildContext context, Post post) {
    if (post.mediaType == MediaType.image) {
      return Container(
        constraints: const BoxConstraints(maxHeight: 300),
        width: double.infinity,
        child: Image.network(
          post.mediaUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 200,
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 200,
              color: Colors.black26,
              child: const Center(
                child: Icon(Icons.broken_image, size: 50, color: Colors.white24),
              ),
            );
          },
        ),
      );
    } else if (post.mediaType == MediaType.video) {
      // Auto-play video feed item
      return VideoFeedItem(
        videoUrl: post.mediaUrl!,
        thumbnailUrl: post.mediaThumbnailUrl,
      );
    }
    return const SizedBox.shrink();
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.white70, size: 24),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color ?? Colors.white70)),
        ],
      ),
    );
  }
}
