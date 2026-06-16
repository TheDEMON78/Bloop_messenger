import 'dart:async';
import 'package:flutter/material.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class ChatProvider extends ChangeNotifier {
  final FirestoreService _db = FirestoreService();
  final NotificationService _notif = NotificationService();

  List<ConversationModel> _conversations = [];
  List<MessageModel> _messages = [];
  StreamSubscription? _convSub;
  StreamSubscription? _msgSub;

  String? _myUid;
  String? _openConversationId;

  List<ConversationModel> get conversations => _conversations;
  List<MessageModel> get messages => _messages;

  // Track which conversation is currently open so we don't notify for it
  void setOpenConversation(String? conversationId) {
    _openConversationId = conversationId;
  }

  void listenConversations(String uid) {
    _myUid = uid;
    _convSub?.cancel();
    // Track previous last-message timestamps to detect new incoming messages
    final Map<String, int> _lastSeenTime = {};
    _convSub = _db.conversationsStream(uid).listen((convs) {
      for (final conv in convs) {
        final prevTime = _lastSeenTime[conv.id];
        final newTime = conv.lastMessageTime?.millisecondsSinceEpoch;
        final senderId = conv.lastMessageSenderId;

        if (newTime != null &&
            prevTime != null &&
            newTime > prevTime &&
            senderId != null &&
            senderId != uid &&
            conv.id != _openConversationId) {
          // New message from someone else in a conversation we're not viewing
          final senderName = conv.participantNames[senderId];
          final title = conv.isGroup
              ? '${conv.groupName ?? "Groupe"} · ${senderName ?? "Bloop"}'
              : senderName ?? 'Bloop';
          _notif.showLocalNotification(
            id: conv.id.hashCode,
            title: title,
            body: conv.lastMessage ?? '',
          );
        }
        if (newTime != null) _lastSeenTime[conv.id] = newTime;
      }
      _conversations = convs;
      notifyListeners();
    });
  }

  void listenMessages(String conversationId) {
    _msgSub?.cancel();
    _msgSub = _db.messagesStream(conversationId).listen((msgs) {
      _messages = msgs;
      notifyListeners();
    });
  }

  Future<ConversationModel> openDirectChat(String uid1, String uid2) =>
      _db.getOrCreateConversation(uid1, uid2);

  Future<ConversationModel> createGroup({
    required String creatorUid,
    required String groupName,
    required List<String> memberUids,
  }) =>
      _db.createGroup(
        creatorUid: creatorUid,
        groupName: groupName,
        memberUids: memberUids,
      );

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    String? replyToId,
  }) =>
      _db.sendMessage(
        conversationId: conversationId,
        senderId: senderId,
        content: content,
        replyToId: replyToId,
      );

  Future<void> editMessage(
          String conversationId, String messageId, String newContent) =>
      _db.editMessage(conversationId, messageId, newContent);

  Future<void> deleteMessage(String conversationId, String messageId) =>
      _db.deleteMessage(conversationId, messageId);

  Future<void> updateGroup({
    required String conversationId,
    String? newGroupName,
    List<String>? addUids,
    Map<String, String>? addNames,
    List<String>? removeUids,
  }) =>
      _db.updateGroup(
        conversationId: conversationId,
        newGroupName: newGroupName,
        addUids: addUids,
        addNames: addNames,
        removeUids: removeUids,
      );

  @override
  void dispose() {
    _convSub?.cancel();
    _msgSub?.cancel();
    super.dispose();
  }
}
