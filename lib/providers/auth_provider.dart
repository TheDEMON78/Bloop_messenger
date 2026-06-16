import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

enum AuthState {
  initial,
  loading,
  otpSent,
  authenticated,
  profileIncomplete,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthState _state = AuthState.initial;
  String? _error;
  String? _verificationId;
  User? _user;

  AuthState get state => _state;
  String? get error => _error;
  User? get user => _user;

  AuthProvider() {
    // Sync init so HomeScreen.initState gets the UID immediately on restart
    _user = FirebaseAuth.instance.currentUser;
    _authService.authStateChanges.listen((user) {
      _user = user;
      if (user != null && _state != AuthState.profileIncomplete) {
        _state = AuthState.authenticated;
      } else if (user == null) {
        _state = AuthState.initial;
      }
      notifyListeners();
    });
  }

  Future<void> sendOtp(String phoneNumber) async {
    _state = AuthState.loading;
    _error = null;
    notifyListeners();

    await _authService.verifyPhone(
      phoneNumber: phoneNumber,
      onAutoVerify: (credential) async {
        await _authService.signInWithCredential(credential);
      },
      onError: (e) {
        _error = e.message;
        _state = AuthState.error;
        notifyListeners();
      },
      onCodeSent: (verificationId, _) {
        _verificationId = verificationId;
        _state = AuthState.otpSent;
        notifyListeners();
      },
    );
  }

  Future<bool> verifyOtp(String code) async {
    if (_verificationId == null) return false;
    _state = AuthState.loading;
    notifyListeners();

    try {
      await _authService.signInWithOtp(_verificationId!, code);
      final isComplete = await _authService.isProfileComplete(_user!.uid);
      _state =
          isComplete ? AuthState.authenticated : AuthState.profileIncomplete;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message;
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> saveProfile(String displayName) async {
    if (_user == null) return;
    await _authService.saveUser(
      uid: _user!.uid,
      phone: _user!.phoneNumber ?? '',
      displayName: displayName,
    );
    _state = AuthState.authenticated;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _state = AuthState.initial;
    notifyListeners();
  }
}
