import 'package:flutter/material.dart';
import '../services/database_service.dart';
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
  State<HomePage> createState() =>
      _HomePageState();
}

class _HomePageState
    extends State<HomePage> {
  static const Color primaryGreen = Color(0xFF176B52);
  static const Color darkGreen = Color(0xFF0F513D);
  static const Color backgroundColor = Color(0xFFF6F8F5);
  static const Color lightGreen = Color(0xFFEAF4EF);
  static const Color textColor = Color(0xFF1F2924);
  static const Color secondaryText = Color(0xFF6B756F);

  final DatabaseService databaseService = DatabaseService();

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
    setState(() {
      isLoading = true;
    });

    try {
      final combinedList = await databaseService.getHomeFoodData();

      setState(() {
        if (combinedList.isNotEmpty) {
          latestDate = combinedList.first['date'].toString();
        } else {
          latestDate = '';
        }

        latestPrices =
            combinedList
                .take(4)
                .toList();

        featuredItems =
            combinedList
                .take(8)
                .toList();

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      showMessage(
        'Unable to load dashboard.',
      );
    }
  }

  void showMessage(
      String message,
      ) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

  String formatPrice(
      dynamic value,
      ) {
    final price =
        double.tryParse(
          value.toString(),
        ) ??
            0;

    return price.toStringAsFixed(
      2,
    );
  }

  IconData getFoodIcon(String? category) {
    switch (category?.toUpperCase()) {
      case 'ALL CATEGORIES':
        return Icons.restaurant_menu_rounded;
      case 'AYAM':
        return Icons.kebab_dining_outlined;
      case 'BAHAN LAUT':
        return Icons.set_meal_rounded;
      case 'BAHAN-BAHAN MINUMAN':
        return Icons.local_cafe_rounded;
      case 'BAWANG':
        return Icons.grass_rounded;
      case 'BERAS':
        return Icons.rice_bowl_rounded;
      case 'BIHUN':
        return Icons.ramen_dining_rounded;
      case 'BUAH-BUAHAN':
        return Icons.apple_rounded;
      case 'CILI KERING':
        return Icons.whatshot_rounded;
      case 'DAGING':
        return Icons.kebab_dining_rounded;
      case 'ESEN DAN RAGI':
        return Icons.bakery_dining_rounded;
      case 'GULA':
        return Icons.grain_rounded;
      case 'HASIL LAUT KERING':
        return Icons.set_meal_outlined;
      case 'IKAN DALAM TIN':
        return Icons.inventory_2_rounded;
      case 'IKAN DARAT':
        return Icons.set_meal_rounded;
      case 'KACANG':
        return Icons.eco_rounded;
      case 'KELAPA':
        return Icons.park_rounded;
      case 'KICAP DAN SOS':
        return Icons.water_drop_rounded;
      case 'KRIMER DAN SUSU TEPUNG':
        return Icons.local_drink_rounded;
      case 'MAKANAN BAYI':
        return Icons.child_friendly_rounded;
      case 'MEE/KUETIAU':
        return Icons.ramen_dining_rounded;
      case 'MENTEGA':
        return Icons.breakfast_dining_rounded;
      case 'MI SEGERA':
        return Icons.ramen_dining_rounded;
      case 'MINYAK DAN LEMAK':
        return Icons.water_drop_outlined;
      case 'REMPAH RATUS (BERBUNGKUS)':
        return Icons.spa_rounded;
      case 'REMPAH RATUS (TIDAK BERBUNGKUS)':
        return Icons.spa_outlined;
      case 'SANTAN (KOTAK)':
        return Icons.local_drink_outlined;
      case 'SAPUAN (SPREADS)':
        return Icons.breakfast_dining_outlined;
      case 'SAYUR-SAYURAN':
        return Icons.eco_rounded;
      case 'SUSU BAYI':
        return Icons.baby_changing_station_rounded;
      case 'TELUR':
        return Icons.egg_rounded;
      case 'TEPUNG':
        return Icons.bakery_dining_outlined;
      case 'TERSEDIA MINUM':
        return Icons.local_drink_rounded;
      case 'UBI KENTANG':
        return Icons.eco_outlined;
      default:
        return Icons.restaurant_menu_rounded;
    }
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
              fontSize: 21,
              fontWeight: FontWeight.w800,
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
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
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
        height: 118,
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            18,
          ),
          border: Border.all(
            color: const Color(
              0xFFE6ECE8,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: primaryGreen,
              size: 24,
            ),
            const SizedBox(
              height: 4,
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(
              height: 3,
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
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
      borderRadius: BorderRadius.circular(
        16,
      ),
      onTap: () {
        widget.onSearchTap(
          category,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            16,
          ),
          border: Border.all(
            color: const Color(
              0xFFE1E8E4,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: const BoxDecoration(
                color: lightGreen,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 23,
                color: primaryGreen,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.15,
                fontWeight: FontWeight.w700,
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
        builder: (context) => FoodDetailsPage(
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
        bottom: 11,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: const Color(
            0xFFE6ECE8,
          ),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(
          18,
        ),
        onTap: () {
          openFoodDetails(
            food,
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius: BorderRadius.circular(
                    15,
                  ),
                ),
                child: Icon(
                  getFoodIcon(
                    food['category']?.toString(),
                  ),
                  color: primaryGreen,
                  size: 25,
                ),
              ),
              const SizedBox(
                width: 13,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food['item'].toString(),
                      maxLines: 2,
                      overflow:
                      TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.25,
                        fontWeight:
                        FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    Text(
                      '${food['category']} • ${food['unit']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: secondaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: 9,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'RM ${formatPrice(food['price'])}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: primaryGreen,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  const Text(
                    'Latest',
                    style: TextStyle(
                      fontSize: 12,
                      color: secondaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget featuredItemCard(
      Map<String, dynamic> food,
      ) {
    return Container(
      width: 176,
      margin: const EdgeInsets.only(
        right: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color: const Color(
            0xFFE6ECE8,
          ),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(
          20,
        ),
        onTap: () {
          openFoodDetails(
            food,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(
            13,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 88,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius: BorderRadius.circular(
                    15,
                  ),
                ),
                child: Icon(
                  getFoodIcon(
                    food['category']?.toString(),
                  ),
                  size: 42,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(
                height: 11,
              ),
              Text(
                food['item'].toString(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const Spacer(),
              Text(
                'RM ${formatPrice(food['price'])}',
                style: const TextStyle(
                  fontSize: 18,
                  color: primaryGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(
                height: 3,
              ),
              Text(
                'per ${food['unit']}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: secondaryText,
                  fontWeight: FontWeight.w500,
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
      borderRadius: BorderRadius.circular(
        18,
      ),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            18,
          ),
          border: Border.all(
            color: const Color(
              0xFFE6ECE8,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: lightGreen,
                borderRadius: BorderRadius.circular(
                  14,
                ),
              ),
              child: Icon(
                icon,
                size: 25,
                color: primaryGreen,
              ),
            ),
            const SizedBox(
              width: 12,
            ),
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
                      fontSize: 14,
                      fontWeight:
                      FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight:
                      FontWeight.w500,
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
          child: CustomScrollView(
            physics:
            const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.fromLTRB(
                    20,
                    15,
                    20,
                    30,
                  ),
                  decoration:
                  const BoxDecoration(
                    gradient:
                    LinearGradient(
                      begin:
                      Alignment.topLeft,
                      end:
                      Alignment.bottomRight,
                      colors: [
                        primaryGreen,
                        darkGreen,
                      ],
                    ),
                    borderRadius:
                    BorderRadius.only(
                      bottomLeft:
                      Radius.circular(
                        30,
                      ),
                      bottomRight:
                      Radius.circular(
                        30,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                14,
                              ),
                            ),
                            child: Image.asset(
                              'assets/images/my67food_price_logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(
                            width: 11,
                          ),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                              children: [
                                Text(
                                  'My67Food Price',
                                  style:
                                  TextStyle(
                                    color:
                                    Colors.white,
                                    fontSize:
                                    20,
                                    fontWeight:
                                    FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Malaysia Food Price Comparison',
                                  style: TextStyle(
                                    color: Color(
                                      0xFFDCEDE6,
                                    ),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
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
                            child:
                            IconButton(
                              onPressed: widget
                                  .onNotificationTap,
                              icon:
                              const Icon(
                                Icons
                                    .notifications_none_rounded,
                                color:
                                Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      const Text(
                        'Find better food prices',
                        style:
                        TextStyle(
                          color:
                          Colors.white,
                          fontSize: 26,
                          fontWeight:
                          FontWeight.w700,
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        latestDate.isEmpty
                            ? 'Compare prices across Malaysia'
                            : 'Latest data updated $latestDate',
                        style: const TextStyle(
                          color: Color(
                            0xFFDCEDE6,
                          ),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Material(
                        color:
                        Colors.white,
                        borderRadius:
                        BorderRadius.circular(
                          17,
                        ),
                        child: InkWell(
                          borderRadius:
                          BorderRadius.circular(
                            17,
                          ),
                          onTap: () {
                            widget.onSearchTap(
                              null,
                            );
                          },
                          child: Container(
                            height: 55,
                            padding:
                            const EdgeInsets
                                .symmetric(
                              horizontal:
                              16,
                            ),
                            child:
                            const Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  color:
                                  primaryGreen,
                                ),
                                SizedBox(
                                  width: 11,
                                ),
                                Expanded(
                                  child: Text(
                                    'Search food prices...',
                                    style:
                                    TextStyle(
                                      fontSize: 15,
                                      color: Colors.black45,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons
                                      .tune_rounded,
                                  color:
                                  Colors
                                      .black38,
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
              ),

              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 18,
                ),
              ),

              SliverPadding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                sliver:
                SliverToBoxAdapter(
                  child: Row(
                    children: [
                      statisticCard(
                        value: '320+',
                        title:
                        'Food Items',
                        icon: Icons
                            .restaurant_menu_rounded,
                      ),
                      const SizedBox(
                        width: 9,
                      ),
                      statisticCard(
                        value: '16',
                        title:
                        'States',
                        icon: Icons
                            .location_on_outlined,
                      ),
                      const SizedBox(
                        width: 9,
                      ),
                      statisticCard(
                        value: '463K+',
                        title:
                        'Price Records',
                        icon: Icons
                            .analytics_outlined,
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 23,
                ),
              ),

              SliverToBoxAdapter(
                child: sectionHeader(
                  title:
                  'Food Categories',
                  actionText:
                  'See all',
                  onPressed: () {
                    widget.onSearchTap(
                      null,
                    );
                  },
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 6,
                ),
              ),

              SliverPadding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                sliver: SliverGrid(
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio:
                    1.38,
                  ),
                  delegate:
                  SliverChildListDelegate(
                    [
                      categoryCard(
                        title: 'Sayur-sayuran',
                        category: 'SAYUR-SAYURAN',
                        icon: getFoodIcon(
                          'SAYUR-SAYURAN',
                        ),
                      ),
                      categoryCard(
                        title: 'Buah-buahan',
                        category: 'BUAH-BUAHAN',
                        icon: getFoodIcon(
                          'BUAH-BUAHAN',
                        ),
                      ),
                      categoryCard(
                        title: 'Daging',
                        category: 'DAGING',
                        icon: getFoodIcon(
                          'DAGING',
                        ),
                      ),
                      categoryCard(
                        title: 'Bahan Laut',
                        category: 'BAHAN LAUT',
                        icon: getFoodIcon(
                          'BAHAN LAUT',
                        ),
                      ),
                      categoryCard(
                        title: 'Minuman',
                        category: 'TERSEDIA MINUM',
                        icon: getFoodIcon(
                          'TERSEDIA MINUM',
                        ),
                      ),
                      categoryCard(
                        title: 'Beras',
                        category: 'BERAS',
                        icon: getFoodIcon(
                          'BERAS',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 24,
                ),
              ),

              SliverPadding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                sliver:
                SliverToBoxAdapter(
                  child: Row(
                    children: [
                      const Text(
                        'Latest Prices',
                        style:
                        TextStyle(
                          fontSize: 19,
                          fontWeight:
                          FontWeight.w700,
                          color:
                          textColor,
                        ),
                      ),
                      const Spacer(),
                      if (latestDate
                          .isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          decoration:
                          BoxDecoration(
                            color:
                            lightGreen,
                            borderRadius:
                            BorderRadius
                                .circular(
                              20,
                            ),
                          ),
                          child: Text(
                            latestDate,
                            style: const TextStyle(
                              fontSize: 12,
                              color: primaryGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 10,
                ),
              ),

              if (isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding:
                    EdgeInsets.all(
                      30,
                    ),
                    child: Center(
                      child:
                      CircularProgressIndicator(
                        color:
                        primaryGreen,
                      ),
                    ),
                  ),
                )
              else if (latestPrices.isEmpty)
                SliverPadding(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  sliver:
                  SliverToBoxAdapter(
                    child: Container(
                      width:
                      double.infinity,
                      padding:
                      const EdgeInsets.all(
                        25,
                      ),
                      decoration:
                      BoxDecoration(
                        color:
                        Colors.white,
                        borderRadius:
                        BorderRadius.circular(
                          18,
                        ),
                      ),
                      child:
                      const Text(
                        'No latest price data found.',
                        textAlign:
                        TextAlign.center,
                        style:
                        TextStyle(
                          color:
                          Colors.black45,
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  sliver: SliverList(
                    delegate:
                    SliverChildBuilderDelegate(
                          (
                          context,
                          index,
                          ) {
                        return latestPriceCard(
                          latestPrices[index],
                        );
                      },
                      childCount:
                      latestPrices.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 20,
                ),
              ),

              SliverToBoxAdapter(
                child: sectionHeader(
                  title:
                  'Featured Items',
                  actionText:
                  'View all',
                  onPressed: () {
                    widget.onSearchTap(
                      null,
                    );
                  },
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 7,
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(
                  height: 220,
                  child:
                  featuredItems.isEmpty
                      ? const Center(
                    child: Text(
                      'No featured items',
                      style:
                      TextStyle(
                        color:
                        Colors.black45,
                      ),
                    ),
                  )
                      : SingleChildScrollView(
                    scrollDirection:
                    Axis.horizontal,
                    padding:
                    const EdgeInsets
                        .only(
                      left: 20,
                      right: 8,
                    ),
                    child: Row(
                      children:
                      featuredItems
                          .map(
                            (
                            food,
                            ) =>
                            featuredItemCard(
                              food,
                            ),
                      )
                          .toList(),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 24,
                ),
              ),

              SliverToBoxAdapter(
                child: sectionHeader(
                  title:
                  'Quick Access',
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 7,
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                sliver: SliverGrid(
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.95,
                  ),
                  delegate: SliverChildListDelegate(
                    [
                      quickNavigationCard(
                        title: 'Store Map',
                        subtitle: 'Find nearby premises',
                        icon: Icons.map_outlined,
                        onTap: () {
                          widget.onNavigationTap(
                            2,
                          );
                        },
                      ),
                      quickNavigationCard(
                        title: 'Price Trends',
                        subtitle: 'Analyse price history',
                        icon: Icons.show_chart_rounded,
                        onTap: () {
                          widget.onNavigationTap(
                            3,
                          );
                        },
                      ),
                      quickNavigationCard(
                        title: 'Favorites',
                        subtitle: 'View favourites',
                        icon: Icons.favorite_border,
                        onTap: () {
                          widget.onNavigationTap(
                            4,
                          );
                        },
                      ),
                      quickNavigationCard(
                        title: 'Shopping List',
                        subtitle: 'Manage shopping items',
                        icon: Icons.shopping_cart_outlined,
                        onTap: () {
                          widget.onNavigationTap(
                            5,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}