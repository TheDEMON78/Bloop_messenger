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

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  Future<UserModel?> getUserByPhone(String phone) async {
    final q = await _db
        .collection('users')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return UserModel.fromMap(q.docs.first.data());
  }

  Future<void> updateProfile({
    required String uid,
    required String displayName,
    String? status,
  }) async {
    await _db.collection('users').doc(uid).update({
      'displayName': displayName,
      if (status != null && status.isNotEmpty) 'status': status,
    });
  }

  Future<void> deleteUserData(String uid) async {
    final batch = _db.batch();
    final contacts = await _db
        .collection('users')
        .doc(uid)
        .collection('contacts')
        .get();
    for (final doc in contacts.docs) {
      batch.delete(doc.reference);
    }
    final blocked = await _db
        .collection('users')
        .doc(uid)
        .collection('blocked')
        .get();
    for (final doc in blocked.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_db.collection('users').doc(uid));
    await batch.commit();
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
      .map((s) =>
          s.docs.map((d) => ContactModel.fromMap(d.data())).toList());

  Stream<List<ConversationModel>> conversationsStream(String uid) => _db
      .collection('conversations')
      .where('participants', arrayContains: uid)
      .orderBy('lastMessageTime', descending: true)
      .snapshots()
      .map((s) => s.docs
          .map((d) =>
              ConversationModel.fromMap({...d.data(), 'id': d.id}))
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
        // Update participantNames if missing
        final existing =
            ConversationModel.fromMap({...doc.data(), 'id': doc.id});
        if (existing.participantNames.isEmpty) {
          final u1 = await getUser(uid1);
          final u2 = await getUser(uid2);
          final names = {
            uid1: u1?.displayName ?? '',
            uid2: u2?.displayName ?? '',
          };
          await doc.reference.update({'participantNames': names});
          return ConversationModel.fromMap(
              {...doc.data(), 'id': doc.id, 'participantNames': names});
        }
        return existing;
      }
    }

    // Create new conversation with participant names
    final u1 = await getUser(uid1);
    final u2 = await getUser(uid2);
    final names = {
      uid1: u1?.displayName ?? '',
      uid2: u2?.displayName ?? '',
    };

    final docRef = _db.collection('conversations').doc();
    final conv = ConversationModel(
      id: docRef.id,
      participants: [uid1, uid2],
      participantNames: names,
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
    final allUids = [creatorUid, ...memberUids];
    // Fetch display names for all members
    final names = <String, String>{};
    for (final uid in allUids) {
      final u = await getUser(uid);
      if (u != null) names[uid] = u.displayName;
    }
    final docRef = _db.collection('conversations').doc();
    final conv = ConversationModel(
      id: docRef.id,
      participants: allUids,
      participantNames: names,
      isGroup: true,
      groupName: groupName,
      groupAvatar: avatarUrl,
      creatorUid: creatorUid,
    );
    await docRef.set(conv.toMap());
    return conv;
  }

  Future<void> updateGroup({
    required String conversationId,
    String? newGroupName,
    List<String>? addUids,
    Map<String, String>? addNames,
    List<String>? removeUids,
  }) async {
    final updates = <String, dynamic>{};
    if (newGroupName != null) updates['groupName'] = newGroupName;
    if (addUids != null && addUids.isNotEmpty) {
      updates['participants'] = FieldValue.arrayUnion(addUids);
    }
    if (removeUids != null && removeUids.isNotEmpty) {
      updates['participants'] = FieldValue.arrayRemove(removeUids);
    }
    if (addNames != null) {
      for (final e in addNames.entries) {
        updates['participantNames.${e.key}'] = e.value;
      }
    }
    if (removeUids != null) {
      for (final uid in removeUids) {
        updates['participantNames.$uid'] = FieldValue.delete();
      }
    }
    if (updates.isNotEmpty) {
      await _db.collection('conversations').doc(conversationId).update(updates);
    }
  }

  Stream<List<MessageModel>> messagesStream(String conversationId) => _db
      .collection('conversations')
      .doc(conversationId)
      .collection('messages')
      .orderBy('timestamp')
      .snapshots()
      .map((s) =>
          s.docs.map((d) => MessageModel.fromMap(d.data())).toList());

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

  Future<void> editMessage(
      String conversationId, String messageId, String newContent) async {
    await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({
      'content': newContent,
      'editedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> deleteMessage(
      String conversationId, String messageId) async {
    await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({
      'isDeleted': true,
      'content': 'Message supprimé',
    });
  }

  Future<void> markAsRead(String conversationId, String uid) async {
    await _db
        .collection('conversations')
        .doc(conversationId)
        .update({'unreadCount.$uid': 0});
  }

  Future<void> leaveGroup(String conversationId, String uid, String displayName) async {
    await _db.collection('conversations').doc(conversationId).update({
      'participants': FieldValue.arrayRemove([uid]),
      'participantNames.$uid': FieldValue.delete(),
    });
  }

  Future<void> deleteGroup(String conversationId) async {
    // Delete all messages then the conversation document
    final messages = await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .get();
    final batch = _db.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_db.collection('conversations').doc(conversationId));
    await batch.commit();
  }
}
