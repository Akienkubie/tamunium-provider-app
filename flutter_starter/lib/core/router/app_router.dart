import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/home/presentation/home_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: _AuthStateNotifier(ref),
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull?.session != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoggingIn) return '/login';
      final isResetting = state.matchedLocation == '/reset-password';
      final isPasswordRecovery = authState.valueOrNull?.event == AuthChangeEvent.passwordRecovery;
      if (isPasswordRecovery && isLoggedIn && !isResetting) return '/reset-password';
      if (isLoggedIn && isLoggingIn) return '/';
      if (isResetting && !isLoggedIn) return '/login';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/reset-password', builder: (context, state) => const ResetPasswordScreen()),
    ],
  );
});

/// Bridges Riverpod's authStateProvider stream into a Listenable so
/// go_router's `refreshListenable` re-evaluates `redirect` on every
/// sign-in/sign-out, not just on first build.
class _AuthStateNotifier extends ChangeNotifier {
  _AuthStateNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}
