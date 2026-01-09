import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_service.dart';

final authServiceProvider = Provider((ref) => AuthService());

final authStateProvider = StreamProvider((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;

  AuthController(this._authService) : super(const AsyncValue.data(null));

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _authService.signInWithEmail(email, password),
    );
  }

  Future<void> signup(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _authService.signUpWithEmail(email, password),
    );
  }

  Future<void> googleLogin() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authService.signInWithGoogle());
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
      return AuthController(ref.watch(authServiceProvider));
    });
