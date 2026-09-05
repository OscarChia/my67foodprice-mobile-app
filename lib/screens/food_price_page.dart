import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'food_details_page.dart';

class FoodPricePage extends StatefulWidget {
  final String? initialCategory;

  const FoodPricePage({
    super.key,
    this.initialCategory,
  });

  @override
  State<FoodPricePage> createState() => FoodPricePageState();
}

class FoodPricePageState extends State<FoodPricePage> {
  static const Color primaryGreen = Color(0xFF176B52);
  static const Color darkGreen = Color(0xFF0F513D);
  static const Color backgroundColor = Color(0xFFF6F8F5);
  static const Color lightGreen = Color(0xFFEAF4EF);
  static const Color textColor = Color(0xFF1F2924);
  static const Color secondaryText = Color(0xFF6B756F);

  final DatabaseService databaseService = DatabaseService();

  List<Map<String, dynamic>> foodPriceList = [];
  List<Map<String, dynamic>> allFoodItems = [];
  Set<int> savedItemCodes = {};
  bool isLoading = true;
  bool showFilters = false;
  int currentPage = 0;
  int? savingItemCode;
  Set<String> shoppingItemKeys = {};
  String? addingCartItemKey;

  final searchController = TextEditingController();
  final int itemsPerPage = 20;

  String selectedCategory = 'All Categories';
  String selectedState = 'All States';
  String selectedSort = 'Default';

  String getShoppingKey(
      dynamic itemCode,
      dynamic premiseCode,
      ) {
    return [
      itemCode,
      premiseCode,
    ].join('_');
  }

  final List<String> categories = [
    'All Categories',
    'AYAM',
    'BAHAN LAUT',
    'BAHAN-BAHAN MINUMAN',
    'BAWANG',
    'BERAS',
    'BIHUN',
    'BUAH-BUAHAN',
    'CILI KERING',
    'DAGING',
    'ESEN DAN RAGI',
    'GULA',
    'HASIL LAUT KERING',
    'IKAN DALAM TIN',
    'IKAN DARAT',
    'KACANG',
    'KELAPA',
    'KICAP DAN SOS',
    'KRIMER DAN SUSU TEPUNG',
    'MAKANAN BAYI',
    'MEE/KUETIAU',
    'MENTEGA',
    'MI SEGERA',
    'MINYAK DAN LEMAK',
    'REMPAH RATUS (BERBUNGKUS)',
    'REMPAH RATUS (TIDAK BERBUNGKUS)',
    'SANTAN (KOTAK)',
    'SAPUAN (SPREADS)',
    'SAYUR-SAYURAN',
    'SUSU BAYI',
    'TELUR',
    'TEPUNG',
    'TERSEDIA MINUM',
    'UBI KENTANG',
  ];

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

  List<String> states = [
    'All States',
  ];

  final List<String> sortOptions = [
    'Default',
    'Price: Low to High',
    'Price: High to Low',
  ];

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.initialCategory ?? 'All Categories';
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    setState(() {
      isLoading = true;
    });

