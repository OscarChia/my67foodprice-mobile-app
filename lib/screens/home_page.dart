import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'food_details_page.dart';

class HomePage extends StatefulWidget {
  final Function(String?) onSearchTap;
  final Function(int) onNavigationTap;
  final VoidCallback onNotificationTap;

  const HomePage({
    super.key,
    required this.onSearchTap,
    required this.onNavigationTap,
    required this.onNotificationTap,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color primaryGreen = Color(0xFF176B52);
  static const Color darkGreen = Color(0xFF0F513D);
  static const Color backgroundColor = Color(0xFFF6F8F5);
  static const Color lightGreen = Color(0xFFEAF4EF);
  static const Color textColor = Color(0xFF1F2924);

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
            'item':
            itemData['item'] ?? 'Unknown Item',
            'category':
            itemData['item_category'] ?? '',
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
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String formatPrice(dynamic value) {
    final price =
        double.tryParse(value.toString()) ?? 0;

    return price.toStringAsFixed(2);
  }

  Widget sectionHeader({
    required String title,
    String? actionText,
    VoidCallback? onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const Spacer(),
          if (actionText != null)
            TextButton(
              onPressed: onPressed,
              child: Text(
                actionText,
                style: const TextStyle(
                  color: primaryGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget statisticCard({
    required String value,
    required String title,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        height: 96,
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE6ECE8),
          ),
        ),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: primaryGreen,
              size: 22,
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.black54,
              ),
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
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        widget.onSearchTap(category);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE6ECE8),
          ),
        ),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: lightGreen,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 25,
                color: primaryGreen,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor,
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
            FoodDetailsPage(
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
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE6ECE8),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          openFoodDetails(food);
        },
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: lightGreen,
                borderRadius:
                BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.shopping_basket_outlined,
                color: primaryGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    food['item'].toString(),
                    maxLines: 2,
                    overflow:
                    TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight:
                      FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${food['category']} • ${food['unit']}',
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
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment:
              CrossAxisAlignment.end,
              children: [
                Text(
                  'RM ${formatPrice(food['price'])}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Latest',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.black38,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget featuredItemCard(
      Map<String, dynamic> food,
      ) {
    return Container(
      width: 168,
      margin: const EdgeInsets.only(
        right: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE6ECE8),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
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
                height: 83,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius:
                  BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  size: 40,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                food['item'].toString(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const Spacer(),
              Text(
                'RM ${formatPrice(food['price'])}',
                style: const TextStyle(
                  fontSize: 17,
                  color: primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'per ${food['unit']}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE6ECE8),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: lightGreen,
                borderRadius:
                BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                size: 23,
                color: primaryGreen,
              ),
            ),
            const SizedBox(width: 10),
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
                      FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9,
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
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryGreen,
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
                    20,
                    15,
                    20,
                    30,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryGreen,
                        darkGreen,
                      ],
                    ),
                    borderRadius:
                    BorderRadius.only(
                      bottomLeft:
                      Radius.circular(30),
                      bottomRight:
                      Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration:
                            BoxDecoration(
                              color: Colors.white
                                  .withValues(
                                alpha: 0.15,
                              ),
                              borderRadius:
                              BorderRadius
                                  .circular(13),
                            ),
                            child: const Icon(
                              Icons
                                  .shopping_basket_rounded,
                              color: Colors.white,
                              size: 23,
                            ),
                          ),
                          const SizedBox(width: 11),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                              children: [
                                Text(
                                  'My67Food Price',
                                  style: TextStyle(
                                    color:
                                    Colors.white,
                                    fontSize: 20,
                                    fontWeight:
                                    FontWeight
                                        .bold,
                                  ),
                                ),
                                Text(
                                  'Malaysia Food Price Comparison',
                                  style: TextStyle(
                                    color:
                                    Color(
                                        0xFFDCEDE6),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 42,
                            height: 42,
                            decoration:
                            BoxDecoration(
                              color: Colors.white
                                  .withValues(
                                alpha: 0.15,
                              ),
                              shape:
                              BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: widget.onNotificationTap,
                              icon: const Icon(
                                Icons.notifications_none_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'Find better food prices',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight:
                          FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        latestDate.isEmpty
                            ? 'Compare prices across Malaysia'
                            : 'Latest data updated $latestDate',
                        style: const TextStyle(
                          color:
                          Color(0xFFDCEDE6),
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Material(
                        color: Colors.white,
                        borderRadius:
                        BorderRadius.circular(
                            17),
                        child: InkWell(
                          borderRadius:
                          BorderRadius.circular(
                              17),
                          onTap: () {
                            widget.onSearchTap(null);
                          },
                          child: Container(
                            height: 55,
                            padding:
                            const EdgeInsets
                                .symmetric(
                              horizontal: 16,
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  color:
                                  primaryGreen,
                                ),
                                SizedBox(width: 11),
                                Expanded(
                                  child: Text(
                                    'Search food prices...',
                                    style:
                                    TextStyle(
                                      fontSize: 14,
                                      color: Colors
                                          .black45,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons
                                      .tune_rounded,
                                  color:
                                  Colors.black38,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                Padding(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  child: Row(
                    children: [
                      statisticCard(
                        value: '320+',
                        title: 'Food Items',
                        icon: Icons
                            .restaurant_menu_rounded,
                      ),
                      const SizedBox(width: 9),
                      statisticCard(
                        value: '16',
                        title: 'States',
                        icon: Icons
                            .location_on_outlined,
                      ),
                      const SizedBox(width: 9),
                      statisticCard(
                        value: '463K+',
                        title: 'Price Records',
                        icon:
                        Icons.analytics_outlined,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 23),

                sectionHeader(
                  title: 'Food Categories',
                  actionText: 'See all',
                  onPressed: () {
                    widget.onSearchTap(null);
                  },
                ),

                const SizedBox(height: 6),

                Padding(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  child: GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics:
                    const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.02,
                    children: [
                      categoryCard(
                        title: 'Sayur-sayuran',
                        category:
                        'SAYUR-SAYURAN',
                        icon: Icons.eco_outlined,
                      ),
                      categoryCard(
                        title: 'Buah-buahan',
                        category:
                        'BUAH-BUAHAN',
                        icon: Icons.apple,
                      ),
                      categoryCard(
                        title: 'Daging',
                        category: 'DAGING',
                        icon:
                        Icons.restaurant,
                      ),
                      categoryCard(
                        title: 'Bahan Laut',
                        category:
                        'BAHAN LAUT',
                        icon: Icons.set_meal,
                      ),
                      categoryCard(
                        title: 'Minumam',
                        category:
                        'TERSEDIA MINUM',
                        icon: Icons
                            .local_drink_outlined,
                      ),
                      categoryCard(
                        title: 'Beras',
                        category: 'BERAS',
                        icon:
                        Icons.rice_bowl_outlined,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Padding(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Latest Prices',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight:
                          FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const Spacer(),
                      if (latestDate.isNotEmpty)
                        Container(
                          padding:
                          const EdgeInsets
                              .symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration:
                          BoxDecoration(
                            color: lightGreen,
                            borderRadius:
                            BorderRadius
                                .circular(20),
                          ),
                          child: Text(
                            latestDate,
                            style:
                            const TextStyle(
                              fontSize: 9,
                              color:
                              primaryGreen,
                              fontWeight:
                              FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                Padding(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  child: isLoading
                      ? const Padding(
                    padding:
                    EdgeInsets.all(
                        30),
                    child: Center(
                      child:
                      CircularProgressIndicator(
                        color:
                        primaryGreen,
                      ),
                    ),
                  )
                      : latestPrices.isEmpty
                      ? Container(
                    width:
                    double.infinity,
                    padding:
                    const EdgeInsets
                        .all(25),
                    decoration:
                    BoxDecoration(
                      color:
                      Colors.white,
                      borderRadius:
                      BorderRadius
                          .circular(
                          18),
                    ),
                    child:
                    const Text(
                      'No latest price data found.',
                      textAlign:
                      TextAlign
                          .center,
                      style:
                      TextStyle(
                        color: Colors
                            .black45,
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

                sectionHeader(
                  title: 'Featured Items',
                  actionText: 'View all',
                  onPressed: () {
                    widget.onSearchTap(null);
                  },
                ),

                const SizedBox(height: 7),

                SizedBox(
                  height: 220,
                  child: featuredItems.isEmpty
                      ? const Center(
                    child: Text(
                      'No featured items',
                      style: TextStyle(
                        color:
                        Colors.black45,
                      ),
                    ),
                  )
                      : ListView.builder(
                    scrollDirection:
                    Axis.horizontal,
                    padding:
                    const EdgeInsets.only(
                      left: 20,
                      right: 8,
                    ),
                    itemCount:
                    featuredItems.length,
                    itemBuilder:
                        (context, index) {
                      return featuredItemCard(
                        featuredItems[index],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                sectionHeader(
                  title: 'Quick Access',
                ),

                const SizedBox(height: 7),

                Padding(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics:
                    const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.15,
                    children: [
                      quickNavigationCard(
                        title: 'Store Map',
                        subtitle:
                        'Find nearby premises',
                        icon:
                        Icons.map_outlined,
                        onTap: () {
                          widget
                              .onNavigationTap(2);
                        },
                      ),
                      quickNavigationCard(
                        title: 'Price Trends',
                        subtitle:
                        'Analyse price history',
                        icon: Icons
                            .show_chart_rounded,
                        onTap: () {
                          widget
                              .onNavigationTap(3);
                        },
                      ),
                      quickNavigationCard(
                        title: 'Saved Items',
                        subtitle:
                        'View favourites',
                        icon: Icons
                            .favorite_border,
                        onTap: () {
                          widget
                              .onNavigationTap(4);
                        },
                      ),
                      quickNavigationCard(
                        title: 'My Profile',
                        subtitle:
                        'Account settings',
                        icon:
                        Icons.person_outline,
                        onTap: () {
                          widget
                              .onNavigationTap(5);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 35),
              ],
            ),
          ),
        ),
      ),
    );
  }
}