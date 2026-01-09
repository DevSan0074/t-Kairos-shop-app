import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../auth/login_page.dart';

// --- PROVIDER TO FETCH PROFILE DATA ---
final userProfileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) throw Exception("Not logged in");

  final data = await Supabase.instance.client
      .from('profiles')
      .select()
      .eq('id', user.id)
      .maybeSingle();

  return data ??
      {
        'username': 'User',
        'email': user.email,
        'is_admin': false,
        'score': 0,
        'avatar_url': null,
        'cover_url': null,
        'bio': 'Welcome to my profile'
      };
});

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  // --- UPLOAD LOGIC ---
  Future<void> _uploadImage(String column) async {
    try {
      final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 70); // Optimize size
      if (image == null) return;

      setState(() => _isUploading = true);

      final Uint8List bytes = await image.readAsBytes();
      final String userId = Supabase.instance.client.auth.currentUser!.id;
      final String fileExt = image.path.split('.').last;
      final String fileName =
          '${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final String path = '$userId/$fileName';

      await Supabase.instance.client.storage.from('profiles').uploadBinary(
          path, bytes,
          fileOptions: const FileOptions(upsert: true));

      final String publicUrl =
          Supabase.instance.client.storage.from('profiles').getPublicUrl(path);

      await Supabase.instance.client
          .from('profiles')
          .update({column: publicUrl}).eq('id', userId);

      ref.refresh(userProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Updated!"),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error: $e"), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Clean off-white
      body: Stack(
        children: [
          profileAsync.when(
            data: (profile) => SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  // 1. HEADER (Compact Cover + Avatar)
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      // --- COVER PHOTO (Smaller height: 160) ---
                      GestureDetector(
                        onTap: () => _uploadImage('cover_url'),
                        child: Container(
                          height: 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            image: profile['cover_url'] != null
                                ? DecorationImage(
                                    image: CachedNetworkImageProvider(
                                        profile['cover_url']),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: profile['cover_url'] == null
                              ? Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.camera_alt,
                                          color: Colors.black26, size: 20),
                                      SizedBox(width: 8),
                                      Text("Add Cover",
                                          style: TextStyle(
                                              color: Colors.black26,
                                              fontSize: 14)),
                                    ],
                                  ),
                                )
                              : null,
                        ),
                      ),

                      // --- PROFILE AVATAR (Smaller radius: 45) ---
                      Positioned(
                        bottom: -45,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            GestureDetector(
                              onTap: () => _uploadImage('avatar_url'),
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    )
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 45,
                                  backgroundColor: const Color(0xFFEEEEEE),
                                  backgroundImage: profile['avatar_url'] != null
                                      ? CachedNetworkImageProvider(
                                          profile['avatar_url'])
                                      : null,
                                  child: profile['avatar_url'] == null
                                      ? const Icon(Icons.person,
                                          size: 45, color: Colors.grey)
                                      : null,
                                ),
                              ),
                            ),
                            // Small Edit Badge
                            GestureDetector(
                              onTap: () => _uploadImage('avatar_url'),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt,
                                    size: 12, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 55), // Spacing for avatar overlap

                  // 2. USER INFO (Compact)
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            profile['username'] ?? "User",
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D2D2D)),
                          ),
                          const SizedBox(width: 4),
                          if (profile['is_admin'] == true)
                            const Icon(Icons.verified,
                                color: Colors.blue, size: 18),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile['bio'] ?? "T Kairos Member",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          Supabase.instance.client.auth.currentUser?.email ??
                              "",
                          style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // 3. COMPACT MENU LIST
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildMenuItem(
                            Icons.person_rounded, "Edit Profile", Colors.blue),
                        _buildScoreItem(profile['score'] ?? 0),
                        _buildMenuItem(Icons.headset_mic_rounded, "Help Center",
                            Colors.orange),
                        _buildMenuItem(
                            Icons.map_rounded, "View Map", Colors.teal),

                        // ADMIN PANEL (Conditional)
                        if (profile['is_admin'] == true)
                          _buildMenuItem(Icons.admin_panel_settings_rounded,
                              "Admin Panel", Colors.purple),

                        _buildMenuItem(
                            Icons.info_rounded, "About Us", Colors.green),

                        const SizedBox(height: 16),

                        // COMPACT LOGOUT BUTTON
                        _buildLogoutButton(context),

                        const SizedBox(height: 100), // Bottom padding
                      ],
                    ),
                  ),
                ],
              ),
            ),
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, st) => Center(child: Text("Error: $e")),
          ),
          if (_isUploading)
            Container(
              color: Colors.black45,
              child: const Center(
                  child: CircularProgressIndicator(color: Colors.white)),
            )
        ],
      ),
    );
  }

  // --- COMPACT MENU ITEM ---
  Widget _buildMenuItem(IconData icon, String title, Color color,
      {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10), // Tighter spacing
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // Smaller radius
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), // Very subtle shadow
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap ?? () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12), // Compact padding
            child: Row(
              children: [
                // Small Icon Box
                Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 16),
                // Title
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                // Simple Arrow
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreItem(int score) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
            ),
            const SizedBox(width: 16),
            const Text("My Score",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const Spacer(),
            Text("$score",
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                    fontSize: 16)),
            const SizedBox(width: 4),
            const Icon(Icons.history_rounded, size: 16, color: Colors.amber),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.error.withOpacity(0.15)), // Thin red border
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Supabase.instance.client.auth.signOut();
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.logout_rounded,
                      color: AppColors.error, size: 20),
                ),
                const SizedBox(width: 16),
                const Text(
                  "Logout",
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.error),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
