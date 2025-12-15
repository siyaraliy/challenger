import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/cubit/mode_cubit.dart';
import '../../../../core/models/app_mode_state.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/models/team.dart';
import '../../data/repositories/team_repository.dart';
import '../../../profile/data/repositories/profile_repository.dart';

class TeamSquadScreen extends StatefulWidget {
  const TeamSquadScreen({super.key});

  @override
  State<TeamSquadScreen> createState() => _TeamSquadScreenState();
}

class _TeamSquadScreenState extends State<TeamSquadScreen> {
  final TeamRepository _teamRepo = getIt<TeamRepository>();
  final ProfileRepository _profileRepo = getIt<ProfileRepository>();

  Team? _team;
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  String? _captainId;
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
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final modeState = context.read<ModeCubit>().state;
    if (!modeState.isTeamMode || modeState.teamId == null) return;

    setState(() => _isLoading = true);

    try {
      final teamId = modeState.teamId!;
      final team = await _teamRepo.getTeam(teamId);
      final memberIds = await _teamRepo.getTeamMembers(teamId);

      final members = <Map<String, dynamic>>[];
      for (final memberId in memberIds) {
        final profile = await _profileRepo.getProfile(memberId);
        if (profile != null) {
          members.add({
            'id': memberId,
            'name': profile.fullName ?? 'İsimsiz Oyuncu',
            'position': profile.position ?? 'Belirsiz',
            'avatarUrl': profile.avatarUrl,
            'isCaptain': team?.captainId == memberId,
          });
        }
      }

      // Sort: captain first
      members.sort((a, b) {
        if (a['isCaptain']) return -1;
        if (b['isCaptain']) return 1;
        return 0;
      });

      setState(() {
        _team = team;
        _captainId = team?.captainId;
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<ModeCubit, AppModeState>(
      listener: (context, modeState) {
        // When team changes, reload data
        if (modeState.isTeamMode && modeState.teamId != _lastTeamId) {
          _lastTeamId = modeState.teamId;
          _loadData();
        }
      },
      builder: (context, modeState) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Kadro'),
            centerTitle: true,
            actions: [
              // Show invite button only if user is captain
              if (_captainId != null)
                IconButton(
                  icon: const Icon(Icons.person_add),
                  tooltip: 'Oyuncu Davet Et',
                  onPressed: () {
                    context.push('/invite-player', extra: {
                      'teamId': modeState.teamId,
                      'teamName': modeState.teamName ?? _team?.name ?? 'Takım',
                    });
                  },
                ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: _members.isEmpty
                      ? _buildEmptyState(theme, modeState)
                      : _buildMembersList(theme),
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              context.push('/invite-player', extra: {
                'teamId': modeState.teamId,
                'teamName': modeState.teamName ?? _team?.name ?? 'Takım',
              });
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Davet Et'),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.black,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme, AppModeState modeState) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey[600]),
            const SizedBox(height: 24),
            Text(
              'Henüz Oyuncu Yok',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Takımına oyuncu davet ederek kadroyu oluştur',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                context.push('/invite-player', extra: {
                  'teamId': modeState.teamId,
                  'teamName': modeState.teamName ?? 'Takım',
                });
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Oyuncu Davet Et'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _members.length + 1, // +1 for header
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Icon(Icons.groups, color: theme.colorScheme.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Takım Kadrosu (${_members.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        final member = _members[index - 1];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: member['isCaptain']
                ? Border.all(color: Colors.amber.withValues(alpha: 0.5))
                : null,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                  backgroundImage: member['avatarUrl'] != null
                      ? NetworkImage(member['avatarUrl'])
                      : null,
                  child: member['avatarUrl'] == null
                      ? Icon(Icons.person, color: theme.colorScheme.primary)
                      : null,
                ),
                if (member['isCaptain'])
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star, size: 14, color: Colors.black),
                    ),
                  ),
              ],
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    member['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (member['isCaptain'])
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'KAPTAN',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                member['position'],
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
          ),
        );
      },
    );
  }
}
