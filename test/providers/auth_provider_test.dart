import 'package:caretrack/providers/auth_provider.dart';
import 'package:caretrack/services/auth_service.dart';
import 'package:caretrack/services/auth_session_service.dart';
import 'package:caretrack/services/firebase_auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../support/test_helpers.dart';

class _MockAuthService extends Mock implements AuthService {}

class _MockAuthSessionService extends Mock implements AuthSessionService {}

class _MockFirebaseAuthService extends Mock implements FirebaseAuthService {}

void main() {
  late _MockAuthService authService;
  late _MockAuthSessionService sessionService;
  late _MockFirebaseAuthService firebaseAuthService;
  late AuthProvider provider;

  setUpAll(() {
    registerFallbackValue(sampleAuthResult);
  });

  setUp(() {
    authService = _MockAuthService();
    sessionService = _MockAuthSessionService();
    firebaseAuthService = _MockFirebaseAuthService();
    provider = AuthProvider(
      authService: authService,
      sessionService: sessionService,
      firebaseAuthService: firebaseAuthService,
    );
  });

  test('initialize restores and saves Firebase session when available', () async {
    when(
      () => firebaseAuthService.restoreSession(),
    ).thenAnswer((_) async => sampleAuthResult);
    when(
      () => sessionService.saveSession(any()),
    ).thenAnswer((_) async => sampleAuthSession);

    await provider.initialize();

    expect(provider.isInitializing, isFalse);
    expect(provider.isAuthenticated, isTrue);
    expect(provider.session?.userEmail, sampleUser.email);
    verify(() => firebaseAuthService.restoreSession()).called(1);
    verify(() => sessionService.saveSession(any())).called(1);
  });

  test('signIn stores the returned session', () async {
    when(
      () => authService.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => sampleAuthResult);
    when(
      () => sessionService.saveSession(any()),
    ).thenAnswer((_) async => sampleAuthSession);

    final result = await provider.signIn(
      email: sampleUser.email,
      password: 'password123',
    );

    expect(result.token, sampleAuthResult.token);
    expect(provider.isSubmitting, isFalse);
    expect(provider.session?.userName, sampleUser.name);
    verify(
      () => authService.signIn(
        email: sampleUser.email,
        password: 'password123',
      ),
    ).called(1);
  });

  test('signOut clears auth state and persisted session', () async {
    when(() => authService.signOut()).thenAnswer((_) async {});
    when(() => sessionService.clearSession()).thenAnswer((_) async {});

    await provider.signOut();

    expect(provider.isAuthenticated, isFalse);
    verify(() => authService.signOut()).called(1);
    verify(() => sessionService.clearSession()).called(1);
  });
}
