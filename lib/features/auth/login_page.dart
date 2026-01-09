import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/sakura_button.dart';
import 'auth_controller.dart';
import 'signup_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen(authControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error.toString()),
          backgroundColor: AppColors.error,
        ));
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- CHANGED HERE: YOUR CUSTOM LOGO ---
                Image.asset(
                  'asset/logo.png', // Uses your file
                  height: 120, // Adjust size as needed
                  fit: BoxFit.contain,
                ),
                // --------------------------------------

                const SizedBox(height: 20),
                const Text("T Kairos Shop",
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark)),
                const SizedBox(height: 10),
                const Text("Login to your premium account",
                    style: TextStyle(color: AppColors.textLight)),
                const SizedBox(height: 40),
                TextField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline)),
                ),
                const SizedBox(height: 24),
                SakuraButton(
                  text: 'Login',
                  isLoading: authState.isLoading,
                  onPressed: () => ref
                      .read(authControllerProvider.notifier)
                      .login(_emailCtrl.text, _passCtrl.text),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(authControllerProvider.notifier).googleLogin(),
                  icon: const Icon(Icons.login),
                  label: const Text("Sign in with Google"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textDark,
                    side: const BorderSide(color: AppColors.textLight),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 24),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SignupPage())),
                  child: const Text("Don't have an account? Sign Up",
                      style: TextStyle(color: AppColors.primary)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
