import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animations/animations.dart';

// Core Imports
import 'core/theme/sakura_theme.dart';
import 'core/theme/app_colors.dart';

// Feature Imports
import 'features/auth/login_page.dart';
import 'features/auth/auth_controller.dart';
import 'features/home/home_page.dart';
import 'features/market/market_page.dart';
import 'features/cart/cart_page.dart';
import 'features/profile/profile_page.dart';
import 'features/message/message_page.dart'; // Import Message Page

class TKairosApp extends ConsumerWidget {
  const TKairosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'T Kairos Shop',
      debugShowCheckedModeBanner: false,
      theme: SakuraTheme.lightTheme,
      home: authState.when(
        data: (state) =>
            state.session != null ? const MainScaffold() : const LoginPage(),
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
        error: (e, _) => Scaffold(
          body: Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  // Deep Pink for High Contrast Active State
  final Color _activeColor = const Color(0xFFE91E63);

  // The 5 Tabs (Connected MessagePage)
  final List<Widget> _pages = [
    const HomePage(),
    const MarketPage(),
    const CartPage(),
    const MessagePage(), // Real Chat Page
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,

      // Smooth Fade Transition (No Jump)
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation, secondaryAnimation) {
          return FadeThroughTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            fillColor: Colors.transparent,
            child: child,
          );
        },
        child: _pages[_currentIndex],
      ),

      // 🌸 Glass Bottom Navigation Bar
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 85,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: Colors.white.withOpacity(0.6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 30,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              selectedItemColor: _activeColor,
              unselectedItemColor: Colors.grey.shade500,
              selectedLabelStyle: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold, height: 2),
              unselectedLabelStyle: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w500, height: 2),
              items: [
                BottomNavigationBarItem(
                  icon: _glassIcon(
                      icon: Icons.home_outlined,
                      active: _currentIndex == 0,
                      color: _activeColor),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: _glassIcon(
                      icon: Icons.storefront_outlined,
                      active: _currentIndex == 1,
                      color: _activeColor),
                  label: 'Market',
                ),
                BottomNavigationBarItem(
                  icon: _glassIcon(
                      icon: Icons.shopping_bag_outlined,
                      active: _currentIndex == 2,
                      color: _activeColor),
                  label: 'Cart',
                ),
                BottomNavigationBarItem(
                  icon: _glassIcon(
                      icon: Icons.chat_bubble_outline,
                      active: _currentIndex == 3,
                      color: _activeColor),
                  label: 'Message',
                ),
                BottomNavigationBarItem(
                  icon: _glassIcon(
                      icon: Icons.person_outline,
                      active: _currentIndex == 4,
                      color: _activeColor),
                  label: 'Me',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 🌸 Animated Glass Icon (NO POP UP)
/// Just fades color and background smoothly
Widget _glassIcon({
  required IconData icon,
  required bool active,
  required Color color,
}) {
  return AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut, // Smooth curve, no bounce

    // Removed Matrix Transform (No Scale/Translate)

    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      // Background remains soft light pink
      color: active ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
    ),
    child: Icon(
      active ? _getFilledIcon(icon) : icon,
      size: 24,
      color: active ? color : Colors.grey.shade500,
    ),
  );
}

IconData _getFilledIcon(IconData icon) {
  if (icon == Icons.home_outlined) return Icons.home_rounded;
  if (icon == Icons.storefront_outlined) return Icons.storefront_rounded;
  if (icon == Icons.shopping_bag_outlined) return Icons.shopping_bag_rounded;
  if (icon == Icons.chat_bubble_outline) return Icons.chat_bubble_rounded;
  if (icon == Icons.person_outline) return Icons.person_rounded;
  return icon;
}
