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

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    required this.timestamp,
    this.replyToId,
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
      };
}
