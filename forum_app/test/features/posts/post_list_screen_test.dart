import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:forum_app/core/result.dart';
import 'package:forum_app/features/auth/logic/auth_view_model.dart';
import 'package:forum_app/features/posts/presentation/screens/post_list_screen.dart';
import 'package:mocktail/mocktail.dart';
import 'package:forum_app/features/profile/data/profile_service.dart';
import 'package:forum_app/features/profile/data/user_profile.dart';
import 'package:forum_app/features/posts/data/post_service.dart';
import 'package:forum_app/features/posts/data/post.dart';
import 'package:forum_app/features/posts/data/paginated_result.dart';

class MockProfileService extends Mock implements ProfileService {}

class MockPostService extends Mock implements PostService {
  static final _emptyPaginated = Success(PaginatedResult<Post>(items: const [], hasMore: false, nextCursor: null));
  
  @override
  Future<Result<PaginatedResult<Post>>> fetchPosts({String? cursor, int limit = 10}) async {
    return _emptyPaginated;
  }
}

class FakeAuthViewModel extends ChangeNotifier implements AuthViewModel {
  bool _loggedIn;
  FakeAuthViewModel({this._loggedIn = false});

  @override
  bool get isLoggedIn => _loggedIn;

  @override
  User? get user => null;

  @override
  UserProfile? get profile => null;

  @override
  bool get isAdmin => false;

  @override
  Future<void> signOut() async {
    _loggedIn = false;
    notifyListeners();
  }

  @override
  Future<Result<void>> signIn(String email, String password) async {
    _loggedIn = true;
    notifyListeners();
    return const Success(null);
  }

  @override
  Future<Result<void>> signUp(String email, String password) async {
    _loggedIn = true;
    notifyListeners();
    return const Success(null);
  }
}

void main() {
  Widget wrap(FakeAuthViewModel fake, {ProfileService? profileService, PostService? postService}) => ChangeNotifierProvider<AuthViewModel>.value(
        value: fake,
        child: MaterialApp(home: PostListScreen(profileService: profileService, postService: postService)),
      );

  testWidgets('shows Sign out when logged in', (tester) async {
    final mockPost = MockPostService();
    await tester.pumpWidget(wrap(FakeAuthViewModel(loggedIn: true), postService: mockPost));
    expect(find.text('Sign out'), findsOneWidget);
    expect(find.text('Log in'), findsNothing);
  });

  testWidgets('shows Log in when logged out', (tester) async {
    final mockPost = MockPostService();
    await tester.pumpWidget(wrap(FakeAuthViewModel(loggedIn: false), postService: mockPost));
    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('Sign out'), findsNothing);
  });

  testWidgets('tapping Sign out flips state and updates UI', (tester) async {
    final fake = FakeAuthViewModel(loggedIn: true);
    final mockProfile = MockProfileService();
    final mockPost = MockPostService();
    await tester.pumpWidget(wrap(fake, profileService: mockProfile, postService: mockPost));

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(fake.isLoggedIn, isFalse);
    expect(find.text('Log in'), findsOneWidget);
  });
}