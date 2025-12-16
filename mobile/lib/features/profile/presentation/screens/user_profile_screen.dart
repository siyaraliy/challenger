import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/models/user_profile.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/profile_bloc.dart';
import '../widgets/profile_posts_tab.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String? userId;

    if (authState is AuthAuthenticated) {
      userId = authState.user.id;
    } else if (authState is AuthGuest) {
      userId = authState.user?.id;
    }

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Kullanıcı bulunamadı')),
      );
    }

    return BlocProvider(
      create: (_) => getIt<ProfileBloc>()..add(ProfileLoadRequested(userId!)),
      child: UserProfileView(userId: userId),
    );
  }
}

class UserProfileView extends StatelessWidget {
  final String userId;

  const UserProfileView({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
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

          if (state is ProfileLoaded || state is ProfileUpdated) {
            final profile = state is ProfileLoaded 
                ? state.profile 
                : (state as ProfileUpdated).profile;
            
            return _buildProfileContent(context, theme, profile);
          }

          return const Center(child: Text('Profil yüklenemedi'));
        },
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, ThemeData theme, UserProfile profile) {
    return Column(
      children: [
        // Profile header section
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Avatar
              GestureDetector(
                onTap: () => _pickAndUploadAvatar(context),
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.colorScheme.primary, width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[800],
                        backgroundImage: profile.avatarUrl != null 
                            ? NetworkImage(profile.avatarUrl!) 
                            : null,
                        child: profile.avatarUrl == null 
                            ? const Icon(Icons.person, size: 50, color: Colors.white)
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, size: 16, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Full Name
              Text(
                profile.fullName ?? 'İsimsiz Kullanıcı',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 8),

              // Position
              if (profile.position != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
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

              if (profile.bio != null) ...[
                const SizedBox(height: 12),
                Text(
                  profile.bio!,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 16),

              // Edit Button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () => _showEditDialog(context, profile),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Profili Düzenle'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(color: theme.colorScheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Divider
        Container(height: 1, color: Colors.grey[800]),

        // Posts tabs
        Expanded(
          child: ProfilePostsTab(userId: userId),
        ),
      ],
    );
  }

  Future<void> _pickAndUploadAvatar(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );

    if (image != null && context.mounted) {
      context.read<ProfileBloc>().add(
            ProfileAvatarUploadRequested(File(image.path)),
          );
    }
  }

  void _showEditDialog(BuildContext context, UserProfile profile) {
    final nameController = TextEditingController(text: profile.fullName);
    final bioController = TextEditingController(text: profile.bio);
    String? selectedPosition = profile.position;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Profili Düzenle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Full Name
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(color: Colors.white),
              ),

              const SizedBox(height: 16),

              // Position Dropdown
              StatefulBuilder(
                builder: (_, setState) => DropdownButtonFormField<String>(
                  value: selectedPosition,
                  decoration: const InputDecoration(
                    labelText: 'Mevki',
                    border: OutlineInputBorder(),
                  ),
                  dropdownColor: Theme.of(context).scaffoldBackgroundColor,
                  items: AppConstants.positions.map((pos) {
                    return DropdownMenuItem<String>(
                      value: pos['id'],
                      child: Text(
                        pos['name']!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedPosition = value);
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Bio
              TextField(
                controller: bioController,
                decoration: const InputDecoration(
                  labelText: 'Hakkında',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedProfile = profile.copyWith(
                fullName: nameController.text,
                position: selectedPosition,
                bio: bioController.text,
              );

              context.read<ProfileBloc>().add(ProfileUpdateRequested(updatedProfile));
              Navigator.pop(dialogContext);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}
