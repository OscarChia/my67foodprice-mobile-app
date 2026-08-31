import 'package:flutter/material.dart';
import '/screens/home_page.dart';
import '/screens/food_price_page.dart';
import '/screens/map_page.dart';
import '/screens/trend_page.dart';
import '/screens/favorites_page.dart';
import '/screens/profile_page.dart';
import '/screens/shopping_list_page.dart';

class MainNavigationPage extends StatefulWidget {
  final int initialIndex;

  const MainNavigationPage({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  static const Color primaryGreen = Color(0xFF176B52);
  static const Color backgroundColor = Color(0xFFF6F8F5);

  late int selectedIndex;

  String? selectedFoodCategory;

  int searchRefreshKey = 0;

  final GlobalKey<FoodPricePageState>foodPriceKey = GlobalKey<FoodPricePageState>();
  final GlobalKey<SavedPageState>savedPageKey = GlobalKey<SavedPageState>();
  final GlobalKey<ShoppingListPageState> shoppingListKey = GlobalKey<ShoppingListPageState>();

  @override
  void initState() {
    super.initState();

    selectedIndex = widget.initialIndex;
  }

  void changePage(int index) {
    setState(() {
      selectedIndex = index;
    });
    if (index == 5) {
      shoppingListKey.currentState
          ?.loadShoppingList();
    }

    if (index == 4) {
      savedPageKey.currentState
          ?.loadSavedItems();
    }

    if (index == 1) {
      foodPriceKey.currentState
          ?.refreshSavedItems();
    }
  }

  void openNotifications() {
    setState(() {
      selectedIndex = 4;
    });

    savedPageKey.currentState
        ?.openNotifications();
  }

  void openSearch(
      String? category
      ) {
    setState(() {
      selectedFoodCategory = category;
      selectedIndex = 1;
    });

    Future.delayed(
      const Duration(
        milliseconds: 100,
      ),
          () {
        foodPriceKey.currentState
            ?.filterByCategory(
          category,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomePage(
        onSearchTap: (category) {
          openSearch(category);
        },
        onNavigationTap: (index) {
          changePage(index);
        },
        onNotificationTap: () {
          openNotifications();
        },
      ),

      FoodPricePage(
        key: foodPriceKey,
        initialCategory: selectedFoodCategory,
      ),
      const MapPage(),
      const TrendPage(),
      SavedPage(
        key: savedPageKey,
      ),
      ShoppingListPage(
        key: shoppingListKey,
        onBrowseFood: () {
          changePage(1);
        },
      ),
      const ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: backgroundColor,

      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.08,
              ),
              blurRadius: 15,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: selectedIndex,
            type: BottomNavigationBarType.fixed,

            backgroundColor: Colors.white,

            selectedItemColor: primaryGreen,

            unselectedItemColor: Colors.grey,

            selectedFontSize: 11,

            unselectedFontSize: 10,

            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
            ),

            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
            ),

            elevation: 0,

            onTap: (index) {
              changePage(index);
            },

            items: const [
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.home_outlined,
                ),
                activeIcon: Icon(
                  Icons.home_rounded,
                ),
                label: 'Home',
              ),

              BottomNavigationBarItem(
                icon: Icon(
                  Icons.search_outlined,
                ),
                activeIcon: Icon(
                  Icons.search_rounded,
                ),
                label: 'Search',
              ),

              BottomNavigationBarItem(
                icon: Icon(
                  Icons.map_outlined,
                ),
                activeIcon: Icon(
                  Icons.map_rounded,
                ),
                label: 'Map',
              ),

              BottomNavigationBarItem(
                icon: Icon(
                  Icons.show_chart_outlined,
                ),
                activeIcon: Icon(
                  Icons.show_chart_rounded,
                ),
                label: 'Trend',
              ),

              BottomNavigationBarItem(
                icon: Icon(
                  Icons.favorite_border,
                ),
                activeIcon: Icon(
                  Icons.favorite,
                ),
                label: 'Favorites',
              ),

              BottomNavigationBarItem(
                icon: Icon(
                  Icons.shopping_cart_outlined,
                ),
                activeIcon: Icon(
                  Icons.shopping_cart,
                ),
                label: 'Cart',
              ),

              BottomNavigationBarItem(
                icon: Icon(
                  Icons.person_outline,
                ),
                activeIcon: Icon(
                  Icons.person,
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}