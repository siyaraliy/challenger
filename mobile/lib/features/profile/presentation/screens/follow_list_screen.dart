import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/models/team.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/repositories/profile_repository.dart';
import '../../../team/data/repositories/team_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FollowListScreen extends StatefulWidget {
  final String userId;
  final int initialTab;

  const FollowListScreen({
    super.key,
    required this.userId,
    this.initialTab = 0,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ProfileRepository _profileRepository = getIt<ProfileRepository>();

  List<UserProfile> _followers = [];
  List<UserProfile> _following = [];
  List<Team> _followedTeams = [];
  bool _isLoadingFollowers = true;
  bool _isLoadingFollowing = true;
  String? _currentUserId;

  // Track follow status for each user
  final Map<String, bool> _followStatus = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _loadCurrentUser();
    _loadData();
  }

  void _loadCurrentUser() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _currentUserId = authState.user.id;
    } else if (authState is AuthGuest && authState.user != null) {
      _currentUserId = authState.user!.id;
    }
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadFollowers(),
      _loadFollowing(),
    ]);
  }

  Future<void> _loadFollowers() async {
    try {
      final followers = await _profileRepository.getFollowers(widget.userId);
      if (mounted) {
        setState(() {
          _followers = followers;
          _isLoadingFollowers = false;
        });
        // Check follow status for each follower
        for (final user in followers) {
          _checkFollowStatus(user.id);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingFollowers = false);
      }
    }
  }

  Future<void> _loadFollowing() async {
    try {
      final teamRepo = getIt<TeamRepository>();
      final following = await _profileRepository.getFollowing(widget.userId);
      final followedTeams = await teamRepo.getFollowedTeams(widget.userId);
      
      if (mounted) {
        setState(() {
          _following = following;
          _followedTeams = followedTeams;
          _isLoadingFollowing = false;
        });
        // Check follow status for each following
        for (final user in following) {
          _checkFollowStatus(user.id);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingFollowing = false);
      }
    }
  }

  Future<void> _checkFollowStatus(String userId) async {
    if (_currentUserId == null || userId == _currentUserId) return;
    
    final isFollowing = await _profileRepository.isFollowing(userId);
    if (mounted) {
      setState(() {
        _followStatus[userId] = isFollowing;
      });
    }
  }

  Future<void> _toggleFollow(String userId) async {
    if (_currentUserId == null) return;

    final isCurrentlyFollowing = _followStatus[userId] ?? false;

    try {
      if (isCurrentlyFollowing) {
        await _profileRepository.unfollowUser(userId);
      } else {
        await _profileRepository.followUser(userId);
      }

      if (mounted) {
        setState(() {
          _followStatus[userId] = !isCurrentlyFollowing;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Takip'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: 'Takipçiler (${_followers.length})'),
            Tab(text: 'Takip Edilen (${_following.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserList(_followers, _isLoadingFollowers),
          _buildFollowingList(),
        ],
      ),
    );
  }

  Widget _buildFollowingList() {
    if (_isLoadingFollowing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_following.isEmpty && _followedTeams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'Henüz kimse yok',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        children: [
          if (_following.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Kişiler',
                style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            ..._following.map((user) => _buildUserTile(user)),
          ],
          if (_followedTeams.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Takımlar',
                style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            ..._followedTeams.map((team) => _buildTeamTile(team)),
          ],
        ],
      ),
    );
  }

  Widget _buildUserList(List<UserProfile> users, bool isLoading) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'Henüz kimse yok',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return _buildUserTile(user);
        },
      ),
    );
  }

  Widget _buildTeamTile(Team team) {
    final theme = Theme.of(context);
    
    return ListTile(
      onTap: () => context.push('/team/${team.id}'),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[800],
          image: team.logoUrl != null ? DecorationImage(image: NetworkImage(team.logoUrl!), fit: BoxFit.cover) : null,
        ),
        child: team.logoUrl == null ? const Icon(Icons.shield, color: Colors.white, size: 24) : null,
      ),
      title: Text(
        team.name,
        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
      ),
      subtitle: Text(
        'Takım',
        style: TextStyle(color: theme.colorScheme.primary, fontSize: 12),
      ),
      trailing: widget.userId == _currentUserId 
          ? ElevatedButton(
              onPressed: () async {
                try {
                  await getIt<TeamRepository>().unfollowTeam(team.id);
                  _loadFollowing(); // Refresh
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Hata: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Takibi Bırak', style: TextStyle(fontSize: 12)),
            )
          : null,
    );
  }

  Widget _buildUserTile(UserProfile user) {
    final theme = Theme.of(context);
    final isMe = user.id == _currentUserId;
    final isFollowing = _followStatus[user.id] ?? false;

    return ListTile(
      onTap: () {
        if (isMe) {
          context.push('/profile');
        } else {
          context.push('/user/${user.id}');
        }
      },
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey[800],
        backgroundImage:
            user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
        child: user.avatarUrl == null
            ? const Icon(Icons.person, color: Colors.white)
            : null,
      ),
      title: Text(
        user.fullName ?? 'İsimsiz Kullanıcı',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      subtitle: user.position != null
          ? Text(
              AppConstants.getPositionName(user.position!) ?? user.position!,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            )
          : null,
      trailing: isMe
          ? null
          : SizedBox(
              width: 100,
              child: ElevatedButton(
                onPressed: () => _toggleFollow(user.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isFollowing ? Colors.grey[800] : theme.colorScheme.primary,
                  foregroundColor: isFollowing ? Colors.white : Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isFollowing ? 'Takipte' : 'Takip Et',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
    );
  }
}
