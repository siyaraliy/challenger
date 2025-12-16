import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/models/chat_room.dart';
import '../../data/chat_repository.dart';

// ==================== Events ====================

abstract class ChatListEvent extends Equatable {
  const ChatListEvent();

  @override
  List<Object?> get props => [];
}

class LoadChatList extends ChatListEvent {
  const LoadChatList();
}

class RefreshChatList extends ChatListEvent {
  const RefreshChatList();
}

class CreateDirectChat extends ChatListEvent {
  final String targetUserId;

  const CreateDirectChat(this.targetUserId);

  @override
  List<Object?> get props => [targetUserId];
}

// ==================== States ====================

abstract class ChatListState extends Equatable {
  const ChatListState();

  @override
  List<Object?> get props => [];
}

class ChatListInitial extends ChatListState {
  const ChatListInitial();
}

class ChatListLoading extends ChatListState {
  const ChatListLoading();
}

class ChatListLoaded extends ChatListState {
  final List<ChatRoom> chats;
  final String? newChatRoomId; // For navigation after creating direct chat

  const ChatListLoaded(this.chats, {this.newChatRoomId});

  @override
  List<Object?> get props => [chats, newChatRoomId];

  ChatListLoaded copyWith({
    List<ChatRoom>? chats,
    String? newChatRoomId,
  }) {
    return ChatListLoaded(
      chats ?? this.chats,
      newChatRoomId: newChatRoomId,
    );
  }
}

class ChatListError extends ChatListState {
  final String message;

  const ChatListError(this.message);

  @override
  List<Object?> get props => [message];
}

// ==================== Bloc ====================

class ChatListBloc extends Bloc<ChatListEvent, ChatListState> {
  final ChatRepository _chatRepository;

  // Expose repository for user search
  ChatRepository get chatRepository => _chatRepository;

  ChatListBloc(this._chatRepository) : super(const ChatListInitial()) {
    on<LoadChatList>(_onLoadChatList);
    on<RefreshChatList>(_onRefreshChatList);
    on<CreateDirectChat>(_onCreateDirectChat);
  }

  Future<void> _onLoadChatList(
    LoadChatList event,
    Emitter<ChatListState> emit,
  ) async {
    emit(const ChatListLoading());
    try {
      final chats = await _chatRepository.getMyChats();
      // Sort by last message time
      chats.sort((a, b) {
        final aTime = a.lastMessageAt ?? DateTime(2000);
        final bTime = b.lastMessageAt ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });
      emit(ChatListLoaded(chats));
    } catch (e) {
      emit(ChatListError('Sohbetler yüklenemedi: $e'));
    }
  }

  Future<void> _onRefreshChatList(
    RefreshChatList event,
    Emitter<ChatListState> emit,
  ) async {
    try {
      final chats = await _chatRepository.getMyChats();
      chats.sort((a, b) {
        final aTime = a.lastMessageAt ?? DateTime(2000);
        final bTime = b.lastMessageAt ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });
      emit(ChatListLoaded(chats));
    } catch (e) {
      // Keep current state on refresh error
      if (state is ChatListLoaded) {
        return;
      }
      emit(ChatListError('Sohbetler yüklenemedi: $e'));
    }
  }

  Future<void> _onCreateDirectChat(
    CreateDirectChat event,
    Emitter<ChatListState> emit,
  ) async {
    try {
      final roomId = await _chatRepository.createDirectChat(event.targetUserId);
      
      // Refresh chat list and include new room ID for navigation
      final chats = await _chatRepository.getMyChats();
      chats.sort((a, b) {
        final aTime = a.lastMessageAt ?? DateTime(2000);
        final bTime = b.lastMessageAt ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });
      emit(ChatListLoaded(chats, newChatRoomId: roomId));
    } catch (e) {
      emit(ChatListError('Sohbet oluşturulamadı: $e'));
    }
  }
}
