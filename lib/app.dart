import 'dart:ui'; // Required for BackdropFilter (Glass effect)
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

class TKairosApp extends ConsumerWidget {
  const TKairosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch authentication state
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

  // Pages List
  final List<Widget> _pages = const [
    HomePage(),
    MarketPage(),
    CartPage(),
    Scaffold(body: Center(child: Text('Message (Coming Soon)'))),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // CRITICAL: Allows content to scroll behind the glass navigation bar
      extendBody: true,

      // Smooth Fade/Slide Page Transition
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

      // 🌸 Premium Glass Bottom Navigation Bar with Bounce Animation
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 85, // Taller to accommodate bouncing icons
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7), // Glass opacity
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: Colors.white.withOpacity(0.4)),
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
              backgroundColor: Colors.transparent, // Handled by Container
              elevation: 0,

              // Text Styling
              showSelectedLabels: true,
              showUnselectedLabels: true,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: Colors.grey.shade400,
              selectedLabelStyle: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, height: 2),
              unselectedLabelStyle: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w500, height: 2),

              items: [
                BottomNavigationBarItem(
                  icon: _glassIcon(
                      icon: Icons.home_outlined, active: _currentIndex == 0),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: _glassIcon(
                      icon: Icons.storefront_outlined,
                      active: _currentIndex == 1),
                  label: 'Market',
                ),
                BottomNavigationBarItem(
                  icon: _glassIcon(
                      icon: Icons.shopping_bag_outlined,
                      active: _currentIndex == 2),
                  label: 'Cart',
                ),
                BottomNavigationBarItem(
                  icon: _glassIcon(
                      icon: Icons.chat_bubble_outline,
                      active: _currentIndex == 3),
                  label: 'Message',
                ),
                BottomNavigationBarItem(
                  icon: _glassIcon(
                      icon: Icons.person_outline, active: _currentIndex == 4),
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

/// 🌸 Animated Glass Icon with "Pop" Scale Effect
Widget _glassIcon({
  required IconData icon,
  required bool active,
}) {
  return AnimatedContainer(
    duration: const Duration(milliseconds: 350),
    curve: Curves.easeOutBack, // Bouncy effect

    // SCALE TRANSFORMATION: Grow by 25% if active
    transform: Matrix4.identity()..scale(active ? 1.25 : 1.0),
    transformAlignment: Alignment.center,

    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: active ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
    ),
    child: Icon(
      active ? _getFilledIcon(icon) : icon, // Swap to filled icon
      size: 24,
      color: active ? AppColors.primary : Colors.grey.shade500,
    ),
  );
}

// Helper to switch outlined icons to filled icons automatically
IconData _getFilledIcon(IconData icon) {
  if (icon == Icons.home_outlined) return Icons.home_rounded;
  if (icon == Icons.storefront_outlined) return Icons.storefront_rounded;
  if (icon == Icons.shopping_bag_outlined) return Icons.shopping_bag_rounded;
  if (icon == Icons.chat_bubble_outline) return Icons.chat_bubble_rounded;
  if (icon == Icons.person_outline) return Icons.person_rounded;
  return icon; // Fallback
}
