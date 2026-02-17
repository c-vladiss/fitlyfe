abstract class AuthStategy {
  Future<void> signIn();
  Future<void> handleDeepLink(Uri uri);
  Future<void> signOut();
}
