import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> verifyPhone({
    required String phoneNumber,
    required void Function(PhoneAuthCredential) onAutoVerify,
    required void Function(FirebaseAuthException) onError,
    required void Function(String, int?) onCodeSent,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onAutoVerify,
      verificationFailed: onError,
      codeSent: (verificationId, resendToken) =>
          onCodeSent(verificationId, resendToken),
      codeAutoRetrievalTimeout: (_) {},
      timeout: const Duration(seconds: 60),
    );
  }

  Future<UserCredential> signInWithCredential(PhoneAuthCredential credential) =>
      _auth.signInWithCredential(credential);

  Future<UserCredential> signInWithOtp(String verificationId, String smsCode) {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<void> saveUser({
    required String uid,
    required String phone,
    required String displayName,
    String? avatarUrl,
  }) async {
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'phone': phone,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'status': 'Disponible',
      'lastSeen': DateTime.now().millisecondsSinceEpoch,
      'isOnline': true,
    }, SetOptions(merge: true));
  }

  Future<bool> isProfileComplete(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists &&
        (doc.data()?['displayName'] as String?)?.isNotEmpty == true;
  }

  Future<void> updatePresence(bool isOnline) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).update({
      'isOnline': isOnline,
      'lastSeen': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> signOut() async {
    await updatePresence(false);
    await _auth.signOut();
  }
}
