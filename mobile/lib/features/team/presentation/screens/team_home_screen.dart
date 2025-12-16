import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/cubit/mode_cubit.dart';
import '../../../../core/widgets/mode_switcher_button.dart';
import '../../../../core/widgets/post_card.dart';
import '../../../../core/models/post.dart';
import '../../../../core/di/service_locator.dart';
import '../../../home/data/posts_repository.dart';

class TeamHomeScreen extends StatefulWidget {
  const TeamHomeScreen({super.key});

  @override
  State<TeamHomeScreen> createState() => _TeamHomeScreenState();
}

class _TeamHomeScreenState extends State<TeamHomeScreen> {
  final PostsRepository _postsRepo = getIt<PostsRepository>();
  
  List<Post> _posts = [];
  bool _isLoading = true;
  String? _error;
  String? _lastTeamId; // Track last loaded team

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDataIfNeeded());
  }

  void _loadDataIfNeeded() {
    final modeState = context.read<ModeCubit>().state;
    if (modeState.isTeamMode && modeState.teamId != _lastTeamId) {
      _lastTeamId = modeState.teamId;
      _loadPosts();
    }
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final posts = await _postsRepo.getFeed();
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleLike(Post post) async {
    try {
      final liked = await _postsRepo.toggleLike(post.id);
      setState(() {
        final index = _posts.indexWhere((p) => p.id == post.id);
        if (index != -1) {
          _posts[index] = post.copyWith(
            isLiked: liked,
            likesCount: liked ? post.likesCount + 1 : post.likesCount - 1,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Like işlemi başarısız: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocListener<ModeCubit, dynamic>(
      listener: (context, state) {
        // When team changes, reload posts
        if (state.isTeamMode && state.teamId != _lastTeamId) {
          _lastTeamId = state.teamId;
          _loadPosts();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Takım Ana Sayfa'),
          centerTitle: true,
          actions: [
            // Notifications icon (first - more user friendly)
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              tooltip: 'Bildirimler',
              onPressed: () => context.push('/notifications'),
            ),
            // Team Chat icon
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              tooltip: 'Takım Sohbeti',
              onPressed: () => context.push('/team-chat'),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadPosts,
          child: _buildBody(theme),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/create-post'),
          icon: const Icon(Icons.add),
          label: const Text('Paylaş'),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.black,
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('Hata: $_error', style: TextStyle(color: Colors.red[300])),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPosts,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield, size: 80, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'Takım Modundasınız',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Henüz gönderi yok - İlk gönderiyi takımın için paylaş!',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.feed, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Takım Akışı',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ..._posts.map((post) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: PostCard(
            post: post,
            onLikeTap: () => _toggleLike(post),
            onCommentTap: () {},
          ),
        )),
      ],
    );
  }
}
