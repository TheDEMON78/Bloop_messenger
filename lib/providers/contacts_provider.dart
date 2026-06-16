import 'dart:async';
import 'package:flutter/material.dart';
import '../models/contact_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class ContactsProvider extends ChangeNotifier {
  final FirestoreService _db = FirestoreService();

  List<ContactModel> _contacts = [];
  StreamSubscription? _sub;

  List<ContactModel> get contacts => _contacts;

  void listenContacts(String uid) {
    _sub?.cancel();
    _sub = _db.contactsStream(uid).listen((contacts) {
      _contacts = contacts;
      notifyListeners();
    });
  }

  Future<UserModel?> findUserByPhone(String phone) =>
      _db.getUserByPhone(phone);

  Future<void> addContact(String ownerUid, ContactModel contact) =>
      _db.addContact(ownerUid, contact);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
