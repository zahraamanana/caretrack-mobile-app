import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config/firebase_project_config.dart';
import '../models/auth_result.dart';
import '../models/user_profile.dart';
import 'firestore_service.dart';
import 'logger_service.dart';

class FirebaseAuthService {
  FirebaseAuthService({
    FirebaseAuth? firebaseAuth,
    FirestoreService? firestoreService,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestoreService = firestoreService ?? FirestoreService.instance;

  static final FirebaseAuthService instance = FirebaseAuthService();

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
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to save nurse profile after Firebase sign-up.',
        error,
        stackTrace,
      );
      try {
        await user.delete();
      } catch (deleteError, deleteStackTrace) {
        AppLogger.error(
          'Failed to roll back Firebase user after sign-up profile save failure.',
          deleteError,
          deleteStackTrace,
        );
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
          : UserProfile(
              id: user.uid,
              name: (user.displayName?.trim().isNotEmpty ?? false)
                  ? user.displayName!.trim()
                  : fallbackName,
               email: (user.email ?? '').trim(),
             ),
    );
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    if (!FirebaseProjectConfig.shouldUseFirebaseAuth) {
      throw StateError('Firebase Auth is disabled in FirebaseProjectConfig.');
    }

    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to send Firebase password reset email.',
        error,
        stackTrace,
      );
      rethrow;
    }
  }
}
