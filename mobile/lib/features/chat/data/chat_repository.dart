import 'dart:async';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/api_config.dart';
import '../../../core/models/chat_room.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/models/chat_participant.dart';

class ChatRepository {
  final SupabaseClient _supabase;
  final Dio _dio;

  ChatRepository(this._supabase)
      : _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));

  String? get _accessToken => _supabase.auth.currentSession?.accessToken;
  String? get _userId => _supabase.auth.currentUser?.id;

  Map<String, String> get _authHeaders => {
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  // ==================== Chat Rooms ====================

  /// Get all chat rooms for current user
  Future<List<ChatRoom>> getMyChats() async {
    try {
      final response = await _dio.get(
        '/chats/my',
        options: Options(headers: _authHeaders),
      );

      final data = response.data['data'] as List;
      return data.map((json) => ChatRoom.fromJson(json)).toList();
    } catch (e) {
      print('Get my chats error: $e');
      // Fallback to direct Supabase query
      return _getChatsFromSupabase();
    }
  }

  /// Fallback: Get chats directly from Supabase
  Future<List<ChatRoom>> _getChatsFromSupabase() async {
    try {
      final userId = _userId;
      if (userId == null) return [];

      final response = await _supabase
          .from('chat_participants')
          .select('''
            room_id,
            status,
            role,
            chat_rooms (
              id,
              type,
              name,
              team_id,
              last_message_at,
              created_at
            )
          ''')
          .eq('participant_id', userId)
          .eq('status', 'approved');

      final rooms = <ChatRoom>[];
      for (final item in response as List) {
        final room = item['chat_rooms'];
        if (room == null) continue;

        // Get last message
        final lastMessageResponse = await _supabase
            .from('chat_messages')
            .select('content, sender_id, created_at')
            .eq('room_id', room['id'])
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        // Get unread count
        final unreadResponse = await _supabase
            .from('chat_messages')
            .select('id')
            .eq('room_id', room['id'])
            .eq('is_read', false)
            .neq('sender_id', userId);

        // Get other participant for direct chats
        String? name = room['name'];
        String? avatarUrl;
        
        if (room['type'] == 'direct') {
          final otherParticipant = await _supabase
              .from('chat_participants')
              .select('participant_id')
              .eq('room_id', room['id'])
              .neq('participant_id', userId)
              .maybeSingle();

          if (otherParticipant != null) {
            final profile = await _supabase
                .from('profiles')
                .select('full_name, avatar_url')
                .eq('id', otherParticipant['participant_id'])
                .maybeSingle();
            name = profile?['full_name'];
            avatarUrl = profile?['avatar_url'];
          }
        }

        rooms.add(ChatRoom(
          id: room['id'],
          type: room['type'],
          name: name,
          avatarUrl: avatarUrl,
          teamId: room['team_id'],
          lastMessage: lastMessageResponse?['content'] as String?,
          lastMessageAt: lastMessageResponse?['created_at'] != null
              ? DateTime.parse(lastMessageResponse!['created_at'] as String)
              : null,
          unreadCount: (unreadResponse as List).length,
          role: item['role'] ?? 'member',
        ));
      }

      return rooms;
    } catch (e) {
      print('Get chats from Supabase error: $e');
      return [];
    }
  }

  /// Create or get direct chat with another user
  Future<String> createDirectChat(String targetUserId) async {
    try {
      final response = await _dio.post(
        '/chats/direct',
        data: {'userId': targetUserId},
        options: Options(headers: _authHeaders),
      );

      return response.data['data']['roomId'] as String;
    } catch (e) {
      print('Create direct chat error: $e');
      // Fallback to RPC
      final result = await _supabase.rpc('get_or_create_direct_chat', params: {
        'user1_id': _userId,
        'user2_id': targetUserId,
      });
      return result as String;
    }
  }

  /// Get room details
  Future<ChatRoom?> getRoomDetails(String roomId) async {
    try {
      final response = await _dio.get(
        '/chats/$roomId',
        options: Options(headers: _authHeaders),
      );

      return ChatRoom.fromJson(response.data['data']);
    } catch (e) {
      print('Get room details error: $e');
      return null;
    }
  }

  // ==================== Messages ====================

  /// Get messages for a room
  /// Returns messages with newest at index 0 (for reversed ListView)
  /// contextType and contextId are used to determine which messages are "own"
  Future<List<ChatMessage>> getMessages(
    String roomId, {
    int limit = 50,
    int offset = 0,
    String? contextType,  // 'user' or 'team'
    String? contextId,    // userId or teamId
  }) async {
    try {
      final response = await _dio.get(
        '/chats/$roomId/messages',
        queryParameters: {'limit': limit, 'offset': offset},
        options: Options(headers: _authHeaders),
      );

      final data = response.data['data'] as List;
      final userId = _userId;
      
      // Parse messages and set isOwn based on current context
      final messages = data.map((json) {
        final msg = ChatMessage.fromJson(json);
        
        // Determine isOwn based on context
        bool isOwn = false;
        if (contextType == 'team' && contextId != null) {
          // In team mode: own if sender_type is 'team' AND sender_id is the team
          isOwn = msg.senderType == 'team' && msg.senderId == contextId;
        } else {
          // In user mode: own if sender_id matches current user
          isOwn = msg.senderId == userId;
        }
        
        if (isOwn != msg.isOwn) {
          return ChatMessage(
            id: msg.id,
            roomId: msg.roomId,
            senderType: msg.senderType,
            senderId: msg.senderId,
            senderName: msg.senderName,
            senderAvatar: msg.senderAvatar,
            content: msg.content,
            messageType: msg.messageType,
            mediaUrl: msg.mediaUrl,
            isRead: msg.isRead,
            isOwn: isOwn,
            createdAt: msg.createdAt,
          );
        }
        return msg;
      }).toList();
      
      // Sort by createdAt descending (newest first at index 0)
      messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return messages;
    } catch (e) {
      print('Get messages error: $e');
      // Fallback to direct Supabase query
      return _getMessagesFromSupabase(roomId, limit: limit, offset: offset, contextType: contextType, contextId: contextId);
    }
  }

  /// Fallback: Get messages directly from Supabase
  Future<List<ChatMessage>> _getMessagesFromSupabase(
    String roomId, {
    int limit = 50,
    int offset = 0,
    String? contextType,
    String? contextId,
  }) async {
    try {
      final userId = _userId;
      
      // Fetch messages in ASCENDING order (oldest first)
      final response = await _supabase
          .from('chat_messages')
          .select('*')
          .eq('room_id', roomId)
          .order('created_at', ascending: true)
          .range(offset, offset + limit - 1);

      final messages = <ChatMessage>[];
      for (final msg in response as List) {
        // Get sender info
        String? senderName;
        String? senderAvatar;
        
        if (msg['sender_type'] == 'user') {
          final profile = await _supabase
              .from('profiles')
              .select('full_name, avatar_url')
              .eq('id', msg['sender_id'])
              .maybeSingle();
          senderName = profile?['full_name'];
          senderAvatar = profile?['avatar_url'];
        } else {
          final team = await _supabase
              .from('teams')
              .select('name, logo_url')
              .eq('id', msg['sender_id'])
              .maybeSingle();
          senderName = team?['name'];
          senderAvatar = team?['logo_url'];
        }

        // Determine isOwn based on context
        bool isOwn = false;
        if (contextType == 'team' && contextId != null) {
          // In team mode: own if sender_type is 'team' AND sender_id is the team
          isOwn = msg['sender_type'] == 'team' && msg['sender_id'] == contextId;
        } else {
          // In user mode: own if sender_id matches current user
          isOwn = msg['sender_id'] == userId;
        }

        messages.add(ChatMessage(
          id: msg['id'],
          roomId: msg['room_id'],
          senderType: msg['sender_type'] ?? 'user',
          senderId: msg['sender_id'],
          senderName: senderName,
          senderAvatar: senderAvatar,
          content: msg['content'],
          messageType: msg['message_type'] ?? 'text',
          mediaUrl: msg['media_url'],
          isRead: msg['is_read'] ?? false,
          isOwn: isOwn,
          createdAt: DateTime.parse(msg['created_at']),
        ));
      }
      // Reverse: newest message at index 0 (for reversed ListView which shows index 0 at bottom)
      return messages.reversed.toList();
    } catch (e) {
      print('Get messages from Supabase error: $e');
      return [];
    }
  }

  /// Send a message
  Future<ChatMessage?> sendMessage(
    String roomId,
    String content, {
    String messageType = 'text',
    String? mediaUrl,
    String? contextType,
    String? contextId,
  }) async {
    try {
      final headers = {
        ..._authHeaders,
        if (contextType != null) 'x-context-type': contextType,
        if (contextId != null) 'x-context-id': contextId,
      };

      final response = await _dio.post(
        '/chats/$roomId/messages',
        data: {
          'content': content,
          'messageType': messageType,
          if (mediaUrl != null) 'mediaUrl': mediaUrl,
        },
        options: Options(headers: headers),
      );

      return ChatMessage.fromJson(response.data['data']);
    } catch (e) {
      print('Send message error: $e');
      // Fallback to direct Supabase insert
      return _sendMessageToSupabase(roomId, content, messageType: messageType, mediaUrl: mediaUrl);
    }
  }

  /// Fallback: Send message directly to Supabase
  Future<ChatMessage?> _sendMessageToSupabase(
    String roomId,
    String content, {
    String messageType = 'text',
    String? mediaUrl,
  }) async {
    try {
      final userId = _userId;
      if (userId == null) return null;

      final response = await _supabase.from('chat_messages').insert({
        'room_id': roomId,
        'sender_type': 'user',
        'sender_id': userId,
        'content': content,
        'message_type': messageType,
        if (mediaUrl != null) 'media_url': mediaUrl,
      }).select().single();

      return ChatMessage(
        id: response['id'],
        roomId: response['room_id'],
        senderType: response['sender_type'],
        senderId: response['sender_id'],
        content: response['content'],
        messageType: response['message_type'] ?? 'text',
        mediaUrl: response['media_url'],
        isRead: false,
        isOwn: true,
        createdAt: DateTime.parse(response['created_at']),
      );
    } catch (e) {
      print('Send message to Supabase error: $e');
      return null;
    }
  }

  // ==================== Realtime ====================

  /// Subscribe to new messages in a room
  Stream<ChatMessage> getMessageStream(String roomId) {
    return _supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: false)
        .limit(1)
        .map((data) {
          if (data.isEmpty) return null;
          final msg = data.first;
          return ChatMessage(
            id: msg['id'],
            roomId: msg['room_id'],
            senderType: msg['sender_type'],
            senderId: msg['sender_id'],
            content: msg['content'],
            messageType: msg['message_type'] ?? 'text',
            mediaUrl: msg['media_url'],
            isRead: msg['is_read'] ?? false,
            isOwn: msg['sender_id'] == _userId,
            createdAt: DateTime.parse(msg['created_at']),
          );
        })
        .where((msg) => msg != null)
        .cast<ChatMessage>();
  }

  // ==================== Join Requests ====================

  /// Get pending join requests for a room (admin only)
  Future<List<ChatParticipant>> getPendingRequests(String roomId) async {
    try {
      final response = await _dio.get(
        '/chats/$roomId/pending',
        options: Options(headers: _authHeaders),
      );

      final data = response.data['data'] as List;
      return data.map((json) => ChatParticipant.fromJson(json)).toList();
    } catch (e) {
      print('Get pending requests error: $e');
      return [];
    }
  }

  /// Approve a join request
  Future<bool> approveJoinRequest(String roomId, String participantId) async {
    try {
      await _dio.post(
        '/chats/$roomId/approve/$participantId',
        options: Options(headers: _authHeaders),
      );
      return true;
    } catch (e) {
      print('Approve join request error: $e');
      return false;
    }
  }

  /// Reject a join request
  Future<bool> rejectJoinRequest(String roomId, String participantId) async {
    try {
      await _dio.post(
        '/chats/$roomId/reject/$participantId',
        options: Options(headers: _authHeaders),
      );
      return true;
    } catch (e) {
      print('Reject join request error: $e');
      return false;
    }
  }

  // ==================== Team Chat Helpers ====================

  /// Get team chat room ID - creates if doesn't exist
  Future<String?> getTeamChatRoom(String teamId) async {
    print('DEBUG: getTeamChatRoom called with teamId: $teamId');
    print('DEBUG: Current userId: $_userId');
    try {
      // First try to find existing room
      final response = await _supabase
          .from('chat_rooms')
          .select('id')
          .eq('team_id', teamId)
          .eq('type', 'team_group')
          .maybeSingle();

      print('DEBUG: Found existing room: $response');

      if (response != null) {
        // Room exists, ensure user is participant
        await _ensureTeamChatParticipant(response['id'] as String);
        return response['id'] as String;
      }

      // Room doesn't exist - create it
      print('DEBUG: Creating team chat room for team: $teamId');
      return await _createTeamChatRoom(teamId);
    } catch (e) {
      print('DEBUG: Get team chat room error: $e');
      return null;
    }
  }

  /// Create team chat room for an existing team
  Future<String?> _createTeamChatRoom(String teamId) async {
    try {
      final userId = _userId;
      if (userId == null) return null;

      // Get team info
      final teamResponse = await _supabase
          .from('teams')
          .select('name, captain_id')
          .eq('id', teamId)
          .single();

      final teamName = teamResponse['name'] as String;
      final captainId = teamResponse['captain_id'] as String;

      // Create chat room
      final roomResponse = await _supabase
          .from('chat_rooms')
          .insert({
            'type': 'team_group',
            'name': '$teamName Sohbeti',
            'team_id': teamId,
            'created_by': captainId,
          })
          .select('id')
          .single();

      final roomId = roomResponse['id'] as String;

      // Add captain as admin
      await _supabase.from('chat_participants').insert({
        'room_id': roomId,
        'participant_type': 'user',
        'participant_id': captainId,
        'status': 'approved',
        'role': 'admin',
      });

      // If current user is not captain, add them too
      if (userId != captainId) {
        await _supabase.from('chat_participants').upsert({
          'room_id': roomId,
          'participant_type': 'user',
          'participant_id': userId,
          'status': 'approved',
          'role': 'member',
        });
      }

      // Add existing team members
      final members = await _supabase
          .from('team_members')
          .select('user_id')
          .eq('team_id', teamId)
          .neq('user_id', captainId);

      for (final member in members as List) {
        await _supabase.from('chat_participants').upsert({
          'room_id': roomId,
          'participant_type': 'user',
          'participant_id': member['user_id'],
          'status': 'approved',
          'role': 'member',
        });
      }

      print('Created team chat room: $roomId');
      return roomId;
    } catch (e) {
      print('Create team chat room error: $e');
      return null;
    }
  }

  /// Ensure current user is a participant in the chat room
  Future<void> _ensureTeamChatParticipant(String roomId) async {
    try {
      final userId = _userId;
      if (userId == null) return;

      // Check if user is already a participant
      final existing = await _supabase
          .from('chat_participants')
          .select('id')
          .eq('room_id', roomId)
          .eq('participant_id', userId)
          .maybeSingle();

      if (existing == null) {
        // Add user as approved participant (since they're already in the team)
        await _supabase.from('chat_participants').insert({
          'room_id': roomId,
          'participant_type': 'user',
          'participant_id': userId,
          'status': 'approved',
          'role': 'member',
        });
      }
    } catch (e) {
      print('Ensure participant error: $e');
    }
  }

  // ==================== User Search ====================

  /// Search users by name for starting a new chat
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    print('DEBUG: searchUsers called with query: "$query"');
    try {
      if (query.trim().isEmpty) {
        return getAllUsers(limit: 20);
      }

      final response = await _supabase
          .from('profiles')
          .select('id, full_name, avatar_url')
          .ilike('full_name', '%$query%')
          .neq('id', _userId ?? '')
          .limit(20);

      print('DEBUG: Search found ${(response as List).length} users');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('DEBUG: Search users error: $e');
      return [];
    }
  }

  /// Get all users (for showing suggestions)
  Future<List<Map<String, dynamic>>> getAllUsers({int limit = 20}) async {
    print('DEBUG: getAllUsers called, limit: $limit');
    print('DEBUG: Current userId to exclude: $_userId');
    try {
      final response = await _supabase
          .from('profiles')
          .select('id, full_name, avatar_url')
          .neq('id', _userId ?? '')
          .limit(limit);

      print('DEBUG: getAllUsers found ${(response as List).length} users');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('DEBUG: Get all users error: $e');
      return [];
    }
  }
}
