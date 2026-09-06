import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'food_details_page.dart';

class SavedPage extends StatefulWidget {
  final int initialTab;

  const SavedPage({
    super.key,
    this.initialTab = 0,
  });

  @override
  State<SavedPage> createState() => SavedPageState();
}

class SavedPageState extends State<SavedPage> {
  static const Color primaryGreen = Color(0xFF176B52);
  static const Color darkGreen = Color(0xFF0F513D);
  static const Color backgroundColor = Color(0xFFF6F8F5);
  static const Color lightGreen = Color(0xFFEAF4EF);
  static const Color textColor = Color(0xFF1F2924);

  final DatabaseService databaseService = DatabaseService();

  bool isLoading = true;
  bool priceAlertsEnabled = true;

  double alertThreshold = 5;

  late int selectedTab;

  List<Map<String, dynamic>> savedItems = [];
  List<Map<String, dynamic>> notifications = [];

  @override
  void initState() {
    super.initState();
    selectedTab = widget.initialTab;
    loadSavedItems();
  }

  void openNotifications() {
    setState(() {
      selectedTab = 1;
      generateNotifications();
    });
  }

  double getPriceDifference(
      Map<String, dynamic> item,
      ) {
    final latestPrice = (item['latest_price'] as num?)?.toDouble() ?? 0;

    final previousPrice = (item['previous_price'] as num?)?.toDouble() ?? 0;

    if (previousPrice <= 0) {
      return 0;
    }

    return latestPrice - previousPrice;
  }

  void generateNotifications() {
    final List<Map<String, dynamic>> generatedNotifications = [];

    if (!priceAlertsEnabled) {
      notifications = [];
      return;
    }

    for (final item in savedItems) {
      final alertEnabled = item['alert_enabled'] == true;
      final changePercentage = (item['change_percentage'] as num?)?.toDouble() ?? 0;
      final previousPrice = (item['previous_price'] as num?)?.toDouble() ?? 0;

      if (alertEnabled && previousPrice > 0 && changePercentage.abs() >= alertThreshold) {
        generatedNotifications.add(item);
      }
    }

    generatedNotifications.sort(
          (a, b) {
        final differenceA = getPriceDifference(a).abs();
        final differenceB = getPriceDifference(b).abs();
        return differenceB.compareTo(
          differenceA,
        );
      },
    );

    notifications = generatedNotifications;
  }

