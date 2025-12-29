import 'package:flutter/material.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/features/chat/data/chat_repository.dart';
import '../../../../core/models/chat_room.dart';

class ShareBottomSheet extends StatefulWidget {
  final String postId;

  const ShareBottomSheet({
    super.key,
    required this.postId,
  });

  @override
  State<ShareBottomSheet> createState() => _ShareBottomSheetState();
}

class _ShareBottomSheetState extends State<ShareBottomSheet> {
  final ChatRepository _chatRepo = getIt<ChatRepository>();
  final TextEditingController _searchController = TextEditingController();
  
  List<ChatRoom> _recentChats = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = true;
  String _searchQuery = '';
  Set<String> _sendingTo = {}; // Track which items are being sent to

  @override
  void initState() {
    super.initState();
    _loadRecentChats();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
      _onSearchChanged();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentChats() async {
    try {
      final chats = await _chatRepo.getMyChats();
      if (mounted) {
        setState(() {
          _recentChats = chats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onSearchChanged() async {
    if (_searchQuery.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    try {
      final results = await _chatRepo.searchUsers(_searchQuery);
      if (mounted) {
        setState(() => _searchResults = results);
      }
    } catch (e) {
      print('Search error: $e');
    }
  }

  Future<void> _sendToChat(ChatRoom room) async {
    if (_sendingTo.contains(room.id)) return;

    setState(() => _sendingTo.add(room.id));

    try {
      await _chatRepo.sendMessage(
        room.id,
        'Bir gönderi paylaştı',
        messageType: 'post_share',
        sharedPostId: widget.postId,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${room.name ?? "Kullanıcı"} ile paylaşıldı')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gönderilemedi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sendingTo.remove(room.id));
      }
    }
  }

  Future<void> _sendToUser(Map<String, dynamic> user) async {
    final userId = user['id'] as String;
    if (_sendingTo.contains(userId)) return;

    setState(() => _sendingTo.add(userId));

    try {
      // Create or get chat room
      final roomId = await _chatRepo.createDirectChat(userId);
      
      await _chatRepo.sendMessage(
        roomId,
        'Bir gönderi paylaştı',
        messageType: 'post_share',
        sharedPostId: widget.postId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user["full_name"]} ile paylaşıldı')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gönderilemedi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sendingTo.remove(userId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSearching = _searchQuery.isNotEmpty;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Paylaş',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Ara...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : isSearching
                    ? _buildSearchResults(theme)
                    : _buildRecentChats(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentChats(ThemeData theme) {
    if (_recentChats.isEmpty) {
      return Center(
        child: Text(
          'Sohbet bulunamadı',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _recentChats.length,
      itemBuilder: (context, index) {
        final chat = _recentChats[index];
        final isSending = _sendingTo.contains(chat.id);

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: chat.avatarUrl != null ? NetworkImage(chat.avatarUrl!) : null,
            child: chat.avatarUrl == null ? Text(chat.name?[0].toUpperCase() ?? '?') : null,
          ),
          title: Text(chat.name ?? 'Bilinmeyen'),
          subtitle: Text(
            chat.type == 'team_group' ? 'Takım Sohbeti' : 'Kişisel Sohbet',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          trailing: _buildSendButton(
            isSending: isSending,
            onTap: () => _sendToChat(chat),
            theme: theme,
          ),
        );
      },
    );
  }

  Widget _buildSearchResults(ThemeData theme) {
    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          'Sonuç bulunamadı',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        final userId = user['id'] as String;
        final isSending = _sendingTo.contains(userId);

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
            child: user['avatar_url'] == null ? const Icon(Icons.person) : null,
          ),
          title: Text(user['full_name'] ?? 'İsimsiz'),
          trailing: _buildSendButton(
            isSending: isSending,
            onTap: () => _sendToUser(user),
            theme: theme,
          ),
        );
      },
    );
  }

  Widget _buildSendButton({
    required bool isSending,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return ElevatedButton(
      onPressed: isSending ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSending ? Colors.grey : theme.colorScheme.primary,
        foregroundColor: isSending ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: const Size(64, 32),
      ),
      child: isSending
          ? const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Text('Gönder', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}
