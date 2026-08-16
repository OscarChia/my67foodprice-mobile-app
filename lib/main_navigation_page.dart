import 'package:flutter/material.dart';
import '/screens/home_page.dart';
import '/screens/food_price_page.dart';
import '/screens/map_page.dart';
import 'screens/trend_page.dart';

class MainNavigationPage extends StatefulWidget {
  final int initialIndex;

  const MainNavigationPage({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationPage> createState() =>
      _MainNavigationPageState();
}

class _MainNavigationPageState
    extends State<MainNavigationPage> {

  late int selectedIndex;

  String? selectedFoodCategory;

  @override
  void initState() {
    super.initState();

    selectedIndex = widget.initialIndex;
  }

  void changePage(int index) {
    setState(() {
      if (index == 1) {
        selectedFoodCategory = null;
      }

      selectedIndex = index;
    });
  }

  void openSearch(String? category) {
    setState(() {
      selectedFoodCategory = category;
      selectedIndex = 1;
    });
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
      ),

      FoodPricePage(
        key: ValueKey(
          selectedFoodCategory,
        ),
        initialCategory:
        selectedFoodCategory,
      ),

      const MapPage(),
      const TrendPage(),
      const SavedPlaceholderPage(),
      const ProfilePlaceholderPage(),
    ];

    return Scaffold(
      body: pages[selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        type: BottomNavigationBarType.fixed,

        onTap: (index) {
          changePage(index);
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Trend',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Saved',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class SavedPlaceholderPage extends StatelessWidget {
  const SavedPlaceholderPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Saved',
        ),
      ),
      body: const Center(
        child: Text(
          'Favourite items will be displayed here',
        ),
      ),
    );
  }
}

class ProfilePlaceholderPage extends StatelessWidget {
  const ProfilePlaceholderPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
        ),
      ),
      body: const Center(
        child: Text(
          'User profile will be displayed here',
        ),
      ),
    );
  }
}