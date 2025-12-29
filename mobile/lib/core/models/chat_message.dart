import 'package:equatable/equatable.dart';

/// Represents a chat message
class ChatMessage extends Equatable {
  final String id;
  final String roomId;
  final String senderType; // 'user' or 'team'
  final String senderId;
  final String? senderName;
  final String? senderAvatar;
  final String content;
  final String messageType; // 'text', 'image', 'video', 'system'
  final String? mediaUrl;
  final String? sharedPostId;
  final bool isRead;
  final bool isOwn;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderType,
    required this.senderId,
    this.senderName,
    this.senderAvatar,
    required this.content,
    required this.messageType,
    this.mediaUrl,
    this.sharedPostId,
    required this.isRead,
    required this.isOwn,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      roomId: json['roomId'] as String,
      senderType: json['senderType'] as String? ?? 'user',
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String?,
      senderAvatar: json['senderAvatar'] as String?,
      content: json['content'] as String,
      messageType: json['messageType'] as String? ?? 'text',
      mediaUrl: json['mediaUrl'] as String?,
      sharedPostId: json['sharedPostId'] as String? ?? json['shared_post_id'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      isOwn: json['isOwn'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'senderType': senderType,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'content': content,
      'messageType': messageType,
      'mediaUrl': mediaUrl,
      'sharedPostId': sharedPostId,
      'isRead': isRead,
      'isOwn': isOwn,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isText => messageType == 'text';
  bool get isImage => messageType == 'image';
  bool get isVideo => messageType == 'video';
  bool get isSystem => messageType == 'system';
  bool get isPostShare => messageType == 'post_share';

  @override
  List<Object?> get props => [
        id,
        roomId,
        senderType,
        senderId,
        senderName,
        senderAvatar,
        content,
        messageType,
        mediaUrl,
        sharedPostId,
        isRead,
        isOwn,
        createdAt,
      ];
}
