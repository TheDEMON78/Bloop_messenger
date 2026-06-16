class ConversationModel {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final bool isGroup;
  final String? groupName;
  final String? groupAvatar;
  final Map<String, int> unreadCount;

  const ConversationModel({
    required this.id,
    required this.participants,
    this.participantNames = const {},
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    this.isGroup = false,
    this.groupName,
    this.groupAvatar,
    this.unreadCount = const {},
  });

  factory ConversationModel.fromMap(Map<String, dynamic> map) =>
      ConversationModel(
        id: map['id'] as String,
        participants: List<String>.from(map['participants'] as List),
        participantNames: Map<String, String>.from(
            map['participantNames'] as Map? ?? {}),
        lastMessage: map['lastMessage'] as String?,
        lastMessageTime: map['lastMessageTime'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                map['lastMessageTime'] as int)
            : null,
        lastMessageSenderId: map['lastMessageSenderId'] as String?,
        isGroup: map['isGroup'] as bool? ?? false,
        groupName: map['groupName'] as String?,
        groupAvatar: map['groupAvatar'] as String?,
        unreadCount:
            Map<String, int>.from(map['unreadCount'] as Map? ?? {}),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'participants': participants,
        'participantNames': participantNames,
        'lastMessage': lastMessage,
        'lastMessageTime': lastMessageTime?.millisecondsSinceEpoch,
        'lastMessageSenderId': lastMessageSenderId,
        'isGroup': isGroup,
        'groupName': groupName,
        'groupAvatar': groupAvatar,
        'unreadCount': unreadCount,
      };
}
