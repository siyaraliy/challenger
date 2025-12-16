import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/models/chat_message.dart';
import '../../../../core/models/chat_room.dart';
import '../../../../core/models/chat_participant.dart';
import '../../data/chat_repository.dart';

// ==================== Events ====================

abstract class ChatRoomEvent extends Equatable {
  const ChatRoomEvent();

  @override
  List<Object?> get props => [];
}

class LoadChatRoom extends ChatRoomEvent {
  final String roomId;
  final String? contextType;  // 'user' or 'team'
  final String? contextId;    // userId or teamId

  const LoadChatRoom(this.roomId, {this.contextType, this.contextId});

  @override
  List<Object?> get props => [roomId, contextType, contextId];
}

class LoadMoreMessages extends ChatRoomEvent {
  const LoadMoreMessages();
}

class SendMessage extends ChatRoomEvent {
  final String content;
  final String? contextType;
  final String? contextId;

  const SendMessage(this.content, {this.contextType, this.contextId});

  @override
  List<Object?> get props => [content, contextType, contextId];
}

class MessageReceived extends ChatRoomEvent {
  final ChatMessage message;

  const MessageReceived(this.message);

  @override
  List<Object?> get props => [message];
}

class LoadPendingRequests extends ChatRoomEvent {
  const LoadPendingRequests();
}

class ApproveJoinRequest extends ChatRoomEvent {
  final String participantId;

  const ApproveJoinRequest(this.participantId);

  @override
  List<Object?> get props => [participantId];
}

class RejectJoinRequest extends ChatRoomEvent {
  final String participantId;

  const RejectJoinRequest(this.participantId);

  @override
  List<Object?> get props => [participantId];
}

// ==================== States ====================

abstract class ChatRoomState extends Equatable {
  const ChatRoomState();

  @override
  List<Object?> get props => [];
}

class ChatRoomInitial extends ChatRoomState {
  const ChatRoomInitial();
}

class ChatRoomLoading extends ChatRoomState {
  const ChatRoomLoading();
}

class ChatRoomLoaded extends ChatRoomState {
  final String roomId;
  final ChatRoom? roomDetails;
  final List<ChatMessage> messages;
  final List<ChatParticipant> pendingRequests;
  final bool hasMore;
  final bool isSending;

  const ChatRoomLoaded({
    required this.roomId,
    this.roomDetails,
    required this.messages,
    this.pendingRequests = const [],
    this.hasMore = true,
    this.isSending = false,
  });

  @override
  List<Object?> get props => [roomId, roomDetails, messages, pendingRequests, hasMore, isSending];

  ChatRoomLoaded copyWith({
    String? roomId,
    ChatRoom? roomDetails,
    List<ChatMessage>? messages,
    List<ChatParticipant>? pendingRequests,
    bool? hasMore,
    bool? isSending,
  }) {
    return ChatRoomLoaded(
      roomId: roomId ?? this.roomId,
      roomDetails: roomDetails ?? this.roomDetails,
      messages: messages ?? this.messages,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      hasMore: hasMore ?? this.hasMore,
      isSending: isSending ?? this.isSending,
    );
  }
}

class ChatRoomError extends ChatRoomState {
  final String message;

  const ChatRoomError(this.message);

  @override
  List<Object?> get props => [message];
}

// ==================== Bloc ====================

class ChatRoomBloc extends Bloc<ChatRoomEvent, ChatRoomState> {
  final ChatRepository _chatRepository;
  StreamSubscription<ChatMessage>? _messageSubscription;
  String? _currentRoomId;

  ChatRoomBloc(this._chatRepository) : super(const ChatRoomInitial()) {
    on<LoadChatRoom>(_onLoadChatRoom);
    on<LoadMoreMessages>(_onLoadMoreMessages);
    on<SendMessage>(_onSendMessage);
    on<MessageReceived>(_onMessageReceived);
    on<LoadPendingRequests>(_onLoadPendingRequests);
    on<ApproveJoinRequest>(_onApproveJoinRequest);
    on<RejectJoinRequest>(_onRejectJoinRequest);
  }

