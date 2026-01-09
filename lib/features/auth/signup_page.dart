import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/sakura_button.dart';
import 'auth_controller.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
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
      } else if (!next.isLoading && !next.hasError) {
        // Success case (checking !isLoading and !hasError is enough for void)
        Navigator.pop(context);
      }
    });
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                    labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
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
                text: 'Sign Up',
                isLoading: authState.isLoading,
                onPressed: () => ref
                    .read(authControllerProvider.notifier)
                    .signup(_emailCtrl.text, _passCtrl.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
