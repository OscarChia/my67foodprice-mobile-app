import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'food_comparison_page.dart';

class HomePage extends StatefulWidget {
  final Function(String?) onSearchTap;
  final Function(int) onNavigationTap;

  const HomePage({
    super.key,
    required this.onSearchTap,
    required this.onNavigationTap,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isLoading = true;

  List<Map<String, dynamic>> latestPrices = [];
  List<Map<String, dynamic>> featuredItems = [];

  String latestDate = '';

  @override
  void initState() {
    super.initState();

    fetchHomeData();
  }

  Future<void> fetchHomeData() async {
    try {
      final latestData = await Supabase.instance.client
          .from('food_prices')
          .select('date')
          .order(
        'date',
        ascending: false,
      )
          .limit(1);

      if (latestData.isEmpty) {
        if (!mounted) {
          return;
        }

        setState(() {
          isLoading = false;
        });

        return;
      }

      final newestDate =
      latestData.first['date'].toString();

      final priceData = await Supabase.instance.client
          .from('food_prices')
          .select()
          .eq(
        'date',
        newestDate,
      )
          .limit(80);

      List<dynamic> usedItemCodes = [];

      List<Map<String, dynamic>> uniquePrices = [];

      for (final price in priceData) {
        final itemCode = price['item_code'];

        if (!usedItemCodes.contains(itemCode)) {
          usedItemCodes.add(itemCode);

          uniquePrices.add(
            Map<String, dynamic>.from(price),
          );
        }

        if (uniquePrices.length >= 12) {
          break;
        }
      }

      List<Map<String, dynamic>> combinedList = [];

      for (final price in uniquePrices) {
        final itemData = await Supabase.instance.client
            .from('food_items')
            .select()
            .eq(
          'item_code',
          price['item_code'],
        )
            .maybeSingle();

        if (itemData != null) {
          combinedList.add({
            'item_code': price['item_code'],
            'item': itemData['item'] ?? 'Unknown Item',
            'category': itemData['item_category'] ?? '',
            'unit': itemData['unit'] ?? '',
            'price': price['price'],
            'date': price['date'],
          });
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        latestDate = newestDate;

        latestPrices =
            combinedList.take(4).toList();

        featuredItems =
            combinedList.take(8).toList();

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error loading dashboard: $e',
          ),
        ),
      );
    }
  }

  Widget statisticCard({
    required String value,
    required String title,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        height: 82,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget categoryCard({
    required String title,
    required String category,
    required IconData icon,
    required Color color,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        widget.onSearchTap(category);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 27,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
              ),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void openFoodDetails(
      Map<String, dynamic> food,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            FoodComparisonPage(
              itemCode: food['item_code'],
              itemName: food['item'],
              unit: food['unit'],
            ),
      ),
    );
  }

  Widget latestPriceCard(
      Map<String, dynamic> food,
      ) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: () {
          openFoodDetails(food);
        },
        leading: CircleAvatar(
          backgroundColor:
          Colors.teal.shade50,
          child: const Icon(
            Icons.shopping_basket,
            color: Colors.teal,
          ),
        ),
        title: Text(
          food['item'].toString(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        subtitle: Text(
          '${food['category']} • ${food['unit']}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black54,
          ),
        ),
        trailing: Text(
          'RM ${double.parse(food['price'].toString()).toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
      ),
    );
  }

  Widget featuredItemCard(
      Map<String, dynamic> food,
      ) {
    return Container(
      width: 165,
      margin: const EdgeInsets.only(
        right: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(16),
        onTap: () {
          openFoodDetails(food);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius:
                  BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.fastfood,
                  size: 40,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                food['item'].toString(),
                maxLines: 2,
                overflow:
                TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'RM ${double.parse(food['price'].toString()).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.teal,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                food['unit'].toString(),
                maxLines: 1,
                overflow:
                TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget quickNavigationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius:
      BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius:
                BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 23,
                color: color,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 8,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7F6),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: fetchHomeData,
          child: SingleChildScrollView(
            physics:
            const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.fromLTRB(
                    18,
                    12,
                    18,
                    28,
                  ),
                  decoration:
                  const BoxDecoration(
                    color:
                    Color(0xFF159A7D),
                    borderRadius:
                    BorderRadius.only(
                      bottomLeft:
                      Radius.circular(24),
                      bottomRight:
                      Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 17,
                            color:
                            Colors.white70,
                          ),
                          const SizedBox(
                            width: 4,
                          ),
                          const Text(
                            'MALAYSIA',
                            style: TextStyle(
                              color:
                              Colors.white,
                              fontSize: 12,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 42,
                            height: 42,
                            decoration:
                            BoxDecoration(
                              color: Colors.white
                                  .withOpacity(
                                0.18,
                              ),
                              shape:
                              BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                Icons
                                    .notifications_none,
                                color:
                                Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'My67Food Price',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        latestDate.isEmpty
                            ? 'Smart Food Price Comparison'
                            : 'Smart Food Price Comparison • Updated $latestDate',
                        style:
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        readOnly: true,
                        onTap: () {
                          widget.onSearchTap(
                            null,
                          );
                        },
                        decoration:
                        InputDecoration(
                          hintText:
                          'Search food prices...',
                          prefixIcon:
                          const Icon(
                            Icons.search,
                          ),
                          filled: true,
                          fillColor:
                          Colors.white,
                          contentPadding:
                          const EdgeInsets
                              .symmetric(
                            vertical: 13,
                          ),
                          border:
                          OutlineInputBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                              16,
                            ),
                            borderSide:
                            BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                Padding(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  child: Row(
                    children: [
                      statisticCard(
                        value: '320',
                        title:
                        'Items Tracked',
                        color: Colors.teal,
                      ),
                      const SizedBox(width: 8),
                      statisticCard(
                        value: '16',
                        title: 'States',
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      statisticCard(
                        value: '463K',
                        title:
                        'Price Records',
                        color:
                        Colors.deepOrange,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 23),

                Padding(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Food Categories',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          widget.onSearchTap(
                            null,
                          );
                        },
                        child: const Text(
                          'See all >',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                Padding(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  child: GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics:
                    const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 9,
                    mainAxisSpacing: 9,
                    childAspectRatio: 1.05,
                    children: [
                      categoryCard(
                        title: 'Vegetables',
                        category:
                        'SAYUR-SAYURAN',
                        icon: Icons.eco,
                        color:
                        Colors.green,
                      ),
                      categoryCard(
                        title: 'Fruits',
                        category:
                        'BUAH-BUAHAN',
                        icon: Icons
                            .local_florist,
                        color:
                        Colors.orange,
                      ),
                      categoryCard(
                        title: 'Meat',
                        category:
                        'DAGING',
                        icon: Icons
                            .restaurant,
                        color: Colors.red,
                      ),
                      categoryCard(
                        title: 'Seafood',
                        category:
                        'BAHAN LAUT',
                        icon:
                        Icons.set_meal,
                        color: Colors.blue,
                      ),
                      categoryCard(
                        title: 'Drinks',
                        category:
                        'TERSEDIA MINUM',
                        icon: Icons
                            .local_drink,
                        color: Colors
                            .deepPurple,
                      ),
                      categoryCard(
                        title: 'Rice',
                        category:
                        'BERAS',
                        icon: Icons
                            .rice_bowl,
                        color:
                        Colors.brown,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 23),

                Padding(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Latest Updates',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        latestDate,
                        style:
                        const TextStyle(
                          fontSize: 10,
                          color:
                          Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 9),

                Padding(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  child: isLoading
                      ? const Center(
                    child:
                    CircularProgressIndicator(),
                  )
                      : latestPrices.isEmpty
                      ? const Center(
                    child: Padding(
                      padding:
                      EdgeInsets.all(
                        20,
                      ),
                      child: Text(
                        'No latest data found',
                      ),
                    ),
                  )
                      : Column(
                    children:
                    latestPrices
                        .map(
                          (food) =>
                          latestPriceCard(
                            food,
                          ),
                    )
                        .toList(),
                  ),
                ),

                const SizedBox(height: 20),

                Padding(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Featured Items',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          widget.onSearchTap(
                            null,
                          );
                        },
                        child: const Text(
                          'View all >',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                SizedBox(
                  height: 215,
                  child: featuredItems.isEmpty
                      ? const Center(
                    child: Text(
                      'No featured items',
                    ),
                  )
                      : ListView.builder(
                    scrollDirection:
                    Axis.horizontal,
                    padding:
                    const EdgeInsets.only(
                      left: 16,
                      right: 4,
                    ),
                    itemCount:
                    featuredItems.length,
                    itemBuilder:
                        (context, index) {
                      return featuredItemCard(
                        featuredItems[
                        index],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 23),

                const Padding(
                  padding:
                  EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  child: Text(
                    'Quick Navigation',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Padding(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics:
                    const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 9,
                    mainAxisSpacing: 9,
                    childAspectRatio: 2.1,
                    children: [
                      quickNavigationCard(
                        title: 'Store Map',
                        subtitle:
                        'Find stores near you',
                        icon: Icons.map,
                        color: Colors.blue,
                        onTap: () {
                          widget
                              .onNavigationTap(
                            2,
                          );
                        },
                      ),
                      quickNavigationCard(
                        title:
                        'Price Trends',
                        subtitle:
                        'View price history',
                        icon:
                        Icons.show_chart,
                        color:
                        Colors.purple,
                        onTap: () {
                          widget
                              .onNavigationTap(
                            3,
                          );
                        },
                      ),
                      quickNavigationCard(
                        title:
                        'My Favourites',
                        subtitle:
                        'Saved food items',
                        icon:
                        Icons.favorite,
                        color: Colors.pink,
                        onTap: () {
                          widget
                              .onNavigationTap(
                            4,
                          );
                        },
                      ),
                      quickNavigationCard(
                        title: 'Profile',
                        subtitle:
                        'Account settings',
                        icon:
                        Icons.settings,
                        color: Colors
                            .blueGrey,
                        onTap: () {
                          widget
                              .onNavigationTap(
                            5,
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}