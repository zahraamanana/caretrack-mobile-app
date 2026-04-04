import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config/firebase_project_config.dart';
import '../models/auth_result.dart';
import 'firestore_service.dart';

class FirebaseAuthService {
  FirebaseAuthService._({
    FirebaseAuth? firebaseAuth,
    FirestoreService? firestoreService,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestoreService = firestoreService ?? FirestoreService.instance;

  static final FirebaseAuthService instance = FirebaseAuthService._();

  final FirebaseAuth _firebaseAuth;
  final FirestoreService _firestoreService;

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    if (!FirebaseProjectConfig.shouldUseFirebaseAuth) {
      throw StateError('Firebase Auth is disabled in FirebaseProjectConfig.');
    }

    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    return _authResultFromUser(
      credential.user,
      fallbackName: credential.user?.email ?? 'Firebase User',
      message: 'Signed in with Firebase.',
    );
  }

  Future<AuthResult?> restoreSession() async {
    if (!FirebaseProjectConfig.shouldUseFirebaseAuth) {
      return null;
    }

    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      return null;
    }

    await currentUser.reload();
    final refreshedUser = _firebaseAuth.currentUser;
    if (refreshedUser == null) {
      return null;
    }

    return _authResultFromUser(
      refreshedUser,
      fallbackName: refreshedUser.email ?? 'Firebase User',
      message: 'Restored Firebase session.',
    );
  }

  Future<AuthResult> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    if (!FirebaseProjectConfig.shouldUseFirebaseAuth) {
      throw StateError('Firebase Auth is disabled in FirebaseProjectConfig.');
    }

    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-created',
        message: 'The nurse account could not be created.',
      );
    }

    final trimmedName = fullName.trim();
    try {
      if (trimmedName.isNotEmpty) {
        await user.updateDisplayName(trimmedName);
      }

      await _firestoreService.nurseUsers.doc(user.uid).set({
        'uid': user.uid,
        'name': trimmedName,
        'email': user.email,
        'role': 'nurse',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      try {
        await user.delete();
      } catch (_) {
        await _firebaseAuth.signOut();
      }
      rethrow;
    }

    await user.reload();
    final refreshedUser = _firebaseAuth.currentUser ?? user;

    return _authResultFromUser(
      refreshedUser,
      fallbackName: trimmedName.isEmpty
          ? (refreshedUser.email ?? 'Nurse')
          : trimmedName,
      message: 'Nurse account created successfully.',
    );
  }

  Future<void> signOut() async {
    if (!FirebaseProjectConfig.shouldUseFirebaseAuth) {
      return;
    }

    await _firebaseAuth.signOut();
  }

  Future<AuthResult> _authResultFromUser(
    User? user, {
    required String fallbackName,
    required String message,
  }) async {
    return AuthResult(
      message: message,
      token: await user?.getIdToken(),
      user: user == null
          ? null
          : {
              'name': (user.displayName?.trim().isNotEmpty ?? false)
                  ? user.displayName!.trim()
                  : fallbackName,
              'email': user.email,
              'uid': user.uid,
            },
      isMock: false,
    );
  }
}
