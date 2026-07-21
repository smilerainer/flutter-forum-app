import 'package:flutter_test/flutter_test.dart';
import 'package:forum_app/router.dart';

void main() {
  group('authRedirect', () {
    test('logged out, /login -> stays', () {
      expect(authRedirect(loggedIn: false, matchedLocation: '/login'), isNull);
    });
    test('logged out, /register -> stays', () {
      expect(authRedirect(loggedIn: false, matchedLocation: '/register'), isNull);
    });
    test('logged out, /posts -> stays (public route)', () {
      expect(authRedirect(loggedIn: false, matchedLocation: '/posts'), isNull);
    });
    test('logged out, /profile -> redirected to /login', () {
      expect(authRedirect(loggedIn: false, matchedLocation: '/profile'), '/login');
    });
    test('logged in, /login -> redirected to /posts', () {
      expect(authRedirect(loggedIn: true, matchedLocation: '/login'), '/posts');
    });
    test('logged in, /register -> redirected to /posts', () {
      expect(authRedirect(loggedIn: true, matchedLocation: '/register'), '/posts');
    });
    test('logged in, /posts -> stays', () {
      expect(authRedirect(loggedIn: true, matchedLocation: '/posts'), isNull);
    });
    test('logged in, /profile -> stays', () {
      expect(authRedirect(loggedIn: true, matchedLocation: '/profile'), isNull);
    });
  });
}