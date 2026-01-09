import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../constants/app_strings.dart';

// Supabase Service Initialization
class SupabaseService {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppStrings.supabaseUrl,
      anonKey: AppStrings.supabaseAnonKey,
    );
  }
}

// Auth Service
class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // serverClientId: 'YOUR_SERVER_CLIENT_ID', // Required for Android
  );

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  User? get currentUser => _supabase.auth.currentUser;

  Future<void> signInWithEmail(String email, String password) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUpWithEmail(String email, String password) async {
    await _supabase.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw 'Google Sign-In aborted';

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) throw 'No Access Token found.';
      if (idToken == null) throw 'No ID Token found.';

      return _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _supabase.auth.signOut();
  }
}
