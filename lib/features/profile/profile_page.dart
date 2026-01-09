import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/sakura_button.dart';
import '../auth/login_page.dart'; // Ensure this import exists

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: const CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.secondary,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),

              // Email
              Text(
                user?.email ?? "Guest",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Admin Badge (Only shows if admin)
              FutureBuilder(
                future: Supabase.instance.client
                    .from('profiles')
                    .select('is_admin')
                    .eq('id', user!.id)
                    .single(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data?['is_admin'] == true) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text("Admin User",
                          style: TextStyle(color: Colors.white, fontSize: 12)),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              const Spacer(),

              // LOGOUT BUTTON
              SakuraButton(
                text: "Logout",
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  // The app.dart StreamBuilder will handle navigation,
                  // but we can force it just in case:
                  if (context.mounted) {
                    // Clears navigation stack
                    Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false);
                  }
                },
              ),
              const SizedBox(height: 80), // Space for bottom nav
            ],
          ),
        ),
      ),
    );
  }
}