  Future<void> loadSavedItems({
    bool showLoading = true,
  }) async {
    try {
      final user = databaseService.getCurrentUser();

      if (user == null) {
        setState(() {
          savedItems = [];
          notifications = [];
          isLoading = false;
        });

        return;
      }

      if (showLoading) {
        setState(() {
          isLoading = true;
        });
      }

      final profileData = await databaseService.getSavedPageProfile();

      bool newPriceAlertsEnabled = true;
      double newAlertThreshold = 5;

      if (profileData != null) {
        newPriceAlertsEnabled = profileData['price_alerts'] == true;

        newAlertThreshold = double.tryParse(
              profileData['alert_threshold'].toString(),
            ) ?? 5;
      }

      final savedData = await databaseService.getUserSavedItems();

      if (savedData.isEmpty) {
        setState(() {
          priceAlertsEnabled = newPriceAlertsEnabled;
          alertThreshold = newAlertThreshold;

          savedItems = [];
          notifications = [];
          isLoading = false;
        });

        return;
      }

      final itemCodes = savedData
          .map(
            (row) => int.tryParse(
          row['item_code'].toString(),
        ),
      )
          .whereType<int>()
          .toSet()
          .toList();

      final foodData = await databaseService.getSavedFoodItems(
        itemCodes,
      );

      final priceData = await databaseService.getSavedPriceChanges(
        itemCodes,
      );

      final Map<int, Map<String, dynamic>>
      foodMap = {};

      for (final food in foodData) {
        final code = int.tryParse(
          food['item_code'].toString(),
        );

        if (code != null) {
          foodMap[code] = food;
        }
      }

      final Map<int, Map<String, dynamic>>priceMap = {};

      for (final price in priceData) {
        final code = int.tryParse(
          price['item_code'].toString(),
        );

        if (code != null) {
          priceMap[code] = price;
        }
      }

      final List<Map<String, dynamic>>combinedSavedItems = [];

      for (final saved in savedData) {
        final itemCode = int.tryParse(
          saved['item_code'].toString(),
        );

        if (itemCode == null) {
          continue;
        }

        final food = foodMap[itemCode];

        if (food == null) {
          continue;
        }

        final priceInfo = priceMap[itemCode];

        final latestPrice = double.tryParse(
          priceInfo?['latest_price']?.toString() ?? '0',
        ) ?? 0;

        final previousPrice = double.tryParse(
          priceInfo?['previous_price']?.toString() ?? '0',
        ) ?? 0;

        final changePercentage = double.tryParse(
          priceInfo?['change_percentage']
              ?.toString() ?? '0',
        ) ?? 0;

        combinedSavedItems.add({
          'saved_id': saved['id'],
          'item_code': itemCode,
          'item': food['item'] ?? 'Unknown Item',
          'category': food['item_category'] ?? '',
          'unit': food['unit'] ?? '',
          'alert_enabled': saved['alert_enabled'] ?? true,
          'created_at': saved['created_at'],
          'latest_price': latestPrice,
          'previous_price': previousPrice,
          'change_percentage': changePercentage,
          'latest_date': priceInfo?['latest_date'] ?? '',
          'previous_date': priceInfo?['previous_date'] ?? '',
        });
      }

      final List<Map<String, dynamic>>generatedNotifications = [];

      if (newPriceAlertsEnabled) {
        for (final item
        in combinedSavedItems) {
          final alertEnabled = item['alert_enabled'] == true;
          final previousPrice = (item['previous_price'] as num).toDouble();
          final changePercentage = (item['change_percentage'] as num).toDouble();

          if (alertEnabled && previousPrice > 0 && changePercentage.abs() >= newAlertThreshold) {
            generatedNotifications.add(
              item,
            );
          }
        }
      }

      generatedNotifications.sort(
            (a, b) {
          final differenceA = getPriceDifference(a).abs();
          final differenceB = getPriceDifference(b).abs();

          return differenceB.compareTo(
            differenceA,
          );
        },
      );

      setState(() {
        priceAlertsEnabled = newPriceAlertsEnabled;
        alertThreshold = newAlertThreshold;
        savedItems = combinedSavedItems;
        notifications = generatedNotifications;

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      showMessage(
        'Unable to load favourites.',
      );
    }
  }

  Future<void> removeSavedItem(
      int savedId,
      ) async {
    try {
      await databaseService.removeSavedItemById(
        savedId,
      );

      setState(() {
        savedItems.removeWhere(
              (item) => item['saved_id'] == savedId,
        );

        generateNotifications();
      });

      showMessage(
        'Removed from favourites.',
      );
    } catch (e) {
      showMessage(
        'Unable to remove item.',
      );
    }
  }

  Future<void> toggleAlert(
      Map<String, dynamic> item,
      ) async {
    final currentValue = item['alert_enabled'] == true;
    final newValue = !currentValue;

    try {
      await databaseService.updateSavedFoodAlert(
        savedId: item['saved_id'],
        value: newValue,
      );

      setState(() {
        item['alert_enabled'] = newValue;

        generateNotifications();
      });

      showMessage(
        newValue
            ? 'Price alert turned on.'
            : 'Price alert turned off.',
      );
    } catch (e) {
      showMessage(
        'Unable to update price alert.',
      );
    }
  }

  void openFoodDetails(
      Map<String, dynamic> item,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoodDetailsPage(
              itemCode: item['item_code'],
              itemName: item['item'],
              unit: item['unit'],
            ),
      ),
    );
  }

