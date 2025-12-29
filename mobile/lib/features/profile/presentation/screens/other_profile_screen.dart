import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/user_profile.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/profile_bloc.dart';
import '../widgets/profile_posts_tab.dart';

class OtherProfileScreen extends StatelessWidget {
  final String userId;

  const OtherProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileBloc>()..add(ProfileLoadRequested(userId)),
      child: _OtherProfileView(userId: userId),
    );
  }
}

class _OtherProfileView extends StatelessWidget {
  final String userId;

  const _OtherProfileView({required this.userId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Check if this is actually the current user (e.g. navigated from a link)
    final authState = context.read<AuthBloc>().state;
    final currentUserId = (authState is AuthAuthenticated) ? authState.user.id : null;
    final isMe = currentUserId == userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        centerTitle: true,
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProfileLoaded) {
            return _buildProfileContent(context, theme, state.profile, state.isFollowing, isMe);
          }

          return const Center(child: Text('Profil yüklenemedi'));
        },
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context, 
    ThemeData theme, 
    UserProfile profile, 
    bool isFollowing,
    bool isMe,
  ) {
    return Column(
      children: [
        // Profile Header
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Avatar
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[800],
                backgroundImage: profile.avatarUrl != null 
                    ? NetworkImage(profile.avatarUrl!) 
                    : null,
                child: profile.avatarUrl == null 
                    ? const Icon(Icons.person, size: 50, color: Colors.white)
                    : null,
              ),

              const SizedBox(height: 16),

              // Name
              Text(
                profile.fullName ?? 'İsim Girilmemiş',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              if (profile.position != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
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
              ],

              if (profile.bio != null) ...[
                const SizedBox(height: 12),
                Text(
                  profile.bio!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
              
              const SizedBox(height: 16),

              // Follow / Unfollow Button
              if (!isMe)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (isFollowing) {
                        context.read<ProfileBloc>().add(ProfileUnfollowUserRequested(userId));
                      } else {
                        context.read<ProfileBloc>().add(ProfileFollowUserRequested(userId));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFollowing ? Colors.grey[800] : theme.colorScheme.primary,
                      foregroundColor: isFollowing ? Colors.white : Colors.black,
                    ),
                    child: Text(isFollowing ? 'Takipten Çıkar' : 'Takip Et'),
                  ),
                ),
            ],
          ),
        ),

        // Counts Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              InkWell(
                onTap: () => context.push('/followers/$userId'),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildCountItem(theme, 'Takipçi', profile.followersCount),
                ),
              ),
              Container(width: 1, height: 24, color: Colors.grey[800]),
              InkWell(
                onTap: () => context.push('/following/$userId'),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildCountItem(theme, 'Takip Edilen', profile.followingCount),
                ),
              ),
            ],
          ),
        ),
        
        const Divider(),

        // Posts
        Expanded(
          child: ProfilePostsTab(userId: userId),
        ),
      ],
    );
  }

  Widget _buildCountItem(ThemeData theme, String label, int count) {
    return Column(
      children: [
        Text(
          '$count',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      ],
    );
  }
}
