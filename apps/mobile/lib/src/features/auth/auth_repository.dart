import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthSession {
  const AuthSession({required this.email, required this.isDemo});

  final String email;
  final bool isDemo;
}

enum AuthFailureReason {
  invalidCredentials,
  emailAlreadyInUse,
  weakPassword,
  offline,
  configurationMissing,
  unknown,
}

class AuthFailure implements Exception {
  const AuthFailure(this.reason);

  final AuthFailureReason reason;

  String get userMessage {
    return switch (reason) {
      AuthFailureReason.invalidCredentials =>
        'Email albo haslo sa nieprawidlowe.',
      AuthFailureReason.emailAlreadyInUse =>
        'Ten email ma juz konto. Sprobuj sie zalogowac.',
      AuthFailureReason.weakPassword =>
        'Haslo jest za slabe. Uzyj co najmniej 6 znakow.',
      AuthFailureReason.offline =>
        'Nie mozemy polaczyc sie z serwerem. Sprawdz internet i sprobuj ponownie.',
      AuthFailureReason.configurationMissing =>
        'Brakuje konfiguracji Supabase dla tego builda.',
      AuthFailureReason.unknown =>
        'Nie udalo sie zalogowac. Sprobuj ponownie za chwile.',
    };
  }

  @override
  String toString() => userMessage;
}

abstract class AuthRepository {
  bool get isConfigured;

  Stream<AuthSession?> get authStateChanges;

  Future<AuthSession?> restoreSession();

  Future<AuthSession> signIn({required String email, required String password});

  Future<AuthSession> signUp({required String email, required String password});

  Future<void> signOut();

  void dispose() {}
}

class SupabaseAuthRepository extends AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  bool get isConfigured => true;

  @override
  Stream<AuthSession?> get authStateChanges {
    return _client.auth.onAuthStateChange.map(
      (event) => _fromSupabaseSession(event.session),
    );
  }

  @override
  Future<AuthSession?> restoreSession() async {
    return _fromSupabaseSession(_client.auth.currentSession);
  }

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return _fromSupabaseSession(response.session) ??
          (throw const AuthFailure(AuthFailureReason.unknown));
    } on AuthException catch (error) {
      throw _mapAuthException(error);
    } catch (error) {
      throw _mapUnknownException(error);
    }
  }

  @override
  Future<AuthSession> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
      );
      return _fromSupabaseSession(response.session) ??
          AuthSession(email: email.trim(), isDemo: false);
    } on AuthException catch (error) {
      throw _mapAuthException(error);
    } catch (error) {
      throw _mapUnknownException(error);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (error) {
      throw _mapUnknownException(error);
    }
  }

  AuthSession? _fromSupabaseSession(Session? session) {
    final userEmail = session?.user.email;
    if (userEmail == null || userEmail.trim().isEmpty) {
      return null;
    }
    return AuthSession(email: userEmail, isDemo: false);
  }
}

class InMemoryAuthRepository extends AuthRepository {
  final _controller = StreamController<AuthSession?>.broadcast();
  AuthSession? _session;

  @override
  bool get isConfigured => false;

  @override
  Stream<AuthSession?> get authStateChanges => _controller.stream;

  @override
  Future<AuthSession?> restoreSession() async => _session;

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    return _setDemoSession(email: email, password: password);
  }

  @override
  Future<AuthSession> signUp({
    required String email,
    required String password,
  }) async {
    return _setDemoSession(email: email, password: password);
  }

  @override
  Future<void> signOut() async {
    _session = null;
    _controller.add(null);
  }

  @override
  void dispose() {
    _controller.close();
  }

  AuthSession _setDemoSession({
    required String email,
    required String password,
  }) {
    final normalizedEmail = email.trim();
    if (!normalizedEmail.contains('@')) {
      throw const AuthFailure(AuthFailureReason.invalidCredentials);
    }
    if (password.length < 6) {
      throw const AuthFailure(AuthFailureReason.weakPassword);
    }

    final session = AuthSession(email: normalizedEmail, isDemo: true);
    _session = session;
    _controller.add(session);
    return session;
  }
}

AuthFailure _mapAuthException(AuthException error) {
  final message = error.message.toLowerCase();
  if (message.contains('invalid login') ||
      message.contains('invalid credentials') ||
      message.contains('email not confirmed')) {
    return const AuthFailure(AuthFailureReason.invalidCredentials);
  }
  if (message.contains('already') || message.contains('registered')) {
    return const AuthFailure(AuthFailureReason.emailAlreadyInUse);
  }
  if (message.contains('weak') ||
      message.contains('password') && message.contains('short')) {
    return const AuthFailure(AuthFailureReason.weakPassword);
  }
  return const AuthFailure(AuthFailureReason.unknown);
}

AuthFailure _mapUnknownException(Object error) {
  final message = error.toString().toLowerCase();
  if (message.contains('socket') ||
      message.contains('network') ||
      message.contains('connection') ||
      message.contains('failed host lookup')) {
    return const AuthFailure(AuthFailureReason.offline);
  }
  return const AuthFailure(AuthFailureReason.unknown);
}