  Widget buildTabButton({
    required String title,
    required int index,
  }) {
    final selected = selectedTab == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            selectedTab = index;
            generateNotifications();
          });
        },
        borderRadius: BorderRadius.circular(
          12,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: selected
                ? primaryGreen
                : Colors.transparent,
            borderRadius:
            BorderRadius.circular(
              12,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : Colors.black54,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildFavouriteCard(
      Map<String, dynamic> item,
      ) {
    final price = (item['latest_price'] as num).toDouble();
    final previousPrice = (item['previous_price'] as num).toDouble();
    final priceDifference = price - previousPrice;
    final alertEnabled = item['alert_enabled'] == true;
    final isIncrease = previousPrice > 0 && priceDifference > 0;
    final isDecrease = previousPrice > 0 && priceDifference < 0;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: const Color(
            0xFFE3E9E6,
          ),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              openFoodDetails(
                item,
              );
            },
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(
                18,
              ),
              topRight: Radius.circular(
                18,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(
                15,
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: lightGreen,
                      borderRadius: BorderRadius.circular(
                        15,
                      ),
                    ),
                    child: Icon(
                      getFoodIcon(
                        item['category']?.toString(),
                      ),
                      color: primaryGreen,
                      size: 28,
                    ),
                  ),

                  const SizedBox(
                    width: 13,
                  ),

                  Expanded(
                    child:
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['item']
                              .toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.25,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),

                        const SizedBox(
                          height: 6,
                        ),

                        Text(
                          '${item['category']} • ${item['unit']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        if (previousPrice > 0)
                          Row(
                            children: [
                              Icon(
                                isIncrease
                                    ? Icons.trending_up
                                    : isDecrease
                                    ? Icons.trending_down
                                    : Icons.trending_flat,
                                size: 17,
                                color: isIncrease
                                    ? Colors.red
                                    : isDecrease
                                    ? primaryGreen
                                    : Colors.grey,
                              ),

                              const SizedBox(
                                width: 5,
                              ),

                              Flexible(
                                child: Text(
                                  isIncrease
                                      ? 'Up RM ${priceDifference.abs().toStringAsFixed(2)}'
                                      : isDecrease
                                      ? 'Down RM ${priceDifference.abs().toStringAsFixed(2)}'
                                      : 'No price change',
                                  style: TextStyle(
                                    color: isIncrease
                                        ? Colors.red
                                        : isDecrease
                                        ? primaryGreen
                                        : Colors.grey,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
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
                        price > 0 ? 'RM ${price.toStringAsFixed(2)}' : '-',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      const Text(
                        'Latest Avg',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      if (previousPrice > 0) ...[
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          'Was RM ${previousPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          const Divider(
            height: 1,
          ),

          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    toggleAlert(
                      item,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 13,
                    ),
                    decoration: const BoxDecoration(
                      color: lightGreen,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(
                          18,
                        ),
                      ),
                    ),
                    child:
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          alertEnabled
                              ? Icons.notifications_active_outlined
                              : Icons.notifications_off_outlined,
                          size: 18,
                          color: primaryGreen,
                        ),

                        const SizedBox(
                          width: 6,
                        ),

                        Text(
                          alertEnabled
                              ? 'Alert On'
                              : 'Alert Off',
                          style:
                          const TextStyle(
                            color: primaryGreen,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Expanded(
                child: InkWell(
                  onTap: () {
                    removeSavedItem(
                      item['saved_id'],
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 13,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite,
                          size: 18,
                          color: Colors.red,
                        ),

                        SizedBox(
                          width: 6,
                        ),

                        Text(
                          'Remove',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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

  Widget buildNotificationCard(
      Map<String, dynamic> item,
      ) {
    final previousPrice = (item['previous_price'] as num).toDouble();
    final latestPrice = (item['latest_price'] as num).toDouble();
    final priceDifference = latestPrice - previousPrice;
    final isIncrease = priceDifference > 0;
    final isDecrease = priceDifference < 0;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: const Color(
            0xFFE3E9E6,
          ),
        ),
      ),
      child: InkWell(
        onTap: () {
          openFoodDetails(
            item,
          );
        },
        borderRadius: BorderRadius.circular(
          18,
        ),
        child:
        Padding(
          padding: const EdgeInsets.all(
            15,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isIncrease ? const Color(
                    0xFFFFEEEE,
                  )
                      : isDecrease
                      ? lightGreen
                      : const Color(
                    0xFFF1F3F2,
                  ),
                  shape: BoxShape.circle,
                ),
                child:
                Icon(
                  isIncrease
                      ? Icons.trending_up
                      : isDecrease
                      ? Icons.trending_down
                      : Icons.trending_flat,
                  color: isIncrease
                      ? Colors.red
                      : isDecrease
                      ? primaryGreen
                      : Colors.grey,
                  size: 23,
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
                      item['item'].toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    Text(
                      isIncrease
                          ? 'Price increased by RM ${priceDifference.abs().toStringAsFixed(2)}'
                          : isDecrease
                          ? 'Price decreased by RM ${priceDifference.abs().toStringAsFixed(2)}'
                          : 'No price change',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isIncrease
                            ? Colors.red
                            : isDecrease
                            ? primaryGreen
                            : Colors.grey,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    Text(
                      'RM ${previousPrice.toStringAsFixed(2)} → RM ${latestPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      'Latest: ${item['latest_date']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade500,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildEmptyFavorites() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            25,
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 55,
            horizontal: 20,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(
                0xFFE3E9E6,
              ),
            ),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite_border,
                size: 50,
                color:
                Colors.black26,
              ),

              SizedBox(
                height: 12,
              ),

              Text(
                'No favourites yet',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),

              SizedBox(
                height: 5,
              ),

              Text(
                'Tap the heart icon on the Search page to add food to your favourites.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: Colors.black54,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildFavoritesContent() {
    if (savedItems.isEmpty) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          buildEmptyFavorites(),
        ],
      );
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            25,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                return buildFavouriteCard(
                  savedItems[index],
                );
              },
              childCount: savedItems.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildNotificationsContent() {
    if (!priceAlertsEnabled) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Container(
                width:
                double.infinity,
                margin: const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  25,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 45,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    18,
                  ),
                  border: Border.all(
                    color: const Color(
                      0xFFE3E9E6,
                    ),
                  ),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 48,
                      color:
                      Colors.black26,
                    ),

                    SizedBox(
                      height: 10,
                    ),

                    Text(
                      'Price alerts are turned off',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    SizedBox(
                      height: 4,
                    ),

                    Text(
                      'Turn on Price Alerts in Profile & Settings to receive price change notifications.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (notifications.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              12,
            ),
            sliver: SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 45,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    18,
                  ),
                  border: Border.all(
                    color: const Color(
                      0xFFE3E9E6,
                    ),
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 48,
                      color: Colors.black26,
                    ),

                    SizedBox(
                      height: 10,
                    ),

                    Text(
                      'No price alerts',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    SizedBox(
                      height: 4,
                    ),

                    Text(
                      'There are no significant price changes for your favourite food items.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.45,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        if (notifications.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              4,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  return buildNotificationCard(
                    notifications[index],
                  );
                },
                childCount: notifications.length,
              ),
            ),
          ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            25,
          ),
          sliver: SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(
                16,
              ),
              decoration: BoxDecoration(
                color: const Color(
                  0xFFFFF6E8,
                ),
                borderRadius: BorderRadius.circular(
                  16,
                ),
                border: Border.all(
                  color:
                  Colors.orange,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.notifications_active_outlined,
                    size: 22,
                    color: Colors.orange,
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Price Alerts Active',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),

                        const SizedBox(
                          height: 6,
                        ),

                        Text(
                          'Alerts are triggered when the price changes by ${alertThreshold.toStringAsFixed(0)}% or more. The actual increase or decrease is shown in RM.',
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void showMessage(
      String message,
      ) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
        duration: const Duration(
          seconds: 2,
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
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.fromLTRB(
                18,
                16,
                18,
                15,
              ),
              decoration: const BoxDecoration(
                gradient:
                LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryGreen,
                    darkGreen,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 23,
                      ),

                      SizedBox(
                        width: 7,
                      ),

                      Text(
                        'Favorites',
                        style:
                        TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    savedItems.length == 1 ? '1 favorite item' : '${savedItems.length} favorite items',
                    style: const TextStyle(
                      color: Color(
                        0xFFDCEDE6,
                      ),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  Container(
                    padding: const EdgeInsets.all(
                      4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(
                        14,
                      ),
                    ),
                    child: Row(
                      children: [
                        buildTabButton(
                          title: 'Favorites',
                          index: 0,
                        ),

                        buildTabButton(
                          title: 'Notifications',
                          index: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                color: primaryGreen,
                onRefresh: loadSavedItems,
                child: isLoading ? CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: primaryGreen,
                        ),
                      ),
                    ),
                  ],
                )
                    : selectedTab == 0
                    ? buildFavoritesContent()
                    : buildNotificationsContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}