  Future<void> _onLoadChatRoom(
    LoadChatRoom event,
    Emitter<ChatRoomState> emit,
  ) async {
    emit(const ChatRoomLoading());
    _currentRoomId = event.roomId;

    try {
      // Load messages and room details in parallel
      final messagesFuture = _chatRepository.getMessages(
        event.roomId,
        contextType: event.contextType,
        contextId: event.contextId,
      );
      final roomDetailsFuture = _chatRepository.getRoomDetails(event.roomId);

      final results = await Future.wait([messagesFuture, roomDetailsFuture]);
      final messages = results[0] as List<ChatMessage>;
      final roomDetails = results[1] as ChatRoom?;

      emit(ChatRoomLoaded(
        roomId: event.roomId,
        roomDetails: roomDetails,
        messages: messages,
        hasMore: messages.length >= 50,
      ));

      // Subscribe to realtime messages
      _subscribeToMessages(event.roomId);

      // If admin, load pending requests
      if (roomDetails?.isAdmin == true) {
        add(const LoadPendingRequests());
      }
    } catch (e) {
      emit(ChatRoomError('Sohbet yüklenemedi: $e'));
    }
  }

  Future<void> _onLoadMoreMessages(
    LoadMoreMessages event,
    Emitter<ChatRoomState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatRoomLoaded || !currentState.hasMore) return;

    try {
      final moreMessages = await _chatRepository.getMessages(
        currentState.roomId,
        offset: currentState.messages.length,
      );

      emit(currentState.copyWith(
        messages: [...currentState.messages, ...moreMessages],
        hasMore: moreMessages.length >= 50,
      ));
    } catch (e) {
      // Silently fail for pagination
      print('Load more messages error: $e');
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatRoomState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatRoomLoaded) return;

    emit(currentState.copyWith(isSending: true));

    try {
      final message = await _chatRepository.sendMessage(
        currentState.roomId,
        event.content,
        contextType: event.contextType,
        contextId: event.contextId,
      );

      if (message != null) {
        // Add message to list if not already received via realtime
        final exists = currentState.messages.any((m) => m.id == message.id);
        if (!exists) {
          emit(currentState.copyWith(
            messages: [message, ...currentState.messages],
            isSending: false,
          ));
        } else {
          emit(currentState.copyWith(isSending: false));
        }
      } else {
        emit(currentState.copyWith(isSending: false));
      }
    } catch (e) {
      emit(currentState.copyWith(isSending: false));
    }
  }

  void _onMessageReceived(
    MessageReceived event,
    Emitter<ChatRoomState> emit,
  ) {
    final currentState = state;
    if (currentState is! ChatRoomLoaded) return;

    // Check if message already exists
    final exists = currentState.messages.any((m) => m.id == event.message.id);
    if (!exists) {
      emit(currentState.copyWith(
        messages: [event.message, ...currentState.messages],
      ));
    }
  }

  Future<void> _onLoadPendingRequests(
    LoadPendingRequests event,
    Emitter<ChatRoomState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatRoomLoaded) return;

    try {
      final requests = await _chatRepository.getPendingRequests(currentState.roomId);
      emit(currentState.copyWith(pendingRequests: requests));
    } catch (e) {
      print('Load pending requests error: $e');
    }
  }

  Future<void> _onApproveJoinRequest(
    ApproveJoinRequest event,
    Emitter<ChatRoomState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatRoomLoaded) return;

    try {
      final success = await _chatRepository.approveJoinRequest(
        currentState.roomId,
        event.participantId,
      );

      if (success) {
        // Remove from pending list
        final updatedRequests = currentState.pendingRequests
            .where((r) => r.participantId != event.participantId)
            .toList();
        emit(currentState.copyWith(pendingRequests: updatedRequests));
      }
    } catch (e) {
      print('Approve request error: $e');
    }
  }

  Future<void> _onRejectJoinRequest(
    RejectJoinRequest event,
    Emitter<ChatRoomState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatRoomLoaded) return;

    try {
      final success = await _chatRepository.rejectJoinRequest(
        currentState.roomId,
        event.participantId,
      );

      if (success) {
        // Remove from pending list
        final updatedRequests = currentState.pendingRequests
            .where((r) => r.participantId != event.participantId)
            .toList();
        emit(currentState.copyWith(pendingRequests: updatedRequests));
      }
    } catch (e) {
      print('Reject request error: $e');
    }
  }

  void _subscribeToMessages(String roomId) {
    _messageSubscription?.cancel();
    _messageSubscription = _chatRepository.getMessageStream(roomId).listen(
      (message) {
        // Only add if it's not our own message or if it's from realtime
        if (_currentRoomId == roomId) {
          add(MessageReceived(message));
        }
      },
      onError: (e) => print('Message stream error: $e'),
    );
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    return super.close();
  }
}
