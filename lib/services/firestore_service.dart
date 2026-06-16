import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../models/contact_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  Stream<UserModel?> userStream(String uid) => _db
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((s) => s.exists ? UserModel.fromMap(s.data()!) : null);

  Future<UserModel?> getUserByPhone(String phone) async {
    final q = await _db
        .collection('users')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return UserModel.fromMap(q.docs.first.data());
  }

  Future<void> addContact(String ownerUid, ContactModel contact) async {
    await _db
        .collection('users')
        .doc(ownerUid)
        .collection('contacts')
        .doc(contact.uid)
        .set(contact.toMap());
  }

  Stream<List<ContactModel>> contactsStream(String uid) => _db
      .collection('users')
      .doc(uid)
      .collection('contacts')
      .snapshots()
      .map((s) => s.docs.map((d) => ContactModel.fromMap(d.data())).toList());

  Stream<List<ConversationModel>> conversationsStream(String uid) => _db
      .collection('conversations')
      .where('participants', arrayContains: uid)
      .orderBy('lastMessageTime', descending: true)
      .snapshots()
      .map((s) => s.docs
          .map((d) => ConversationModel.fromMap({...d.data(), 'id': d.id}))
          .toList());

  Future<ConversationModel> getOrCreateConversation(
      String uid1, String uid2) async {
    final q = await _db
        .collection('conversations')
        .where('participants', arrayContains: uid1)
        .where('isGroup', isEqualTo: false)
        .get();

    for (final doc in q.docs) {
      final participants =
          List<String>.from(doc.data()['participants'] as List);
      if (participants.contains(uid2)) {
        return ConversationModel.fromMap({...doc.data(), 'id': doc.id});
      }
    }

    final docRef = _db.collection('conversations').doc();
    final conv = ConversationModel(
      id: docRef.id,
      participants: [uid1, uid2],
      isGroup: false,
    );
    await docRef.set(conv.toMap());
    return conv;
  }

  Future<ConversationModel> createGroup({
    required String creatorUid,
    required String groupName,
    required List<String> memberUids,
    String? avatarUrl,
  }) async {
    final docRef = _db.collection('conversations').doc();
    final conv = ConversationModel(
      id: docRef.id,
      participants: [creatorUid, ...memberUids],
      isGroup: true,
      groupName: groupName,
      groupAvatar: avatarUrl,
    );
    await docRef.set(conv.toMap());
    return conv;
  }

  Stream<List<MessageModel>> messagesStream(String conversationId) => _db
      .collection('conversations')
      .doc(conversationId)
      .collection('messages')
      .orderBy('timestamp')
      .snapshots()
      .map((s) => s.docs.map((d) => MessageModel.fromMap(d.data())).toList());

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    MessageType type = MessageType.text,
    String? replyToId,
  }) async {
    final id = _uuid.v4();
    final msg = MessageModel(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      content: content,
      type: type,
      status: MessageStatus.sent,
      timestamp: DateTime.now(),
      replyToId: replyToId,
    );

    final batch = _db.batch();
    batch.set(
      _db
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(id),
      msg.toMap(),
    );
    batch.update(_db.collection('conversations').doc(conversationId), {
      'lastMessage': content,
      'lastMessageTime': msg.timestamp.millisecondsSinceEpoch,
      'lastMessageSenderId': senderId,
    });
    await batch.commit();
  }

  Future<void> markAsRead(String conversationId, String uid) async {
    await _db
        .collection('conversations')
        .doc(conversationId)
        .update({'unreadCount.$uid': 0});
  }
}
