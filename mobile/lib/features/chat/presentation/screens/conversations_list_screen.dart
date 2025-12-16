import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/chat_room.dart';
import '../../../../core/di/service_locator.dart';
import '../../data/chat_repository.dart';
import '../bloc/chat_list_bloc.dart';


/// Screen showing list of all conversations
class ConversationsListScreen extends StatefulWidget {
  const ConversationsListScreen({super.key});

  @override
  State<ConversationsListScreen> createState() => _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> {
  @override
  void initState() {
    super.initState();
    // Initial load
    _refreshList();
  }

  void _refreshList() {
    context.read<ChatListBloc>().add(const RefreshChatList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sohbetler'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _showNewChatDialog(context),
            icon: const Icon(Icons.edit_square),
          ),
        ],
      ),
      body: BlocConsumer<ChatListBloc, ChatListState>(
        listener: (context, state) {
          if (state is ChatListLoaded && state.newChatRoomId != null) {
            // Navigate to new chat room
            context.push('/chat/${state.newChatRoomId}');
          }
        },
        builder: (context, state) {
          if (state is ChatListLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ChatListError) {
            return _buildError(context, state.message);
          }

          if (state is ChatListLoaded) {
            if (state.chats.isEmpty) {
              return _buildEmpty(context);
            }
            return _buildChatList(context, state.chats);
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewChatDialog(context),
        child: const Icon(Icons.message),
      ),
    );
  }

  Widget _buildChatList(BuildContext context, List<ChatRoom> chats) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ChatListBloc>().add(const RefreshChatList());
      },
      child: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          return _ChatListItem(
            chat: chat,
            onTap: () {
              // Navigate to chat and refresh list when returning
              context.push('/chat/${chat.id}').then((_) {
                if (context.mounted) {
                  context.read<ChatListBloc>().add(const RefreshChatList());
                }
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 24),
          Text(
            'Henüz sohbet yok',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Yeni bir sohbet başlatmak için + butonuna tıkla',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<ChatListBloc>().add(const LoadChatList());
            },
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  void _showNewChatDialog(BuildContext context) async {
    final roomId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _NewChatBottomSheet(),
    );
    
    // Navigate if a room was created
    if (roomId != null && context.mounted) {
      context.push('/chat/$roomId');
    }
  }
}

/// Single chat list item
class _ChatListItem extends StatelessWidget {
  final ChatRoom chat;
  final VoidCallback onTap;

  const _ChatListItem({
    required this.chat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: chat.isTeamGroup
                ? theme.colorScheme.primary.withValues(alpha: 0.3)
                : Colors.grey[700],
            backgroundImage:
                chat.avatarUrl != null ? NetworkImage(chat.avatarUrl!) : null,
            child: chat.avatarUrl == null
                ? Icon(
                    chat.isTeamGroup ? Icons.groups : Icons.person,
                    color: chat.isTeamGroup
                        ? theme.colorScheme.primary
                        : Colors.white,
                    size: 28,
                  )
                : null,
          ),
          // Unread badge
          if (chat.hasUnread)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  chat.unreadCount > 99 ? '99+' : '${chat.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              chat.displayName,
              style: TextStyle(
                fontWeight: chat.hasUnread ? FontWeight.bold : FontWeight.w500,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (chat.lastMessageAt != null)
            Text(
              _formatTime(chat.lastMessageAt!),
              style: TextStyle(
                fontSize: 12,
                color: chat.hasUnread
                    ? theme.colorScheme.primary
                    : Colors.grey[500],
              ),
            ),
        ],
      ),
      subtitle: chat.lastMessage != null
          ? Text(
              chat.lastMessage!,
              style: TextStyle(
                color: chat.hasUnread ? Colors.white70 : Colors.grey[500],
                fontWeight: chat.hasUnread ? FontWeight.w500 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : Text(
              'Henüz mesaj yok',
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      const days = ['Paz', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt'];
      return days[dateTime.weekday % 7];
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}

/// Bottom sheet for starting a new chat
class _NewChatBottomSheet extends StatefulWidget {
  const _NewChatBottomSheet();

  @override
  State<_NewChatBottomSheet> createState() => _NewChatBottomSheetState();
}

class _NewChatBottomSheetState extends State<_NewChatBottomSheet> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  late final ChatRepository _chatRepository;

  @override
  void initState() {
    super.initState();
    _chatRepository = getIt<ChatRepository>();
    _loadUsers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchUsers(_searchController.text);
  }

  Future<void> _loadUsers() async {
    print('DEBUG: _loadUsers called');
    setState(() => _isLoading = true);
    try {
      final users = await _chatRepository.getAllUsers();
      print('DEBUG: Loaded ${users.length} users');
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('DEBUG: _loadUsers error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _searchUsers(String query) async {
    print('DEBUG: _searchUsers called with: "$query"');
    try {
      final users = await _chatRepository.searchUsers(query);
      print('DEBUG: Search returned ${users.length} users');
      if (mounted) {
        setState(() => _users = users);
      }
    } catch (e) {
      print('DEBUG: _searchUsers error: $e');
    }
  }

  Future<void> _startChat(String userId, String userName) async {
    print('DEBUG: _startChat called with userId: $userId');
    
    try {
      final roomId = await _chatRepository.createDirectChat(userId);
      print('DEBUG: Created/got room: $roomId');
      
      // Pop with roomId so parent can navigate
      if (mounted) {
        Navigator.pop(context, roomId);
      }
    } catch (e) {
      print('DEBUG: _startChat error: $e');
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sohbet açılamadı: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Yeni Sohbet',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),

            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Kullanıcı ara...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // User list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _users.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_search,
                                size: 64,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Kullanıcı bulunamadı',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            final name = user['full_name'] as String? ?? 'Bilinmeyen';
                            final avatarUrl = user['avatar_url'] as String?;
                            final userId = user['id'] as String;

                            return ListTile(
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.grey[700],
                                backgroundImage: avatarUrl != null
                                    ? NetworkImage(avatarUrl)
                                    : null,
                                child: avatarUrl == null
                                    ? Text(
                                        name[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(color: Colors.white),
                              ),
                              onTap: () => _startChat(userId, name),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }
}

