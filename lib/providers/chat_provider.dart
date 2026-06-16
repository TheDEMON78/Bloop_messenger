import 'dart:async';
import 'package:flutter/material.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../services/firestore_service.dart';

class ChatProvider extends ChangeNotifier {
  final FirestoreService _db = FirestoreService();

  List<ConversationModel> _conversations = [];
  List<MessageModel> _messages = [];
  StreamSubscription? _convSub;
  StreamSubscription? _msgSub;

  List<ConversationModel> get conversations => _conversations;
  List<MessageModel> get messages => _messages;

  void listenConversations(String uid) {
    _convSub?.cancel();
    _convSub = _db.conversationsStream(uid).listen((convs) {
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

  Future<void> leaveGroup(String conversationId, String uid, String displayName) =>
      _db.leaveGroup(conversationId, uid, displayName);

  Future<void> deleteGroup(String conversationId) =>
      _db.deleteGroup(conversationId);

  @override
  void dispose() {
    _convSub?.cancel();
    _msgSub?.cancel();
    super.dispose();
  }
}
