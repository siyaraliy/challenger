import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/cubit/mode_cubit.dart';
import '../../../../core/models/app_mode_state.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/models/post.dart';
import '../../../../core/models/team.dart';
import '../../../../core/widgets/mode_switcher_button.dart';
import '../../../home/data/posts_repository.dart';
import '../../../home/presentation/screens/post_detail_screen.dart';
import '../../data/repositories/team_repository.dart';
import '../../data/repositories/challenge_repository.dart';

class TeamProfileScreen extends StatefulWidget {
  const TeamProfileScreen({super.key});

  @override
  State<TeamProfileScreen> createState() => _TeamProfileScreenState();
}

class _TeamProfileScreenState extends State<TeamProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PostsRepository _postsRepo = getIt<PostsRepository>();
  final TeamRepository _teamRepo = getIt<TeamRepository>();
  final ChallengeRepository _challengeRepo = getIt<ChallengeRepository>();
  StreamSubscription? _postSubscription;
  
  Team? _team;
  List<Post> _mediaPosts = [];
  List<Post> _textPosts = [];
  bool _isLoading = true;
  int _totalPoints = 0;
  int _matchesPlayed = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTeamData();

    // Listen for new posts
    _postSubscription = _postsRepo.onPostCreated.listen((_) {
       if (mounted) {
         _loadTeamData();
       }
    });
  }

  @override
  void dispose() {
    _postSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTeamData() async {
    final modeState = context.read<ModeCubit>().state;
    if (!modeState.isTeamMode || modeState.teamId == null) return;

    final teamId = modeState.teamId!;

    try {
      // Load team info
      final team = await _teamRepo.getTeam(teamId);
      
      // Load team points
      final points = await _challengeRepo.getTeamPoints(teamId);
      
      // Load team posts
      final allPosts = await _postsRepo.getFeed();
      final teamPosts = allPosts.where((p) => p.authorType == 'team' && p.authorId == teamId).toList();
      
      setState(() {
        _team = team;
        _totalPoints = points?['total_points'] ?? 0;
        _matchesPlayed = points?['matches_played'] ?? 0;
        _mediaPosts = teamPosts.where((p) => p.mediaType != MediaType.none).toList();
        _textPosts = teamPosts.where((p) => p.mediaType == MediaType.none).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading team data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<ModeCubit, AppModeState>(
      builder: (context, modeState) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Takım Profili'),
            centerTitle: true,
            actions: const [
              ModeSwitcherButton(),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Team header
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Team logo
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: theme.colorScheme.primary,
                            backgroundImage: _team?.logoUrl != null
                                ? NetworkImage(_team!.logoUrl!)
                                : null,
                            child: _team?.logoUrl == null
                                ? const Icon(Icons.shield, size: 50, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(height: 16),
                          
                          // Team name
                          Text(
                            modeState.teamName ?? _team?.name ?? 'Takım',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Points display
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary.withValues(alpha: 0.3),
                                  Colors.amber.withValues(alpha: 0.3),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  '$_totalPoints Puan',
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(width: 1, height: 16, color: Colors.amber.withValues(alpha: 0.3)),
                                const SizedBox(width: 12),
                                Text(
                                  '$_matchesPlayed Maç',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Divider
                    Container(height: 1, color: Colors.grey[800]),

                    // Tabs
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
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
                    ),

                    // Tab content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildMediaGrid(),
                          _buildTextList(),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildMediaGrid() {
    return RefreshIndicator(
      onRefresh: _loadTeamData,
      child: _mediaPosts.isEmpty
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 300,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey[600]),
                      const SizedBox(height: 12),
                      Text('Henüz medya yok', style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(4),
              physics: const AlwaysScrollableScrollPhysics(),
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
            ),
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
    return RefreshIndicator(
      onRefresh: _loadTeamData,
      child: _textPosts.isEmpty
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 300,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.article_outlined, size: 48, color: Colors.grey[600]),
                      const SizedBox(height: 12),
                      Text('Henüz yazı yok', style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(8),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _textPosts.length,
              separatorBuilder: (_, __) => Divider(color: Colors.grey[800]),
              itemBuilder: (context, index) {
                final post = _textPosts[index];
                return GestureDetector(
                  onTap: () => _openPostDetail(post),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.content, style: const TextStyle(color: Colors.white, fontSize: 15)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(post.timeAgo, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                            const SizedBox(width: 16),
                            Icon(Icons.favorite, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text('${post.likesCount}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                            const SizedBox(width: 16),
                            Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text('${post.commentsCount}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
