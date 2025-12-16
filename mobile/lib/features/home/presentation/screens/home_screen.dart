import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/widgets/post_card.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/core/models/post.dart';
import 'package:mobile/core/cubit/mode_cubit.dart';
import 'package:mobile/core/models/app_mode_state.dart';
import '../../../team/presentation/screens/create_challenge_screen.dart';
import '../../data/posts_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  final PostsRepository _postsRepo = getIt<PostsRepository>();
  
  List<Post> _posts = [];
  bool _isLoading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final posts = await _postsRepo.getFeed();
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Like işlemi başarısız: $e')),
      );
    }
  }

  void _challengeTeam(Post post) {
    if (!mounted) return;

    final modeState = context.read<ModeCubit>().state;
    
    if (!modeState.isTeamMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meydan okumak için takım moduna geçmelisiniz')),
      );
      return;
    }
    
    // Check if trying to challenge own team
    if (modeState.teamId == post.authorId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kendi takımınıza meydan okuyamazsınız')),
      );
      return;
    }
    
    // Navigate to create challenge with the challenged team
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateChallengeScreen(
          challengerTeamId: modeState.teamId!,
          preselectedTeamId: post.authorId,
        ),
      ),
    );
  }

  bool _shouldShowChallengeButton(Post post) {
    // Show button on all team posts - the action handler will check permissions
    return post.authorType == 'team';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'CHALLENGER',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: theme.colorScheme.primary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-post'),
        icon: const Icon(Icons.add),
        label: const Text('Gönderi'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.black,
      ),
      body: _buildBody(context, theme),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme) {
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
            Icon(Icons.feed_outlined, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'Henüz gönderi yok',
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'İlk gönderiyi sen paylaş!',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return BlocBuilder<ModeCubit, AppModeState>(
      builder: (context, modeState) {
        return RefreshIndicator(
          onRefresh: _loadPosts,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // Posts
              ..._posts.map((post) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: PostCard(
                    post: post,
                    onLikeTap: () => _toggleLike(post),
                    onCommentTap: () {
                      // TODO: Navigate to comments
                    },
                    showChallengeButton: true,
                    onChallengeTap: () => _challengeTeam(post),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
