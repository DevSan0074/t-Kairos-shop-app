import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/loading_indicator.dart';
import '../home/home_page.dart'; // for isAdminProvider
import 'chat_screen.dart';

class MessagePage extends ConsumerWidget {
  const MessagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdminAsync = ref.watch(isAdminProvider);
    final myId = Supabase.instance.client.auth.currentUser!.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Messages",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
      ),
      body: isAdminAsync.when(
        data: (isAdmin) {
          if (!isAdmin) {
            // NORMAL USER: Show only 1 option (Chat with Admin)
            // Ideally, you'd find a specific admin ID. For now, we simulate one or use a placeholder.
            // Replace 'ADMIN_ID_HERE' with your actual Admin User ID from Supabase Auth table
            // Or better yet, we list Admins.
            return _buildAdminList(context);
          } else {
            // ADMIN: Show list of users who have messaged
            return _buildUserList(context);
          }
        },
        error: (e, s) => Center(child: Text("Error: $e")),
        loading: () => const SakuraLoading(),
      ),
    );
  }

  Widget _buildAdminList(BuildContext context) {
    // For now, let's query profiles where is_admin = true
    return FutureBuilder(
      future: Supabase.instance.client
          .from('profiles')
          .select()
          .eq('is_admin', true),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SakuraLoading();
        final admins = snapshot.data as List;

        if (admins.isEmpty)
          return const Center(child: Text("No support available."));

        return ListView.builder(
          itemCount: admins.length,
          itemBuilder: (context, index) {
            final admin = admins[index];
            return ListTile(
              leading: const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.support_agent, color: Colors.white)),
              title: Text(admin['username'] ?? "Support Team"),
              subtitle: const Text("Tap to chat"),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ChatScreen(
                          otherUserId: admin['id'],
                          otherUserName: "Support Team"))),
            );
          },
        );
      },
    );
  }

  Widget _buildUserList(BuildContext context) {
    // Query list of unique users who have sent messages
    // This is a simplified fetch. In production, use a dedicated 'conversations' table.
    return FutureBuilder(
      future: Supabase.instance.client
          .from('profiles')
          .select()
          .eq('is_admin', false),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SakuraLoading();
        final users = snapshot.data as List;

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              leading: const CircleAvatar(
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white)),
              title: Text(user['email'] ?? "User"),
              subtitle: const Text("Customer"),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ChatScreen(
                          otherUserId: user['id'],
                          otherUserName: user['email'] ?? "User"))),
            );
          },
        );
      },
    );
  }
}
