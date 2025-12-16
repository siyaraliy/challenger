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
    if (_post.mediaType == MediaType.none) {
      return _buildTextPostLayout(context);
    } else {
      return _buildMediaPostLayout(context);
    }
  }

  Widget _buildTextPostLayout(BuildContext context) {
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
        title: const Text('Gönderi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _post.authorType == 'team' ? theme.colorScheme.primary : Colors.grey,
                  backgroundImage: _post.authorAvatar != null ? NetworkImage(_post.authorAvatar!) : null,
                  child: _post.authorAvatar == null
                      ? Icon(_post.authorType == 'team' ? Icons.shield : Icons.person, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _post.authorName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (_post.authorType == 'team')
                      Text('@${_post.authorName.replaceAll(' ', '').toLowerCase()}', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Content
            Text(
              _post.content,
              style: const TextStyle(color: Colors.white, fontSize: 22, height: 1.3),
            ),
            const SizedBox(height: 16),
            
            // Date
            Text(
              _post.timeAgo,
              style: TextStyle(color: Colors.grey[500], fontSize: 15),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            
            // Stats
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text('${_post.likesCount}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(' Beğeni', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                  const SizedBox(width: 16),
                  Text('${_post.commentsCount}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(' Yorum', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                ],
              ),
            ),
            const Divider(color: Colors.white24),
            
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: Icon(_post.isLiked ? Icons.favorite : Icons.favorite_border, color: _post.isLiked ? Colors.red : Colors.grey),
                  onPressed: _toggleLike,
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.grey),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: Colors.grey),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPostLayout(BuildContext context) {
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
        title: Text(_post.authorName.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: _post.authorType == 'team' ? theme.colorScheme.primary : Colors.grey,
                    backgroundImage: _post.authorAvatar != null ? NetworkImage(_post.authorAvatar!) : null,
                    child: _post.authorAvatar == null
                        ? Icon(_post.authorType == 'team' ? Icons.shield : Icons.person, size: 16, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _post.authorName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const Spacer(),
                  const Icon(Icons.more_vert, color: Colors.white),
                ],
              ),
            ),

            // Media
            GestureDetector(
              onDoubleTap: _toggleLike,
              child: _buildMedia(context),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _toggleLike,
                    child: Icon(
                      _post.isLiked ? Icons.favorite : Icons.favorite_border,
                      color: _post.isLiked ? Colors.red : Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 26),
                  const SizedBox(width: 16),
                  const Icon(Icons.send, color: Colors.white, size: 26),
                  const Spacer(),
                  const Icon(Icons.bookmark_border, color: Colors.white, size: 28),
                ],
              ),
            ),

            // Likes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '${_post.likesCount} beğenme',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),

            // Caption
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  children: [
                    TextSpan(
                      text: '${_post.authorName} ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: _post.content),
                  ],
                ),
              ),
            ),

            // Time
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(
                _post.timeAgo,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ),
            
            const SizedBox(height: 24),
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
