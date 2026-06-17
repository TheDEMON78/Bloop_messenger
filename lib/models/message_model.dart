enum MessageType { text, image }
enum MessageStatus { sending, sent, delivered, read }

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final String? replyToId;
  final bool isDeleted;
  final DateTime? editedAt;
  final Map<String, String> reactions;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    required this.timestamp,
    this.replyToId,
    this.isDeleted = false,
    this.editedAt,
    this.reactions = const {},
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) => MessageModel(
        id: map['id'] as String,
        conversationId: map['conversationId'] as String,
        senderId: map['senderId'] as String,
        content: map['content'] as String,
        type: MessageType.values.firstWhere(
          (e) => e.name == (map['type'] as String? ?? 'text'),
          orElse: () => MessageType.text,
        ),
        status: MessageStatus.values.firstWhere(
          (e) => e.name == (map['status'] as String? ?? 'sent'),
          orElse: () => MessageStatus.sent,
        ),
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
        replyToId: map['replyToId'] as String?,
        isDeleted: map['isDeleted'] as bool? ?? false,
        editedAt: map['editedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['editedAt'] as int)
            : null,
        reactions: Map<String, String>.from(map['reactions'] as Map? ?? {}),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'conversationId': conversationId,
        'senderId': senderId,
        'content': content,
        'type': type.name,
        'status': status.name,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'replyToId': replyToId,
        'isDeleted': isDeleted,
        if (editedAt != null) 'editedAt': editedAt!.millisecondsSinceEpoch,
        'reactions': reactions,
      };
}
