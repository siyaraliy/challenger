import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/cubit/mode_cubit.dart';
import '../../../../core/models/app_mode_state.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/models/post.dart';
import '../../../../core/models/team.dart';
import '../../../../core/widgets/video_player_widget.dart';
import '../../../../core/widgets/mode_switcher_button.dart';
import '../../../home/data/posts_repository.dart';
import '../../data/repositories/team_repository.dart';

class TeamProfileScreen extends StatefulWidget {
  const TeamProfileScreen({super.key});

  @override
  State<TeamProfileScreen> createState() => _TeamProfileScreenState();
}

class _TeamProfileScreenState extends State<TeamProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PostsRepository _postsRepo = getIt<PostsRepository>();
  final TeamRepository _teamRepo = getIt<TeamRepository>();
  
  Team? _team;
  List<Post> _mediaPosts = [];
  List<Post> _textPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTeamData();
  }

  @override
  void dispose() {
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
      
      // Load team posts
      // Note: We'll use a simple filter since backend doesn't have team-specific endpoint yet
      final allPosts = await _postsRepo.getFeed();
      final teamPosts = allPosts.where((p) => p.authorType == 'team' && p.authorId == teamId).toList();
      
      setState(() {
        _team = team;
        _mediaPosts = teamPosts.where((p) => p.mediaType != MediaType.none).toList();
        _textPosts = teamPosts.where((p) => p.mediaType == MediaType.none).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading team data: $e');
      setState(() => _isLoading = false);
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
    if (_mediaPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 12),
            Text('Henüz medya yok', style: TextStyle(color: Colors.grey[500])),
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
          onTap: () => _openMediaViewer(post),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (post.mediaType == MediaType.image)
                Image.network(post.mediaUrl!, fit: BoxFit.cover)
              else
                Container(
                  color: Colors.black,
                  child: const Icon(Icons.videocam, color: Colors.white24),
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
    );
  }

  void _openMediaViewer(Post post) {
    if (post.mediaType == MediaType.video) {
      VideoPlayerDialog.show(context, post.mediaUrl!);
    } else {
      showDialog(
        context: context,
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: InteractiveViewer(child: Image.network(post.mediaUrl!)),
          ),
        ),
      );
    }
  }

  Widget _buildTextList() {
    if (_textPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 12),
            Text('Henüz yazı yok', style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: _textPosts.length,
      separatorBuilder: (_, __) => Divider(color: Colors.grey[800]),
      itemBuilder: (context, index) {
        final post = _textPosts[index];
        return Padding(
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
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
