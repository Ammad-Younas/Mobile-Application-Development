import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'main_screens/account_screen.dart';
import 'main_screens/buy_screen.dart';
import 'main_screens/favorite_screen.dart';
import 'main_screens/home_screen.dart';
import 'main_screens/sell_screen.dart';

class PersistentNavWrapper extends StatefulWidget {
  const PersistentNavWrapper({super.key});

  @override
  State<PersistentNavWrapper> createState() => _PersistentNavWrapperState();
}

class _PersistentNavWrapperState extends State<PersistentNavWrapper> {
  late PersistentTabController _controller;



  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: 0);

  }

  List<Widget> _buildScreens() {
    return [
      HomeScreen(controller: _controller),
      BuyScreen(controller: _controller),
      FavoritesScreen(),
      SellScreen(controller: _controller),
      AccountScreen(),
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.home),
        title: "Home",
        activeColorPrimary: const Color(0xFF1E3A5F),
        inactiveColorPrimary: Colors.grey,
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.build),
        title: "Buy",
        activeColorPrimary: const Color(0xFF1E3A5F),
        inactiveColorPrimary: Colors.grey,
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.favorite_border),
        title: "Favorites",
        activeColorPrimary: const Color(0xFF1E3A5F),
        inactiveColorPrimary: Colors.grey,
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.directions_car),
        title: "Sell",
        activeColorPrimary: const Color(0xFF1E3A5F),
        inactiveColorPrimary: Colors.grey,
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.account_circle),
        title: "Account",
        activeColorPrimary: const Color(0xFF1E3A5F),
        inactiveColorPrimary: Colors.grey,
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      context,
      controller: _controller,
      screens: _buildScreens(),
      items: _navBarsItems(),
      confineToSafeArea: true,
      backgroundColor: Colors.white,
      handleAndroidBackButtonPress: true,
      resizeToAvoidBottomInset: true,
      stateManagement: true,
      hideNavigationBarWhenKeyboardAppears: true,
      decoration: NavBarDecoration(
        borderRadius: BorderRadius.circular(0),
        colorBehindNavBar: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      navBarStyle: NavBarStyle.style1,
    );
  }
}