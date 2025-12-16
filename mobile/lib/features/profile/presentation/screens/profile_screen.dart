import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/cubit/mode_cubit.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/widgets/mode_switcher_button.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../team/data/repositories/team_repository.dart';
import '../bloc/profile_bloc.dart';
import '../widgets/profile_edit_dialog.dart';
import '../widgets/profile_posts_tab.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _userId = authState.user.id;
      context.read<ProfileBloc>().add(ProfileLoadRequested(authState.user.id));
    } else if (authState is AuthGuest && authState.user != null) {
      _userId = authState.user!.id;
      context.read<ProfileBloc>().add(ProfileLoadRequested(authState.user!.id));
    }
  }

  Future<void> _checkAndNavigateToTeam() async {
    try {
      final authState = context.read<AuthBloc>().state;
      String? userId;
      
      if (authState is AuthAuthenticated) {
        userId = authState.user.id;
      } else if (authState is AuthGuest && authState.user != null) {
        userId = authState.user!.id;
      }

      if (userId == null) return;

      final teamRepo = getIt<TeamRepository>();
      
      // Get all teams where user is a member (includes captain)
      final teams = await teamRepo.getMyTeams(userId);

      if (!mounted) return;

      // Always show dialog - whether user has teams or not
      _showTeamSelectionDialog(teams);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  void _showTeamSelectionDialog(List<dynamic> teams) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Takımlarım'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Team list
              if (teams.isNotEmpty) ...[
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: teams.length,
                  itemBuilder: (context, index) {
                    final team = teams[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                          backgroundImage: team.logoUrl != null ? NetworkImage(team.logoUrl!) : null,
                          child: team.logoUrl == null
                              ? Icon(Icons.shield, color: theme.colorScheme.primary)
                              : null,
                        ),
                        title: Text(team.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Takıma geç', style: TextStyle(fontSize: 12)),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.primary),
                        onTap: () async {
                          Navigator.pop(dialogContext);
                          final modeCubit = this.context.read<ModeCubit>();
                          await modeCubit.switchToTeam(team.id, team.name);
                          if (mounted) {
                            this.context.go('/team-home');
                          }
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.group_off, size: 48, color: Colors.grey[600]),
                      const SizedBox(height: 12),
                      Text(
                        'Henüz bir takıma üye değilsiniz',
                        style: TextStyle(color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        context.push('/join-team');
                      },
                      icon: const Icon(Icons.link, size: 18),
                      label: const Text('Takıma Katıl'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        context.push('/create-team');
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Takım Oluştur'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null && mounted) {
        context.read<ProfileBloc>().add(
              ProfileAvatarUploadRequested(File(image.path)),
            );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resim seçilemedi: $e')),
        );
      }
    }
  }

  void _showEditDialog(UserProfile profile) {
    final profileBloc = context.read<ProfileBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => ProfileEditDialog(
        profile: profile,
        onSave: (updatedProfile) {
          profileBloc.add(ProfileUpdateRequested(updatedProfile));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        centerTitle: true,
        actions: [
          const ModeSwitcherButton(),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
          ),
        ],
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is ProfileUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profil güncellendi')),
            );
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProfileAvatarUploading) {
            return Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Resim yükleniyor...', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            );
          }

          if (state is ProfileLoaded) {
            return _buildProfileContent(theme, state.profile);
          }

          return const Center(child: Text('Profil yüklenemedi'));
        },
      ),
    );
  }

  Widget _buildProfileContent(ThemeData theme, UserProfile profile) {
    return Column(
      children: [
        // Compact Profile Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(50),
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.colorScheme.primary, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[700],
                        backgroundImage: profile.avatarUrl != null
                            ? NetworkImage(profile.avatarUrl!)
                            : null,
                        child: profile.avatarUrl == null
                            ? const Icon(Icons.person, size: 40, color: Colors.white)
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, size: 14, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Name and Position
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.fullName ?? 'İsim Girilmemiş',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (profile.position != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colorScheme.primary),
                        ),
                        child: Text(
                          AppConstants.getPositionName(profile.position!) ?? profile.position!,
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (profile.bio != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        profile.bio!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
              // Edit button
              IconButton(
                onPressed: () => _showEditDialog(profile),
                icon: Icon(Icons.edit, color: theme.colorScheme.primary),
              ),
            ],
          ),
        ),

        // Team Section Card
        _buildTeamSection(theme),

        // Divider
        Container(height: 1, color: Colors.grey[800]),

        // Posts tabs
        if (_userId != null)
          Expanded(
            child: ProfilePostsTab(userId: _userId!),
          ),
      ],
    );
  }

  Widget _buildTeamSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.2),
              Colors.transparent,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.shield, color: theme.colorScheme.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Takım',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Takım oluştur veya mevcut takıma geç',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _checkAndNavigateToTeam,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Git'),
            ),
          ],
        ),
      ),
    );
  }
}