    try {
      allFoodItems = await databaseService.getFoodItems();

      setState(() {
        foodPriceList = [];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      showMessage(
        'Unable to load food data.',
      );
    }

    loadStates();
    loadSavedItems();
    loadShoppingItems();
  }

  Future<void> loadStates() async {
    try {
      final stateList = await databaseService.getStates();

      setState(() {
        states = stateList;
      });
    } catch (e) {
      setState(() {
        states = [
          'All States',
        ];
      });
    }
  }

  Future<void> loadSavedItems() async {
    try {
      final codes = await databaseService.getSavedItemCodes();

      setState(() {
        savedItemCodes = codes;
      });
    } catch (e) {
      setState(() {
        savedItemCodes = {};
      });
    }
  }

  Future<void> loadShoppingItems() async {
    try {
      final data = await databaseService.getShoppingList();
      final keys = data.map<String?>((row) {
          final itemCode = row['item_code'];
          final premiseCode = row['premise_code'];

          if (itemCode == null || premiseCode == null) {
            return null;
          }

          return getShoppingKey(
            itemCode,
            premiseCode,
          );
        },
      )
          .whereType<String>()
          .toSet();

      setState(() {
        shoppingItemKeys = keys;
      });
    } catch (e) {
      setState(() {
        shoppingItemKeys = {};
      });
    }
  }

  Future<void> refreshSavedItems() async {
    await loadSavedItems();
    await loadShoppingItems();
  }

  void filterByCategory(
      String? category,
      ) {
    setState(() {
      selectedCategory = category ?? 'All Categories';
      selectedState = 'All States';
      selectedSort = 'Default';
      searchController.clear();
    });

    fetchFoodPrices();
  }

  Future<void> toggleSavedItem(
      int itemCode,
      ) async {
    if (savingItemCode != null) {
      return;
    }

    final user = databaseService.getCurrentUser();

    if (user == null) {
      showMessage(
        'Please login first.',
      );
      return;
    }

    final isAlreadySaved =
    savedItemCodes.contains(
      itemCode,
    );

    setState(() {
      savingItemCode = itemCode;
    });

    try {
      if (isAlreadySaved) {
        await databaseService.removeSavedItemByCode(
          itemCode,
        );

        setState(() {
          savedItemCodes.remove(
            itemCode,
          );
        });

        showMessage(
          'Removed from favourites.',
        );
      } else {
        final defaultAlert = await databaseService.getDefaultSavedItemAlert();

        await databaseService.addSavedItem(
          itemCode,
          defaultAlert,
        );

        setState(() {
          savedItemCodes.add(
            itemCode,
          );
        });

        showMessage(
          'Added to favourites.',
        );
      }
    } catch (e) {
      showMessage(
        'Unable to update favourite.',
      );
    } finally {
      setState(() {
        savingItemCode = null;
      });
    }
  }

  Future<void> toggleShoppingItem(
      Map<String, dynamic> food,
      ) async {
    final itemCode = int.tryParse(
      food['item_code'].toString(),
    );

    final premiseCode = food['premise_code'];

    if (itemCode == null || premiseCode == null) {
      return;
    }

    final shoppingKey = getShoppingKey(
      itemCode,
      premiseCode,
    );

    if (addingCartItemKey != null) {
      return;
    }

    final user = databaseService.getCurrentUser();

    if (user == null) {
      showMessage(
        'Please login first.',
      );
      return;
    }

    final isAlreadyAdded = shoppingItemKeys.contains(
      shoppingKey,
    );

    setState(() {
      addingCartItemKey = shoppingKey;
    });

    try {
      if (isAlreadyAdded) {
        await databaseService.removeFromShoppingList(
          itemCode,
          premiseCode,
        );

        setState(() {
          shoppingItemKeys.remove(
            shoppingKey,
          );
        });

        showMessage(
          'Removed from shopping list.',
        );
      } else {
        await databaseService.addToShoppingList(
          itemCode,
          premiseCode,
        );

        setState(() {
          shoppingItemKeys.add(
            shoppingKey,
          );
        });

        showMessage(
          'Added to shopping list.',
        );
      }
    } catch (e) {
      showMessage(
        'Unable to update shopping list.',
      );
    } finally {
      setState(() {
        addingCartItemKey = null;
      });
    }
  }

  Future<void> fetchFoodPrices() async {
    final searchText = searchController.text
        .trim()
        .toLowerCase();

    if (searchText.isEmpty) {
      setState(() {
        foodPriceList = [];
        currentPage = 0;
        isLoading = false;
      });

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      List<Map<String, dynamic>>matchingItems = List<Map<String, dynamic>>.from(
        allFoodItems,
      );

      if (selectedCategory != 'All Categories') {
        matchingItems = matchingItems.where(
                  (item) {
                return item['item_category']?.toString() == selectedCategory;
              },
            ).toList();
      }

      if (searchText.isNotEmpty) {
        matchingItems = matchingItems.where(
                  (item) {
                final itemName = item['item']?.toString().toLowerCase() ?? '';

                return itemName.contains(
                  searchText,
                );
              },
            ).toList();
      }

      if (matchingItems.isEmpty) {
        setState(() {
          foodPriceList = [];
          currentPage = 0;
          isLoading = false;
        });

        return;
      }

      final itemCodes = matchingItems
          .map(
            (item) => item['item_code'],
      )
          .where(
            (code) => code != null,
      )
          .toList();

      List<Map<String, dynamic>>selectedPremises = [];
      List<dynamic> premiseCodes = [];

      if (selectedState != 'All States') {
        selectedPremises = await databaseService.getPremisesByState(
          selectedState,
        );

        if (selectedPremises.isEmpty) {
          setState(() {
            foodPriceList = [];
            currentPage = 0;
            isLoading = false;
          });

          return;
        }

        premiseCodes = selectedPremises.map(
              (premise) => premise['premise_code'],
            )
                .where((code) => code != null,
            )
                .toList();
      }

      final priceData = await databaseService.getFoodPrices(
        itemCodes: itemCodes,
        premiseCodes: selectedState == 'All States' ? null : premiseCodes,
      );

      if (priceData.isEmpty) {
        setState(() {
          foodPriceList = [];
          currentPage = 0;
          isLoading = false;
        });

        return;
      }

      final usedPremiseCodes =
      priceData.map(
            (price) => price['premise_code'],
      )
          .where(
            (code) => code != null,
      )
          .toSet()
          .toList();

      List<Map<String, dynamic>>premiseList;

      if (selectedState == 'All States') {
        premiseList = await databaseService.getPremisesByCodes(
          usedPremiseCodes,
        );
      } else {
        premiseList = selectedPremises;
      }

      final Map<dynamic,
          Map<String, dynamic>>itemMap = {};

      for (final item in matchingItems) {
        itemMap[item['item_code']] = item;
      }

      final Map<dynamic,
          Map<String, dynamic>>
      premiseMap = {};

      for (final premise
      in premiseList) {
        premiseMap[premise['premise_code']] = premise;
      }

      List<Map<String, dynamic>>combinedList = [];

      for (final price in priceData) {
        final item =
        itemMap[
        price['item_code']];

        if (item == null) {
          continue;
        }

        final premise = premiseMap[
        price['premise_code']];

        combinedList.add({
          'date': price['date'],
          'price': price['price'],
          'item_code': price['item_code'],
          'premise_code': price['premise_code'],
          'item': item['item'],
          'unit': item['unit'],
          'category': item['item_category'],
          'premise': premise?['premise'] ?? 'Unknown Premise',
          'state': premise?['state'] ?? '',
          'district': premise?['district'] ?? '',
        });
      }

      sortFoodPrices(
        combinedList,
      );

      setState(() {
        foodPriceList = combinedList;
        currentPage = 0;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      showMessage(
        'Unable to load food prices.',
      );
    }
  }

  void sortFoodPrices(
      List<Map<String, dynamic>> list,
      ) {
    if (selectedSort == 'Price: Low to High') {
      list.sort(
            (a, b) {
          final priceA = double.tryParse(
                a['price'].toString(),) ?? 0;
          final priceB = double.tryParse(
                b['price'].toString(),) ?? 0;

          return priceA.compareTo(
            priceB,
          );
        },
      );
    }

    if (selectedSort == 'Price: High to Low') {
      list.sort(
            (a, b) {
          final priceA = double.tryParse(
                a['price'].toString(),) ?? 0;

          final priceB = double.tryParse(
                b['price'].toString(),) ?? 0;

          return priceB.compareTo(
            priceA,
          );
        },
      );
    }
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

  InputDecoration dropdownDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontSize: 15,
        color: secondaryText,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: Icon(
        icon,
        size: 22,
        color: primaryGreen,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 17,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(
            0xFFE2E8E5,
          ),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(
            0xFFE2E8E5,
          ),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: primaryGreen,
          width: 1.5,
        ),
      ),
    );
  }

  Widget buildFilterArea() {
    return Container(
      margin: const EdgeInsets.only(
        top: 12,
      ),
      padding: const EdgeInsets.all(
        17,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(
            0xFFE2E8E5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.tune,
                size: 22,
                color: primaryGreen,
              ),
              SizedBox(
                width: 8,
              ),
              Text(
                'Filter Food Prices',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 17,
          ),

          DropdownButtonFormField<String>(
            initialValue:
            selectedCategory,
            isExpanded: true,
            menuMaxHeight: 350,
            decoration: dropdownDecoration(
              label: 'Category',
              icon: Icons.category_outlined,
            ),
            items: categories.map(
                  (category) {
                return DropdownMenuItem<
                    String>(
                  value: category,
                  child: Text(
                    category,
                    overflow: TextOverflow.ellipsis,
                    style:
                    const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                );
              },
            ).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedCategory = value;
                  currentPage = 0;
                });

                if (searchController.text.trim().isNotEmpty) {
                  fetchFoodPrices();
                }
              }
            },
          ),

          const SizedBox(
            height: 14,
          ),

          DropdownButtonFormField<String>(
            initialValue: selectedState,
            isExpanded: true,
            menuMaxHeight: 350,
            decoration: dropdownDecoration(
              label: 'State',
              icon: Icons.location_on_outlined,
            ),
            items: states.map(
                  (state) {
                return DropdownMenuItem<String>(
                  value: state,
                  child: Text(
                    state,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                );
              },
            ).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedState = value;
                  currentPage = 0;
                });

                fetchFoodPrices();
              }
            },
          ),

          const SizedBox(
            height: 14,
          ),

          DropdownButtonFormField<String>(
            initialValue: selectedSort,
            isExpanded: true,
            decoration: dropdownDecoration(
              label: 'Sort Price',
              icon: Icons.sort,
            ),
            items: sortOptions.map(
                  (sort) {
                return DropdownMenuItem<String>(
                  value: sort,
                  child: Text(
                    sort,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                );
              },
            ).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedSort = value;

                  sortFoodPrices(
                    foodPriceList,
                  );

                  currentPage = 0;
                });
              }
            },
          ),

          const SizedBox(
            height: 16,
          ),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  selectedCategory = 'All Categories';
                  selectedState = 'All States';
                  selectedSort = 'Default';
                  searchController.clear();
                  foodPriceList = [];
                  currentPage = 0;
                  isLoading = false;
                });
              },
              icon: const Icon(
                Icons.refresh,
                size: 20,
              ),
              label: const Text(
                'Reset Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style:
              OutlinedButton.styleFrom(
                foregroundColor: primaryGreen,
                side: const BorderSide(
                  color: primaryGreen,
                ),
                shape:
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget foodCard(
      Map<String, dynamic> food,
      ) {
    final itemCode = int.tryParse(
      food['item_code'].toString(),
    );

    final isSaved = itemCode != null && savedItemCodes.contains(
              itemCode,
            );

    final isSaving = savingItemCode == itemCode;
    final premiseCode = food['premise_code'];
    final shoppingKey = itemCode != null && premiseCode != null ? getShoppingKey(
      itemCode,
      premiseCode,
    ) : null;

    final isInShoppingList = shoppingKey != null && shoppingItemKeys.contains(
              shoppingKey,
            );

    final isAddingCart = shoppingKey != null && addingCartItemKey == shoppingKey;
    final price = double.tryParse(
          food['price'].toString(),
        ) ?? 0;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 13,
      ),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: const Color(
            0xFFE3E9E6,
          ),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(19),
        onTap: () {
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
        },
        child: Padding(
          padding: const EdgeInsets.all(
            15,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius: BorderRadius.circular(
                    16,
                  ),
                ),
                child: Icon(
                  getFoodIcon(
                    food['category']?.toString(),
                  ),
                  color: primaryGreen,
                  size: 30,
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
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),

                    const SizedBox(
                      height: 7,
                    ),

                    Row(
                      children: [
                        const Icon(
                          Icons.category_outlined,
                          size: 16,
                          color: secondaryText,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Expanded(
                          child: Text(
                            '${food['category']} • ${food['unit']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: secondaryText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    Row(
                      children: [
                        const Icon(
                          Icons.store_outlined,
                          size: 16,
                          color: secondaryText,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Expanded(
                          child: Text(
                            food['premise'].toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: secondaryText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: secondaryText,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Expanded(
                          child: Text(
                            '${food['district']}, ${food['state']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: secondaryText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    Text(
                      'Updated: ${food['date']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: secondaryText,
                        fontWeight: FontWeight.w600,
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'RM ${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: primaryGreen,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    'per ${food['unit']}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: secondaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                width: 10,
              ),

              Container(
                width: 1,
                height: 88,
                color: const Color(
                  0xFFE3E9E6,
                ),
              ),

              const SizedBox(
                width: 7,
              ),

              SizedBox(
                width: 40,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSaving)
                      const SizedBox(
                        width: 36,
                        height: 36,
                        child: Padding(
                          padding: EdgeInsets.all(
                            8,
                          ),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: primaryGreen,
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          onPressed: itemCode == null ? null : () {
                            toggleSavedItem(
                              itemCode,
                            );
                          },
                          icon: Icon(
                            isSaved
                                ? Icons.favorite
                                : Icons.favorite_border,
                          ),
                          color: isSaved
                              ? Colors.red
                              : Colors.grey,
                          iconSize: 24,
                        ),
                      ),

                    const SizedBox(
                      height: 10,
                    ),

                    if (isAddingCart)
                      const SizedBox(
                        width: 36,
                        height: 36,
                        child: Padding(
                          padding: EdgeInsets.all(
                            8,
                          ),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: primaryGreen,
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          onPressed: itemCode == null ? null : () {
                            toggleShoppingItem(
                              food,
                            );
                          },
                          icon: Icon(
                            isInShoppingList
                                ? Icons.check_circle
                                : Icons.shopping_cart_outlined,
                          ),
                          color: isInShoppingList
                              ? primaryGreen
                              : Colors.grey,
                          iconSize: 24,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int get totalPages {
    if (foodPriceList.isEmpty) {
      return 0;
    }

    return (
        foodPriceList.length / itemsPerPage
    ).ceil();
  }

  List<Map<String, dynamic>>
  get paginatedFoodPriceList {
    if (foodPriceList.isEmpty) {
      return [];
    }

    final startIndex = currentPage * itemsPerPage;

    int endIndex = startIndex + itemsPerPage;

    if (endIndex > foodPriceList.length) {
      endIndex = foodPriceList.length;
    }

    return foodPriceList.sublist(
      startIndex,
      endIndex,
    );
  }

  void goToPreviousPage() {
    if (currentPage > 0) {
      setState(() {
        currentPage--;
      });
    }
  }

  void goToNextPage() {
    if (currentPage < totalPages - 1) {
      setState(() {
        currentPage++;
      });
    }
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
              padding: const EdgeInsets.fromLTRB(
                20,
                18,
                20,
                22,
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
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(
                    28,
                  ),
                  bottomRight: Radius.circular(
                    28,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Find Food Prices',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  const Text(
                    'Search and compare food prices across Malaysia',
                    style: TextStyle(
                      color: Color(0xFFDCEDE6,),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(
                    height: 18,
                  ),
                  TextField(
                    controller: searchController,
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(
                      fontSize: 15,
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isEmpty) {
                        setState(() {
                          foodPriceList = [];
                          currentPage = 0;
                          isLoading = false;
                        });

                        return;
                      }

                      fetchFoodPrices();
                    },
                    decoration: InputDecoration(
                      hintText: 'Search food name...',
                      hintStyle: const TextStyle(
                        fontSize: 16,
                        color: secondaryText,
                        fontWeight: FontWeight.w400,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: primaryGreen,
                        size: 23,
                      ),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.all(5),
                        child: SizedBox(
                          width: 44,
                          height: 40,
                          child: IconButton(
                            onPressed: () {
                              if (searchController.text.trim().isEmpty) {
                                setState(() {
                                  foodPriceList = [];
                                  currentPage = 0;
                                  isLoading = false;
                                });

                                return;
                              }

                              fetchFoodPrices();
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: primaryGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  11,
                                ),
                              ),
                            ),
                            icon: const Icon(
                              Icons.search,
                              color: Colors.white,
                              size: 21,
                            ),
                          ),
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      if (value.trim().isEmpty) {
                        setState(() {
                          foodPriceList = [];
                          currentPage = 0;
                          isLoading = false;
                        });
                      } else {
                        setState(() {});
                      }
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      18,
                      17,
                      18,
                      25,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          InkWell(
                            borderRadius: BorderRadius.circular(
                              14,
                            ),
                            onTap: () {
                              setState(() {
                                showFilters = !showFilters;
                              });
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE2E8E5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.tune,
                                    size: 19,
                                    color: primaryGreen,
                                  ),
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  const Text('Filters & Sort',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: textColor,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    showFilters
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    color: primaryGreen,
                                    size: 22,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          if (showFilters)
                            buildFilterArea(),

                          const SizedBox(
                            height: 18,
                          ),

                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Search Results',
                                      style: TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.w800,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 3,
                                    ),
                                    Text(
                                      searchController.text.trim().isEmpty
                                          ? 'Enter a food name to begin searching'
                                          : '${foodPriceList.length} price record(s) found',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: secondaryText,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (selectedState != 'All States')
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: lightGreen,
                                    borderRadius: BorderRadius.circular(
                                      20,
                                    ),
                                  ),
                                  child: Text(
                                    selectedState,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: primaryGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          if (searchController.text.trim().isEmpty)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(
                                top: 55,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 35,
                              ),
                              child: const Column(
                                children: [
                                  CircleAvatar(
                                    radius: 36,
                                    backgroundColor: lightGreen,
                                    child: Icon(
                                      Icons.search_rounded,
                                      size: 34,
                                      color: primaryGreen,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 18,
                                  ),
                                  Text(
                                    'Search for food prices',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w700,
                                      color: textColor,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 7,
                                  ),
                                  Text(
                                    'Please enter a food name above to find\nand compare food prices.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.5,
                                      color: Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (isLoading)
                            const Padding(
                              padding: EdgeInsets.all(
                                45,
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: primaryGreen,
                                ),
                              ),
                            )
                          else if (foodPriceList.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 45,
                                  horizontal: 20,
                                ),
                                decoration:
                                BoxDecoration(
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
                                      Icons.search_off_outlined,
                                      size: 50,
                                      color: Colors.black26,
                                    ),
                                    SizedBox(
                                      height: 12,
                                    ),
                                    Text(
                                      'No food price found',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 5,
                                    ),
                                    Text(
                                      'Try another food name or change the filters.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.black45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                  if (searchController.text.trim().isNotEmpty && !isLoading && foodPriceList.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        18,
                        0,
                        18,
                        10,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                              (
                              context,
                              index,
                              ) {
                            return foodCard(
                              paginatedFoodPriceList[
                              index
                              ],
                            );
                          },
                          childCount: paginatedFoodPriceList.length,
                        ),
                      ),
                    ),

                  if (searchController.text.trim().isNotEmpty && !isLoading && foodPriceList.isNotEmpty)
                    SliverPadding(
                      padding:
                      const EdgeInsets.fromLTRB(
                        18,
                        0,
                        18,
                        30,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          children: [
                            Text(
                              'Showing '
                                  '${currentPage * itemsPerPage + 1}'
                                  ' - '
                                  '${currentPage * itemsPerPage + paginatedFoodPriceList.length}'
                                  ' of '
                                  '${foodPriceList.length}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: secondaryText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(
                              height: 12,
                            ),

                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: currentPage > 0
                                        ? goToPreviousPage
                                        : null,
                                    icon:
                                    const Icon(
                                      Icons.arrow_back_rounded,
                                      size: 19,
                                    ),
                                    label: const Text(
                                      'Previous',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: primaryGreen,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      side: const BorderSide(
                                        color: primaryGreen,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  width: 10,
                                ),

                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: lightGreen,
                                    borderRadius: BorderRadius.circular(
                                      14,
                                    ),
                                  ),
                                  child: Text(
                                    '${currentPage + 1}/$totalPages',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: primaryGreen,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  width: 10,
                                ),

                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: currentPage < totalPages - 1 ? goToNextPage : null,
                                    label: const Text(
                                      'Next',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 19,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryGreen,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}