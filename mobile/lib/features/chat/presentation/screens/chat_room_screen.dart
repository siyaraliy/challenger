import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/chat_room_bloc.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input_field.dart';
import '../../../../core/models/chat_participant.dart';

/// Screen for a single chat room with messages
class ChatRoomScreen extends StatefulWidget {
  final String roomId;
  final String? roomName;
  final String? contextType; // 'user' or 'team'
  final String? contextId;   // userId or teamId

  const ChatRoomScreen({
    super.key,
    required this.roomId,
    this.roomName,
    this.contextType,
    this.contextId,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _scrollController = ScrollController();
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final showButton = _scrollController.offset > 200;
    if (showButton != _showScrollToBottom) {
      setState(() => _showScrollToBottom = showButton);
    }
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatRoomBloc, ChatRoomState>(
      builder: (context, state) {
        final roomName = state is ChatRoomLoaded
            ? state.roomDetails?.name ?? widget.roomName
            : widget.roomName;

        final isAdmin = state is ChatRoomLoaded && 
            (state.roomDetails?.isAdmin ?? false);
        
        final pendingCount = state is ChatRoomLoaded 
            ? state.pendingRequests.length 
            : 0;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roomName ?? 'Sohbet',
                  style: const TextStyle(fontSize: 16),
                ),
                if (state is ChatRoomLoaded && state.roomDetails != null)
                  Text(
                    state.roomDetails!.isTeamGroup
                        ? 'Takım sohbeti'
                        : 'Özel mesaj',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
              ],
            ),
            actions: [
              // Pending requests badge for admin
              if (isAdmin && pendingCount > 0)
                IconButton(
                  onPressed: () => _showPendingRequestsSheet(context, state),
                  icon: Badge(
                    label: Text('$pendingCount'),
                    child: const Icon(Icons.person_add),
                  ),
                ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  // Handle menu actions
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'info',
                    child: ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('Sohbet Bilgisi'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              // Messages list
              Expanded(
                child: _buildMessageList(state),
              ),

              // Input field
              if (state is ChatRoomLoaded)
                MessageInputField(
                  isSending: state.isSending,
                  onSend: (content) {
                    context.read<ChatRoomBloc>().add(SendMessage(
                      content,
                      contextType: widget.contextType,
                      contextId: widget.contextId,
                    ));
                  },
                ),
            ],
          ),
          floatingActionButton: _showScrollToBottom
              ? FloatingActionButton.small(
                  onPressed: _scrollToBottom,
                  child: const Icon(Icons.keyboard_arrow_down),
                )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.miniCenterFloat,
        );
      },
    );
  }

  Widget _buildMessageList(ChatRoomState state) {
    if (state is ChatRoomLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is ChatRoomError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<ChatRoomBloc>().add(LoadChatRoom(widget.roomId));
              },
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (state is ChatRoomLoaded) {
      if (state.messages.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 16),
              Text(
                'Henüz mesaj yok',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'İlk mesajı sen gönder!',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      }

      return NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // Load more when near the end
          if (notification is ScrollEndNotification &&
              _scrollController.position.extentAfter < 200 &&
              state.hasMore) {
            context.read<ChatRoomBloc>().add(const LoadMoreMessages());
          }
          return false;
        },
        child: ListView.builder(
          controller: _scrollController,
          reverse: true, // Messages start from bottom
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: state.messages.length,
          itemBuilder: (context, index) {
            final message = state.messages[index];
            final previousMessage = index < state.messages.length - 1
                ? state.messages[index + 1]
                : null;

            // Show avatar if different sender or more than 5 minutes apart
            final showAvatar = previousMessage == null ||
                previousMessage.senderId != message.senderId ||
                message.createdAt.difference(previousMessage.createdAt).inMinutes > 5;

            return ChatBubble(
              message: message,
              showAvatar: showAvatar,
            );
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _showPendingRequestsSheet(BuildContext context, ChatRoomState state) {
    if (state is! ChatRoomLoaded) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) => _PendingRequestsSheet(
        requests: state.pendingRequests,
        onApprove: (participantId) {
          context.read<ChatRoomBloc>().add(ApproveJoinRequest(participantId));
          Navigator.pop(bottomSheetContext);
        },
        onReject: (participantId) {
          context.read<ChatRoomBloc>().add(RejectJoinRequest(participantId));
          Navigator.pop(bottomSheetContext);
        },
      ),
    );
  }
}

/// Bottom sheet for pending join requests
class _PendingRequestsSheet extends StatelessWidget {
  final List<ChatParticipant> requests;
  final Function(String) onApprove;
  final Function(String) onReject;

  const _PendingRequestsSheet({
    required this.requests,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'Katılım İstekleri',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${requests.length} kişi sohbete katılmak istiyor',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),

          // Request list
          if (requests.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Bekleyen istek yok',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: request.avatarUrl != null
                        ? NetworkImage(request.avatarUrl!)
                        : null,
                    child: request.avatarUrl == null
                        ? Text(
                            (request.name ?? '?')[0].toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  title: Text(
                    request.name ?? 'Bilinmeyen',
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => onReject(request.participantId),
                        icon: const Icon(Icons.close, color: Colors.red),
                      ),
                      IconButton(
                        onPressed: () => onApprove(request.participantId),
                        icon: const Icon(Icons.check, color: Colors.green),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
