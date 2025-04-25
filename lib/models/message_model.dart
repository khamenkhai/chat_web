import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class ChatMessage extends Equatable {
  final String id;
  final String senderId;
  final String? senderName;
  final String? senderAvatar;
  final String content;
  final DateTime sentAt;
  final MessageType type;
  final MessageStatus status;
  final Map<String, dynamic>? metadata;
  final String? replyToMessageId;
  final List<String>? readBy;
  final String? roomId;
  final String? conversationId;

  const ChatMessage({
    required this.id,
    required this.senderId,
    this.senderName,
    this.senderAvatar,
    required this.content,
    required this.sentAt,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    this.metadata,
    this.replyToMessageId,
    this.readBy,
    this.roomId,
    this.conversationId,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String?,
      senderAvatar: json['senderAvatar'] as String?,
      content: json['content'] as String? ?? '',
      sentAt: json['sentAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['sentAt'] as int)
          : DateTime.now(),
      type: MessageType.values.firstWhere(
        (e) => e.name == (json['type'] as String?),
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String?),
        orElse: () => MessageStatus.sent,
      ),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      replyToMessageId: json['replyToMessageId'] as String?,
      readBy: json['readBy'] != null
          ? List<String>.from(json['readBy'] as List)
          : null,
      roomId: json['roomId'] as String?,
      conversationId: json['conversationId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      if (senderName != null) 'senderName': senderName,
      if (senderAvatar != null) 'senderAvatar': senderAvatar,
      'content': content,
      'sentAt': sentAt.millisecondsSinceEpoch,
      'type': type.name,
      'status': status.name,
      if (metadata != null) 'metadata': metadata,
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      if (readBy != null) 'readBy': readBy,
      if (roomId != null) 'roomId': roomId,
      if (conversationId != null) 'conversationId': conversationId,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? content,
    DateTime? sentAt,
    MessageType? type,
    MessageStatus? status,
    Map<String, dynamic>? metadata,
    String? replyToMessageId,
    List<String>? readBy,
    String? roomId,
    String? conversationId,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      content: content ?? this.content,
      sentAt: sentAt ?? this.sentAt,
      type: type ?? this.type,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      readBy: readBy ?? this.readBy,
      roomId: roomId ?? this.roomId,
      conversationId: conversationId ?? this.conversationId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        senderId,
        senderName,
        senderAvatar,
        content,
        sentAt,
        type,
        status,
        metadata,
        replyToMessageId,
        readBy,
        roomId,
        conversationId,
      ];
}

enum MessageType {
  text,
  image,
  video,
  audio,
  file,
  location,
  sticker,
  gif,
  system,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}
