import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/models/post.dart';
import '../../../home/data/posts_repository.dart';
import '../../../home/presentation/screens/post_detail_screen.dart';

class ProfilePostsTab extends StatefulWidget {
  final String userId;

  const ProfilePostsTab({super.key, required this.userId});

  @override
  State<ProfilePostsTab> createState() => _ProfilePostsTabState();
}

class _ProfilePostsTabState extends State<ProfilePostsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PostsRepository _postsRepo = getIt<PostsRepository>();
  StreamSubscription? _postSubscription;
  
  List<Post> _mediaPosts = [];
  List<Post> _textPosts = [];
  bool _isLoadingMedia = true;
  bool _isLoadingText = true;

  @override
  void initState() {
    super.initState();
    print('ProfilePostsTab initState - userId: ${widget.userId}');
    _tabController = TabController(length: 2, vsync: this);
    _loadPosts();
    
    // Listen for new posts
    _postSubscription = _postsRepo.onPostCreated.listen((_) {
      print('ProfilePostsTab: New post detected, reloading...');
      _loadPosts();
    });
  }

  @override
  void dispose() {
    _postSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    print('ProfilePostsTab _loadPosts started');
    // Load media posts
    try {
      final media = await _postsRepo.getUserPosts(widget.userId, type: 'media');
      print('ProfilePostsTab media posts loaded: ${media.length}');
      setState(() {
        _mediaPosts = media;
        _isLoadingMedia = false;
      });
    } catch (e) {
      print('ProfilePostsTab media error: $e');
      setState(() => _isLoadingMedia = false);
    }

    // Load text posts
    try {
      final text = await _postsRepo.getUserPosts(widget.userId, type: 'text');
      print('ProfilePostsTab text posts loaded: ${text.length}');
      setState(() {
        _textPosts = text;
        _isLoadingText = false;
      });
    } catch (e) {
      print('ProfilePostsTab text error: $e');
      setState(() => _isLoadingText = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Tab bar
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            labelColor: Colors.black,
            unselectedLabelColor: Colors.white70,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.photo_library, size: 20),
                    const SizedBox(width: 8),
                    Text('Medya (${_mediaPosts.length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.article, size: 20),
                    const SizedBox(width: 8),
                    Text('Yazılar (${_textPosts.length})'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Media Grid (Instagram style)
              _buildMediaGrid(),
              // Text Posts (Twitter style)
              _buildTextList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMediaGrid() {
    if (_isLoadingMedia) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_mediaPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 12),
            Text(
              'Henüz medya yok',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: _mediaPosts.length,
      itemBuilder: (context, index) {
        final post = _mediaPosts[index];
        return GestureDetector(
          onTap: () => _openPostDetail(post),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image or video thumbnail
              if (post.mediaType == MediaType.image)
                Image.network(
                  post.mediaUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[800],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                )
              else if (post.mediaType == MediaType.video)
                Container(
                  color: Colors.black,
                  child: post.mediaThumbnailUrl != null
                      ? Image.network(post.mediaThumbnailUrl!, fit: BoxFit.cover)
                      : const Icon(Icons.videocam, color: Colors.white24),
                ),
              
              // Video indicator
              if (post.mediaType == MediaType.video)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _openPostDetail(Post post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(post: post),
      ),
    );
  }

  Widget _buildTextList() {
    if (_isLoadingText) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_textPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 12),
            Text(
              'Henüz yazı yok',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: _textPosts.length,
      separatorBuilder: (_, __) => Divider(color: Colors.grey[800], height: 1),
      itemBuilder: (context, index) {
        final post = _textPosts[index];
        return GestureDetector(
          onTap: () => _openPostDetail(post),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.content,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      post.timeAgo,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.favorite, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      '${post.likesCount}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      '${post.commentsCount}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
