import 'package:flutter/material.dart';
import '../services/database_service.dart';

class ShoppingListPage extends StatefulWidget {
  final VoidCallback? onBrowseFood;

  const ShoppingListPage({
    super.key,
    this.onBrowseFood,
  });

  @override
  State<ShoppingListPage> createState() =>
      ShoppingListPageState();
}

class ShoppingListPageState
    extends State<ShoppingListPage> {
  static const Color backgroundColor = Color(0xFFF8F6F3);
  static const Color cardColor = Colors.white;
  static const Color accentColor = Color(0xFF4B2C24);
  static const Color lightAccent = Color(0xFFF3E7E1);
  static const Color textColor = Color(0xFF17171C);
  static const Color secondaryTextColor = Color(0xFF68707C);
  static const Color borderColor = Color(0xFFE7E4E0);
  static const Color softGrey = Color(0xFFF4F3F1);
  static const Color buttonGrey = Color(0xFFF0EFED);
  static const Color dangerColor = Color(0xFFE54242);
  static const Color dangerBackground = Color(0xFFFFEEEE);

  final DatabaseService databaseService = DatabaseService();

  bool isLoading = true;
  int? updatingId;

  List<Map<String, dynamic>>shoppingItems = [];

  @override
  void initState() {
    super.initState();
    loadShoppingList();
  }

  Future<void> loadShoppingList() async {
    setState(() {
      isLoading = true;
    });

    try {
      final localData =
      await databaseService
          .getShoppingList();

      setState(() {
        shoppingItems =
        List<Map<String, dynamic>>.from(
          localData,
        );

        isLoading = false;
      });

      try {
        await databaseService
            .refreshShoppingListFromServer();

        final refreshedData =
        await databaseService
            .getShoppingList();

        setState(() {
          shoppingItems =
          List<Map<String, dynamic>>.from(
            refreshedData,
          );
        });
      } catch (e) {
        if (shoppingItems.isNotEmpty) {
          showMessage(
            'Offline mode. Showing saved shopping list.',
          );
        }
      }
    } catch (e) {
      debugPrint(
        'Shopping list error: $e',
      );

      showMessage(
        'Unable to update shopping list.',
      );
    }
  }

  Future<void> increaseQuantity(
      Map<String, dynamic> item,
      ) async {
    if (updatingId != null) {
      return;
    }

    final id = int.tryParse(
      item['id'].toString(),
    );

    if (id == null) {
      return;
    }

    final currentQuantity =
        int.tryParse(
          item['quantity'].toString(),
        ) ??
            1;

    final newQuantity =
        currentQuantity + 1;

    setState(() {
      updatingId = id;
    });

    try {
      await databaseService
          .updateShoppingListQuantity(
        id,
        newQuantity,
      );

      setState(() {
        item['quantity'] =
            newQuantity;
      });
    } catch (e) {
      showMessage(
        'Unable to update quantity.',
      );
    } finally {
      setState(() {
        updatingId = null;
      });
    }
  }

  Future<void> decreaseQuantity(
      Map<String, dynamic> item,
      ) async {
    if (updatingId != null) {
      return;
    }

    final id = int.tryParse(
      item['id'].toString(),
    );

    if (id == null) {
      return;
    }

    final currentQuantity =
        int.tryParse(
          item['quantity'].toString(),
        ) ??
            1;

    if (currentQuantity <= 1) {
      return;
    }

    final newQuantity =
        currentQuantity - 1;

    setState(() {
      updatingId = id;
    });

    try {
      await databaseService
          .updateShoppingListQuantity(
        id,
        newQuantity,
      );

      setState(() {
        item['quantity'] =
            newQuantity;
      });
    } catch (e) {
      showMessage(
        'Unable to update quantity.',
      );
    } finally {
      setState(() {
        updatingId = null;
      });
    }
  }

  Future<void> toggleBought(
      Map<String, dynamic> item,
      ) async {
    if (updatingId != null) {
      return;
    }

    final id = int.tryParse(
      item['id'].toString(),
    );

    if (id == null) {
      return;
    }

    final currentValue =
        item['is_bought'] == true;

    final newValue =
    !currentValue;

    setState(() {
      updatingId = id;
    });

    try {
      await databaseService
          .updateShoppingListBought(
        id,
        newValue,
      );

      setState(() {
        item['is_bought'] =
            newValue;
      });
    } catch (e) {
      showMessage(
        'Unable to update item.',
      );
    } finally {
      setState(() {
        updatingId = null;
      });
    }
  }

  Future<void> removeItem(
      Map<String, dynamic> item,
      ) async {
    if (updatingId != null) {
      return;
    }

    final id = int.tryParse(
      item['id'].toString(),
    );

    if (id == null) {
      return;
    }

    setState(() {
      updatingId = id;
    });

    try {
      await databaseService
          .removeShoppingListItem(
        id,
      );

      setState(() {
        shoppingItems.remove(
          item,
        );
      });

      showMessage(
        'Item removed.',
      );
    } catch (e) {
      showMessage(
        'Unable to remove item.',
      );
    } finally {
      setState(() {
        updatingId = null;
      });
    }
  }

  Future<void> clearBoughtItems() async {
    try {
      await databaseService
          .clearBoughtShoppingItems();

      setState(() {
        shoppingItems.removeWhere(
              (item) =>
          item['is_bought'] == true,
        );
      });

      showMessage(
        'Bought items cleared.',
      );
    } catch (e) {
      showMessage(
        'Unable to clear bought items.',
      );
    }
  }

  Future<void> clearAllItems() async {
    if (shoppingItems.isEmpty) {
      return;
    }

    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
          Colors.white,
          surfaceTintColor:
          Colors.white,
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              22,
            ),
          ),
          title:
          const Text(
            'Clear Shopping List?',
            style: TextStyle(
              color: textColor,
              fontWeight:
              FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content:
          const Text(
            'All items will be removed from your shopping list.',
            style: TextStyle(
              color:
              secondaryTextColor,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
              const Text(
                'Cancel',
                style: TextStyle(
                  color:
                  secondaryTextColor,
                ),
              ),
            ),
            FilledButton(
              style:
              FilledButton.styleFrom(
                backgroundColor:
                dangerColor,
                foregroundColor:
                Colors.white,
              ),
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child:
              const Text(
                'Clear All',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await databaseService
          .clearShoppingList();

      setState(() {
        shoppingItems.clear();
      });

      showMessage(
        'Shopping list cleared.',
      );
    } catch (e) {
      showMessage(
        'Unable to clear shopping list.',
      );
    }
  }

  double getEstimatedTotal() {
    double total = 0;

    for (final item in shoppingItems) {
      final price =
          double.tryParse(
            item['price'].toString(),
          ) ??
              0;

      final quantity =
          int.tryParse(
            item['quantity'].toString(),
          ) ??
              1;

      total += price * quantity;
    }

    return total;
  }

  int getTotalQuantity() {
    int total = 0;

    for (final item in shoppingItems) {
      total += int.tryParse(
        item['quantity'].toString(),
      ) ??
          1;
    }

    return total;
  }

  int getBoughtCount() {
    return shoppingItems
        .where(
          (item) =>
      item['is_bought'] == true,
    )
        .length;
  }

  void showMessage(
      String message,
      ) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        backgroundColor: accentColor,
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(
          seconds: 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            12,
          ),
        ),
      ),
    );
  }

  Widget buildQuantityButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    final enabled =
        onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        10,
      ),
      child: Container(
        width: 34,
        height: 34,
        decoration:
        BoxDecoration(
          color: buttonGrey,
          borderRadius: BorderRadius.circular(
            10,
          ),
          border: Border.all(
            color: borderColor,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? const Color(
            0xFF555555,
          )
              : const Color(
            0xFFC8C8C8,
          ),
        ),
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

  Widget buildShoppingCard(
      Map<String, dynamic> item,
      ) {
    final quantity =
        int.tryParse(
          item['quantity'].toString(),
        ) ??
            1;

    final price =
        double.tryParse(
          item['price'].toString(),
        ) ??
            0;

    final isBought =
        item['is_bought'] == true;

    final id = int.tryParse(
      item['id'].toString(),
    );

    final isUpdating =
        updatingId == id;

    final estimated =
        price * quantity;

    final premise =
        item['premise']
            ?.toString() ??
            '';

    final district =
        item['district']
            ?.toString() ??
            '';

    final state =
        item['state']
            ?.toString() ??
            '';

    final date =
        item['date']
            ?.toString() ??
            '';

    return AnimatedOpacity(
      duration: const Duration(
        milliseconds: 200,
      ),
      opacity: isBought ? 0.58 : 1,
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 12,
        ),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(
            20,
          ),
          border: Border.all(
            color: borderColor,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.035,
              ),
              blurRadius: 14,
              offset: const Offset(
                0,
                5,
              ),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(
            14,
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets
                        .only(
                      top: 5,
                    ),
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: Checkbox(
                        value: isBought,
                        activeColor: accentColor,
                        checkColor: Colors.white,
                        side: const BorderSide(
                          color: Color(
                            0xFF969696,
                          ),
                          width: 1.4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius
                              .circular(
                            5,
                          ),
                        ),
                        onChanged: isUpdating
                            ? null
                            : (value) {
                          toggleBought(
                            item,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 9,
                  ),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: lightAccent,
                      borderRadius: BorderRadius.circular(
                        15,
                      ),
                    ),
                    child: Icon(
                      getFoodIcon(
                        item['category']?.toString(),
                      ),
                      color: accentColor,
                      size: 25,
                    ),
                  ),
                  const SizedBox(
                    width: 11,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['item']?.toString() ??
                              'Unknown Item',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            color: isBought
                                ? secondaryTextColor
                                : textColor,
                            decoration: isBought
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Row(
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: softGrey,
                                  borderRadius: BorderRadius.circular(
                                    16,
                                  ),
                                ),
                                child: Text(
                                  item['category']?.toString() ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(
                                      0xFF5B5B5B,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 6,
                            ),
                            Text(
                              '• ${item['unit'] ?? ''}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: secondaryTextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.storefront_outlined,
                              size: 14,
                              color: accentColor,
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Expanded(
                              child: Text(
                                premise,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  height: 1.25,
                                  fontWeight: FontWeight.w700,
                                  color: Color(
                                    0xFF45464A,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: secondaryTextColor,
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Expanded(
                              child: Text(
                                '$district, $state',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: secondaryTextColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (date.isNotEmpty) ...[
                          const SizedBox(
                            height: 5,
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_month_outlined,
                                size: 14,
                                color: secondaryTextColor,
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              Flexible(
                                child: Text(
                                  'Updated: $date',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: secondaryTextColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  SizedBox(
                    width: 86,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (isUpdating)
                          const SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: accentColor,
                            ),
                          )
                        else
                          InkWell(
                            borderRadius: BorderRadius.circular(
                              30,
                            ),
                            onTap: () {
                              removeItem(
                                item,
                              );
                            },
                            child:
                            const Padding(
                              padding: EdgeInsets.all(
                                2,
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                color: dangerColor,
                                size: 20,
                              ),
                            ),
                          ),
                        const SizedBox(
                          height: 10,
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 9,
                          ),
                          decoration:
                          BoxDecoration(
                            color: const Color(
                              0xFFF8F2EE,
                            ),
                            borderRadius: BorderRadius
                                .circular(
                              13,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child:
                                Text(
                                  price > 0
                                      ? 'RM ${price.toStringAsFixed(2)}'
                                      : 'N/A',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 2,
                              ),
                              Text(
                                'per ${item['unit'] ?? ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: secondaryTextColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 13,
              ),
              const Divider(
                height: 1,
                color: borderColor,
              ),
              const SizedBox(
                height: 11,
              ),
              Row(
                children: [
                  const Text(
                    'Quantity',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  buildQuantityButton(
                    icon: Icons.remove,
                    onTap:
                    isUpdating ||
                        quantity <=
                            1
                        ? null
                        : () {
                      decreaseQuantity(
                        item,
                      );
                    },
                  ),
                  SizedBox(
                    width: 36,
                    child: Center(
                      child: Text(
                        quantity.toString(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                  buildQuantityButton(
                    icon: Icons.add,
                    onTap:
                    isUpdating
                        ? null
                        : () {
                      increaseQuantity(
                        item,
                      );
                    },
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Subtotal',
                        style: TextStyle(
                          fontSize: 11,
                          color: secondaryTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(
                        height: 2,
                      ),
                      Text(
                        price > 0
                            ? 'RM ${estimated.toStringAsFixed(2)}'
                            : 'N/A',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildEmptyList() {
    return RefreshIndicator(
      color: accentColor,
      onRefresh: loadShoppingList,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(
                context,
              ).size.height *
                  0.16,
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                Container(
                  width: 74,
                  height: 74,
                  decoration: const BoxDecoration(
                    color: lightAccent,
                    shape: BoxShape.circle,
                  ),
                  child:
                  const Icon(
                    Icons.shopping_cart_outlined,
                    color: accentColor,
                    size: 34,
                  ),
                ),
                const SizedBox(
                  height: 17,
                ),
                const Text(
                  'Your list is empty',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(
                  height: 7,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 38,
                  ),
                  child: Text(
                    'Add items from Search or Food Details to start your shopping list',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.45,
                      color: secondaryTextColor,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 21,
                ),
                SizedBox(
                  height: 43,
                  child: FilledButton.icon(
                    onPressed: widget.onBrowseFood,
                    icon: const Icon(
                      Icons.search_rounded,
                      size: 17,
                    ),
                    label: const Text(
                      'Browse Food Items',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget summaryInfoBox({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        height: 62,
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            12,
          ),
          border: Border.all(
            color: borderColor,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: accentColor,
              size: 20,
            ),
            const SizedBox(
              width: 8,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(
                    height: 2,
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: secondaryTextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
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

  Widget buildSummary() {
    final estimatedTotal = getEstimatedTotal();

    return Container(
      margin: const EdgeInsets.fromLTRB(
        14,
        0,
        14,
        10,
      ),
      padding: const EdgeInsets.all(
        13,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFFFBF7F3,
        ),
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.05,
            ),
            blurRadius: 14,
            offset: const Offset(
              0,
              4,
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: lightAccent,
                  borderRadius: BorderRadius.circular(
                    11,
                  ),
                ),
                child: const Icon(
                  Icons.calculate_outlined,
                  color: accentColor,
                  size: 21,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estimated Total',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                      '${shoppingItems.length} item(s) • ${getTotalQuantity()} quantity',
                      style: const TextStyle(
                        fontSize: 13,
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'RM ${estimatedTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                  Text(
                    '${getBoughtCount()} of ${shoppingItems.length} bought',
                    style: const TextStyle(
                      fontSize: 12,
                      color: secondaryTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(
            height: 11,
          ),
          Row(
            children: [
              summaryInfoBox(
                icon: Icons.shopping_bag_outlined,
                value: shoppingItems.length.toString(),
                label: 'Item(s)',
              ),
              const SizedBox(
                width: 7,
              ),
              summaryInfoBox(
                icon: Icons.inventory_2_outlined,
                value: getTotalQuantity().toString(),
                label: 'Quantity',
              ),
              const SizedBox(
                width: 7,
              ),
              summaryInfoBox(
                icon: Icons.check_circle_outline,
                value: getBoughtCount().toString(),
                label: 'Bought',
              ),
            ],
          ),
          const SizedBox(
            height: 8,
          ),
          Row(
            children: [
              if (shoppingItems.any(
                    (item) =>
                item['is_bought'] == true,
              ))
                TextButton.icon(
                  onPressed: clearBoughtItems,
                  icon: const Icon(
                    Icons.check_circle_outline,
                    size: 18,
                  ),
                  label: const Text(
                    'Clear Bought',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: accentColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                    ),
                  ),
                ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: dangerBackground,
                  borderRadius: BorderRadius.circular(
                    11,
                  ),
                ),
                child: TextButton.icon(
                  onPressed: clearAllItems,
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                  ),
                  label: const Text(
                    'Clear All',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: dangerColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
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

  Widget buildHeader() {
    final bought =
    getBoughtCount();

    final total = shoppingItems.length;

    final progress =
    total == 0 ? 0.0 : bought / total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12,
      ),
      decoration:
      const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: borderColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration:
            BoxDecoration(
              color: lightAccent,
              borderRadius: BorderRadius.circular(
                13,
              ),
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              color: accentColor,
              size: 23,
            ),
          ),
          const SizedBox(
            width: 11,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Shopping List',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  shoppingItems.isEmpty
                      ? 'Plan your shopping, buy smarter'
                      : '${shoppingItems.length} item(s) • ${getTotalQuantity()} total quantity',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: secondaryTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (shoppingItems.isNotEmpty) ...[
            const SizedBox(
              width: 8,
            ),
            Container(
              width: 91,
              height: 44,
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
              ),
              decoration: BoxDecoration(
                color: softGrey,
                borderRadius: BorderRadius.circular(
                  13,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 27,
                    height: 27,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 4,
                      backgroundColor: const Color(
                        0xFFE0DDD8,
                      ),
                      valueColor: const AlwaysStoppedAnimation<
                          Color>(
                        accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 6,
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$bought/$total',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const Text(
                          'Bought',
                          style: TextStyle(
                            fontSize: 11,
                            color: secondaryTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 7,
            ),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  12,
                ),
                border: Border.all(
                  color: borderColor,
                ),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                tooltip: 'Refresh',
                onPressed: loadShoppingList,
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: accentColor,
                  size: 21,
                ),
              ),
            ),
          ],
        ],
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
            buildHeader(),
            Expanded(
              child: isLoading ? const Center(
                child: CircularProgressIndicator(
                  color: accentColor,
                ),
              )
                  : shoppingItems.isEmpty ? buildEmptyList() : RefreshIndicator(
                color: accentColor,
                onRefresh: loadShoppingList,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        14,
                        14,
                        14,
                        14,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                              (
                              context,
                              index,
                              ) {
                            return buildShoppingCard(
                              shoppingItems[
                              index],
                            );
                          },
                          childCount: shoppingItems.length,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(
                        height: 5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!isLoading &&
                shoppingItems.isNotEmpty)
              buildSummary(),
          ],
        ),
      ),
    );
  }
}