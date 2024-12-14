import 'package:mynotes/services/auth/auth_exceptions.dart';
import 'package:mynotes/services/auth/auth_provider.dart';
import 'package:mynotes/services/auth/auth_user.dart';
import 'package:test/test.dart';

void main() {
  group('Mock Authentication', () {
    final provider = MockAuthProvider();
    test('should not be initialized to begin with', () {
      expect(provider.isInitialized, false);
    });
    test('cannot log out if not initialized', () {
      expect(provider.logOut(),
          throwsA(const TypeMatcher<NotInitializedException>()));
    });
    test('should be able to be initializedd', () async {
      await provider.initializeApp();
      expect(provider._isInitialized, true);
    });
    test('user should be null after initialization', () {
      expect(provider.currentUser, null);
    });
    test('Should be able to initialize in less than 2 seconds', () async {
      await provider.initializeApp();
      expect(provider.isInitialized, true);
    }, timeout: const Timeout(Duration(seconds: 3)));

    test('Create user should delegate to login function', () async {
      final badEmailUser =
          provider.createUser(email: 'mide@test.com', password: 'password1');
      expect(badEmailUser,
          throwsA(const TypeMatcher<InvalidEmailAuthException>()));

      final badPasswordUser = provider.createUser(
          email: 'xquizit52@gmail.com', password: 'password');
      expect(badPasswordUser,
          throwsA(const TypeMatcher<WrongPasswordAuthException>()));

      final user = await provider.createUser(
          email: 'xquizit52@gmail.com', password: 'password1');
      expect(provider.currentUser, user);
      expect(user.isEmailVerified, false);
    });

    test('Logged in user should be able to get verified', () {
      provider.sendEmailVerification();
      final user = provider.currentUser;
      expect(user, isNotNull);
      expect(user!.isEmailVerified, true);
    });

    test('Should be able to log out and in again', () async {
      await provider.logOut();
      await provider.login(email: 'email', password: 'password');
      final user = provider.currentUser;
      expect(user, isNotNull);
    });
  });
}

class NotInitializedException implements Exception {}

class MockAuthProvider implements AuthProvider {
  AuthUser? _user;
  var _isInitialized = false;
  bool get isInitialized => _isInitialized;

  @override
  Future<AuthUser> createUser(
      {required String email, required String password}) async {
    if (!isInitialized) throw NotInitializedException();
    await Future.delayed(const Duration(seconds: 1));
    return login(
      email: email,
      password: password,
    );
  }

  @override
  AuthUser? get currentUser => _user;

  @override
  Future<void> initializeApp() async {
    await Future.delayed(const Duration(seconds: 3));
    _isInitialized = true;
  }

  @override
  Future<void> logOut() async {
    if (!isInitialized) throw NotInitializedException();
    if (_user == null) throw UserNotFoundAuthException();
    await Future.delayed(const Duration(seconds: 1));
    _user = null;
  }

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) {
    if (!isInitialized) throw NotInitializedException();
    if (email == "mide@test.com") throw UserNotFoundAuthException;
    if (password == "password") throw WrongPasswordAuthException;
    const user = AuthUser(isEmailVerified: false, email: '', id: 'mmm');
    _user = user;
    return Future.value(user);
  }

  @override
  Future<void> sendEmailVerification() async {
    if (!isInitialized) throw NotInitializedException();
    final user = _user;
    if (user == null) throw UserNotFoundAuthException();
    const newUser = AuthUser( isEmailVerified: true, email: '', id: 'dks');
    _user = newUser;
  }
}
