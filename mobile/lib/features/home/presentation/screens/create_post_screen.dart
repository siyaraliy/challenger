import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/cubit/mode_cubit.dart';
import '../../../../core/models/app_mode_state.dart';
import '../../../../core/models/post.dart';
import '../../data/posts_repository.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final PostsRepository _postsRepo = getIt<PostsRepository>();
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  File? _selectedFile;
  MediaType _mediaType = MediaType.none;
  bool _isLoading = false;

  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        _selectedFile = File(image.path);
        _mediaType = MediaType.image;
      });
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 60),
    );
    if (video != null) {
      setState(() {
        _selectedFile = File(video.path);
        _mediaType = MediaType.video;
      });
    }
  }

  void _removeMedia() {
    setState(() {
      _selectedFile = null;
      _mediaType = MediaType.none;
    });
  }

  Future<void> _createPost() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir içerik yazın')),
      );
      return;
    }

    final userId = _currentUserId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oturum açmanız gerekiyor')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final modeState = context.read<ModeCubit>().state;
      
      String? mediaUrl;
      if (_selectedFile != null) {
        // Upload media
        mediaUrl = await _postsRepo.uploadMedia(
          _selectedFile!,
          authorType: modeState.isTeamMode ? 'team' : 'user',
          authorId: modeState.isTeamMode ? modeState.teamId! : userId,
        );
      }

      await _postsRepo.createPost(
        content: _contentController.text.trim(),
        mediaType: _mediaType,
        mediaUrl: mediaUrl,
        contextType: modeState.isTeamMode ? 'team' : 'user',
        contextId: modeState.isTeamMode ? modeState.teamId : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gönderi paylaşıldı!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
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
            title: Text(
              modeState.isTeamMode ? 'Takım Gönderisi' : 'Yeni Gönderi',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            actions: [
              TextButton(
                onPressed: _isLoading ? null : _createPost,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Paylaş',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author indicator
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: modeState.isTeamMode
                            ? theme.colorScheme.primary
                            : Colors.grey,
                        child: Icon(
                          modeState.isTeamMode ? Icons.shield : Icons.person,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            modeState.isTeamMode
                                ? modeState.teamName ?? 'Takım'
                                : 'Sen',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            modeState.isTeamMode
                                ? 'Takım olarak paylaşılacak'
                                : 'Kullanıcı olarak paylaşılacak',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),

                // Content input
                TextField(
                  controller: _contentController,
                  maxLines: 5,
                  maxLength: 500,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Ne düşünüyorsun?',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Media preview
                if (_selectedFile != null) ...[
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _mediaType == MediaType.image
                            ? Image.file(
                                _selectedFile!,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: double.infinity,
                                height: 200,
                                color: Colors.black,
                                child: const Center(
                                  child: Icon(
                                    Icons.videocam,
                                    size: 48,
                                    color: Colors.white54,
                                  ),
                                ),
                              ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: _removeMedia,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Media buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _pickImage,
                        icon: const Icon(Icons.image),
                        label: const Text('Resim'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _pickVideo,
                        icon: const Icon(Icons.videocam),
                        label: const Text('Video'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[300], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Resim max 10MB, video max 50MB ve 60 saniye',
                          style: TextStyle(color: Colors.blue[300], fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
