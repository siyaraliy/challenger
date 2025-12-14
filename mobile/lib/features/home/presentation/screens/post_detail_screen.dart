import 'package:flutter/material.dart';
import '../../../../core/models/post.dart';
import '../../../../core/widgets/video_player_widget.dart';
import '../../../../core/di/service_locator.dart';
import '../../data/posts_repository.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final PostsRepository _postsRepo = getIt<PostsRepository>();
  late Post _post;
  bool _isLiking = false;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  Future<void> _toggleLike() async {
    if (_isLiking) return;
    
    setState(() => _isLiking = true);
    
    try {
      final liked = await _postsRepo.toggleLike(_post.id);
      setState(() {
        _post = _post.copyWith(
          isLiked: liked,
          likesCount: liked ? _post.likesCount + 1 : _post.likesCount - 1,
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Like işlemi başarısız: $e')),
        );
      }
    } finally {
      setState(() => _isLiking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _post.authorName,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _post.authorType == 'team'
                        ? theme.colorScheme.primary
                        : Colors.grey,
                    backgroundImage: _post.authorAvatar != null
                        ? NetworkImage(_post.authorAvatar!)
                        : null,
                    child: _post.authorAvatar == null
                        ? Icon(
                            _post.authorType == 'team' ? Icons.shield : Icons.person,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _post.authorName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_post.authorType == 'team') ...[
                              const SizedBox(width: 6),
                              Icon(Icons.verified, size: 18, color: theme.colorScheme.primary),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _post.timeAgo,
                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Media (if exists)
            if (_post.mediaType != MediaType.none && _post.mediaUrl != null)
              _buildMedia(context),

            // Content Text
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _post.content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),

            // Divider
            Container(
              height: 1,
              color: Colors.grey[800],
            ),

            // Actions Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Like Button
                  GestureDetector(
                    onTap: _toggleLike,
                    child: Row(
                      children: [
                        Icon(
                          _post.isLiked ? Icons.favorite : Icons.favorite_border,
                          color: _post.isLiked ? Colors.red : Colors.white70,
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_post.likesCount}',
                          style: TextStyle(
                            color: _post.isLiked ? Colors.red : Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Comment Button
                  GestureDetector(
                    onTap: () {
                      // TODO: Open comments
                    },
                    child: Row(
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.white70,
                          size: 26,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_post.commentsCount}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Share Button
                  IconButton(
                    icon: const Icon(Icons.share_outlined, color: Colors.white70),
                    onPressed: () {
                      // TODO: Share post
                    },
                  ),
                ],
              ),
            ),

            // Challenge Button for Team Posts
            if (_post.authorType == 'team')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Challenge team
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.sports_mma),
                    label: const Text(
                      'Meydan Oku',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMedia(BuildContext context) {
    if (_post.mediaType == MediaType.image) {
      return GestureDetector(
        onTap: () => _openFullScreenImage(context),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 400),
          width: double.infinity,
          child: Image.network(
            _post.mediaUrl!,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 300,
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
        ),
      );
    } else if (_post.mediaType == MediaType.video) {
      return GestureDetector(
        onTap: () => VideoPlayerDialog.show(
          context,
          _post.mediaUrl!,
          thumbnailUrl: _post.mediaThumbnailUrl,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.black,
              child: _post.mediaThumbnailUrl != null
                  ? Image.network(_post.mediaThumbnailUrl!, fit: BoxFit.cover)
                  : const Icon(Icons.videocam, size: 60, color: Colors.white24),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow, size: 50, color: Colors.white),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _openFullScreenImage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: InteractiveViewer(
            child: Image.network(_post.mediaUrl!),
          ),
        ),
      ),
    );
  }
}
