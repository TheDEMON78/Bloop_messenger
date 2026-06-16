import 'package:cloud_firestore/cloud_firestore.dart';

class BlockService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> blockUser(String myUid, String targetUid) async {
    await _db
        .collection('users')
        .doc(myUid)
        .collection('blocked')
        .doc(targetUid)
        .set({'blockedAt': DateTime.now().millisecondsSinceEpoch});
  }

  Future<void> unblockUser(String myUid, String targetUid) async {
    await _db
        .collection('users')
        .doc(myUid)
        .collection('blocked')
        .doc(targetUid)
        .delete();
  }

  Future<bool> isBlocked(String myUid, String targetUid) async {
    final doc = await _db
        .collection('users')
        .doc(myUid)
        .collection('blocked')
        .doc(targetUid)
        .get();
    return doc.exists;
  }

  Stream<bool> isBlockedStream(String myUid, String targetUid) => _db
      .collection('users')
      .doc(myUid)
      .collection('blocked')
      .doc(targetUid)
      .snapshots()
      .map((s) => s.exists);

  Future<void> reportUser({
    required String reporterUid,
    required String targetUid,
    required String reason,
    String? conversationId,
  }) async {
    await _db.collection('reports').add({
      'reporterUid': reporterUid,
      'targetUid': targetUid,
      'reason': reason,
      'conversationId': conversationId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'status': 'pending',
    });
  }
}
