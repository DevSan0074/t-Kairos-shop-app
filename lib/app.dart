import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animations/animations.dart';

// Core
import 'core/theme/sakura_theme.dart';
import 'core/theme/app_colors.dart';

// Features
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
      // Smooth iOS-like page transition
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 350),
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

      // 🌸 iOS 26 Glass Bottom Navigation Bar
      extendBody: true, // IMPORTANT: Allows body to go behind the glass bar
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 78,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.65),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                color: Colors.white.withOpacity(0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
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
              selectedItemColor: AppColors.primary,
              unselectedItemColor: Colors.grey.shade500,
              selectedLabelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              items: [
                BottomNavigationBarItem(
                  icon: _glassIcon(
                    icon: Icons.home_outlined,
                    active: _currentIndex == 0,
                  ),
                  activeIcon:
                      _glassIcon(icon: Icons.home_rounded, active: true),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: _glassIcon(
                    icon: Icons.storefront_outlined,
                    active: _currentIndex == 1,
                  ),
                  activeIcon:
                      _glassIcon(icon: Icons.storefront_rounded, active: true),
                  label: 'Market',
                ),
                BottomNavigationBarItem(
                  icon: _glassIcon(
                    icon: Icons.shopping_bag_outlined,
                    active: _currentIndex == 2,
                  ),
                  activeIcon: _glassIcon(
                      icon: Icons.shopping_bag_rounded, active: true),
                  label: 'Cart',
                ),
                BottomNavigationBarItem(
                  icon: _glassIcon(
                    icon: Icons.chat_bubble_outline,
                    active: _currentIndex == 3,
                  ),
                  activeIcon:
                      _glassIcon(icon: Icons.chat_bubble_rounded, active: true),
                  label: 'Message',
                ),
                BottomNavigationBarItem(
                  icon: _glassIcon(
                    icon: Icons.person_outline,
                    active: _currentIndex == 4,
                  ),
                  activeIcon:
                      _glassIcon(icon: Icons.person_rounded, active: true),
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

/// Glass-style animated icon (iOS look)
Widget _glassIcon({
  required IconData icon,
  required bool active,
}) {
  return AnimatedContainer(
    duration: const Duration(milliseconds: 220),
    curve: Curves.easeOut,
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: active ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
    ),
    child: Icon(
      icon,
      size: 24,
      color: active ? AppColors.primary : Colors.grey.shade500,
    ),
  );
}
