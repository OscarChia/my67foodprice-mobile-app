import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  List<Map<String, dynamic>> foodPriceList = [];

  Set<int> savedItemCodes = {};

  bool isLoading = true;
  bool showFilters = false;

  int? savingItemCode;

  final searchController = TextEditingController();

  String selectedCategory = 'All Categories';
  String selectedState = 'All States';
  String selectedSort = 'Default';

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

    selectedCategory =
        widget.initialCategory ?? 'All Categories';

    loadInitialData();
  }

  Future<void> loadInitialData() async {
    await Future.wait([
      loadStates(),
      loadSavedItems(),
    ]);

    await fetchFoodPrices();
  }

  Future<void> loadSavedItems() async {
    final user =
        Supabase.instance.client.auth.currentUser;

    if (user == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        savedItemCodes = {};
      });

      return;
    }

    try {
      final data =
      await Supabase.instance.client
          .from('saved_items')
          .select('item_code')
          .eq(
        'user_id',
        user.id,
      );

      final codes = data
          .map<int?>(
            (row) => int.tryParse(
          row['item_code'].toString(),
        ),
      )
          .whereType<int>()
          .toSet();

      if (!mounted) {
        return;
      }

      setState(() {
        savedItemCodes = codes;
      });
    } catch (e) {
      debugPrint(
        'Error loading saved items: $e',
      );
    }
  }

  Future<void> refreshSavedItems() async {
    await loadSavedItems();
  }

  Future<void> toggleSavedItem(
      int itemCode,
      ) async {
    if (savingItemCode != null) {
      return;
    }

    final user =
        Supabase.instance.client.auth.currentUser;

    if (user == null) {
      showMessage(
        'Please login first.',
      );

      return;
    }

    final isAlreadySaved =
    savedItemCodes.contains(itemCode);

    try {
      setState(() {
        savingItemCode = itemCode;
      });

      if (isAlreadySaved) {
        await Supabase.instance.client
            .from('saved_items')
            .delete()
            .eq(
          'user_id',
          user.id,
        )
            .eq(
          'item_code',
          itemCode,
        );

        if (!mounted) {
          return;
        }

        setState(() {
          savedItemCodes.remove(
            itemCode,
          );
        });

        showMessage(
          'Removed from favourites.',
        );
      } else {
        await Supabase.instance.client
            .from('saved_items')
            .insert({
          'user_id': user.id,
          'item_code': itemCode,
          'alert_enabled': true,
        });

        if (!mounted) {
          return;
        }

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
      debugPrint(
        'Favourite error: $e',
      );

      showMessage(
        'Unable to update favourite.',
      );
    } finally {
      if (mounted) {
        setState(() {
          savingItemCode = null;
        });
      }
    }
  }

  Future<void> loadStates() async {
    try {
      final premiseData =
      await Supabase.instance.client
          .from('premises')
          .select('state');

      final stateSet = premiseData
          .map(
            (premise) =>
            premise['state'].toString(),
      )
          .where(
            (state) => state.isNotEmpty,
      )
          .toSet()
          .toList();

      stateSet.sort();

      if (!mounted) {
        return;
      }

      setState(() {
        states = [
          'All States',
          ...stateSet,
        ];
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      showMessage(
        'Error loading states: $e',
      );
    }
  }

  Future<void> fetchFoodPrices() async {
    setState(() {
      isLoading = true;
    });

    try {
      final searchText =
      searchController.text
          .trim()
          .toLowerCase();

      final itemData =
      await Supabase.instance.client
          .from('food_items')
          .select();

      List<Map<String, dynamic>>
      matchingItems =
      List<Map<String, dynamic>>.from(
        itemData,
      );

      matchingItems =
          matchingItems.where((item) {
            final category =
            item['item_category'].toString();

            return categories.contains(
              category,
            );
          }).toList();

      if (selectedCategory !=
          'All Categories') {
        matchingItems =
            matchingItems.where((item) {
              return item['item_category']
                  .toString() ==
                  selectedCategory;
            }).toList();
      }

      if (searchText.isNotEmpty) {
        matchingItems =
            matchingItems.where((item) {
              final itemName =
              item['item']
                  .toString()
                  .toLowerCase();

              return itemName.contains(
                searchText,
              );
            }).toList();
      }

      if (matchingItems.isEmpty) {
        if (!mounted) {
          return;
        }

        setState(() {
          foodPriceList = [];
          isLoading = false;
        });

        return;
      }

      final itemCodes =
      matchingItems
          .map(
            (item) =>
        item['item_code'],
      )
          .toList();

      List<Map<String, dynamic>>
      selectedPremises = [];

      List<dynamic> premiseCodes = [];

      if (selectedState !=
          'All States') {
        final premiseData =
        await Supabase.instance.client
            .from('premises')
            .select()
            .eq(
          'state',
          selectedState,
        );

        selectedPremises =
        List<Map<String, dynamic>>
            .from(
          premiseData,
        );

        if (selectedPremises.isEmpty) {
          if (!mounted) {
            return;
          }

          setState(() {
            foodPriceList = [];
            isLoading = false;
          });

          return;
        }

        premiseCodes =
            selectedPremises
                .map(
                  (premise) =>
              premise['premise_code'],
            )
                .toList();
      }

      List<dynamic> priceData;

      if (selectedState ==
          'All States') {
        priceData =
        await Supabase.instance.client
            .from('food_prices')
            .select()
            .inFilter(
          'item_code',
          itemCodes,
        )
            .order(
          'date',
          ascending: false,
        )
            .limit(100);
      } else {
        priceData =
        await Supabase.instance.client
            .from('food_prices')
            .select()
            .inFilter(
          'item_code',
          itemCodes,
        )
            .inFilter(
          'premise_code',
          premiseCodes,
        )
            .order(
          'date',
          ascending: false,
        )
            .limit(100);
      }

      if (priceData.isEmpty) {
        if (!mounted) {
          return;
        }

        setState(() {
          foodPriceList = [];
          isLoading = false;
        });

        return;
      }

      final usedPremiseCodes =
      priceData
          .map(
            (price) =>
        price['premise_code'],
      )
          .toSet()
          .toList();

      List<Map<String, dynamic>>
      premiseList;

      if (selectedState ==
          'All States') {
        final premiseData =
        await Supabase.instance.client
            .from('premises')
            .select()
            .inFilter(
          'premise_code',
          usedPremiseCodes,
        );

        premiseList =
        List<Map<String, dynamic>>
            .from(
          premiseData,
        );
      } else {
        premiseList =
            selectedPremises;
      }

      List<Map<String, dynamic>>
      combinedList = [];

      for (final price in priceData) {
        final item =
        matchingItems.firstWhere(
              (item) =>
          item['item_code'] ==
              price['item_code'],
        );

        final premise =
        premiseList.firstWhere(
              (premise) =>
          premise['premise_code'] ==
              price['premise_code'],
          orElse: () => {
            'premise':
            'Unknown Premise',
            'state': '',
            'district': '',
          },
        );

        combinedList.add({
          'date': price['date'],
          'price': price['price'],
          'item_code':
          price['item_code'],
          'premise_code':
          price['premise_code'],
          'item': item['item'],
          'unit': item['unit'],
          'category':
          item['item_category'],
          'premise':
          premise['premise'],
          'state':
          premise['state'],
          'district':
          premise['district'],
        });
      }

      if (selectedSort ==
          'Price: Low to High') {
        combinedList.sort(
              (a, b) {
            final priceA =
            double.parse(
              a['price'].toString(),
            );

            final priceB =
            double.parse(
              b['price'].toString(),
            );

            return priceA.compareTo(
              priceB,
            );
          },
        );
      }

      if (selectedSort ==
          'Price: High to Low') {
        combinedList.sort(
              (a, b) {
            final priceA =
            double.parse(
              a['price'].toString(),
            );

            final priceB =
            double.parse(
              b['price'].toString(),
            );

            return priceB.compareTo(
              priceA,
            );
          },
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        foodPriceList =
            combinedList;

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });

      showMessage(
        'Error: $e',
      );
    }
  }

  void showMessage(
      String message,
      ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
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
      prefixIcon: Icon(
        icon,
        size: 20,
        color: primaryGreen,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
      const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(14),
        borderSide:
        const BorderSide(
          color: Color(0xFFE2E8E5),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(14),
        borderSide:
        const BorderSide(
          color: Color(0xFFE2E8E5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(14),
        borderSide:
        const BorderSide(
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color:
          const Color(0xFFE2E8E5),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.tune,
                size: 20,
                color: primaryGreen,
              ),
              SizedBox(width: 7),
              Text(
                'Filter Food Prices',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                  FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          DropdownButtonFormField<String>(
            initialValue:
            selectedCategory,
            isExpanded: true,
            decoration:
            dropdownDecoration(
              label: 'Category',
              icon:
              Icons.category_outlined,
            ),
            items: categories.map(
                  (category) {
                return DropdownMenuItem<
                    String>(
                  value: category,
                  child: Text(
                    category,
                    overflow:
                    TextOverflow
                        .ellipsis,
                    style:
                    const TextStyle(
                      fontSize: 11,
                    ),
                  ),
                );
              },
            ).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedCategory =
                      value;
                });

                fetchFoodPrices();
              }
            },
          ),

          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            initialValue:
            selectedState,
            isExpanded: true,
            decoration:
            dropdownDecoration(
              label: 'State',
              icon: Icons
                  .location_on_outlined,
            ),
            items: states.map(
                  (state) {
                return DropdownMenuItem<
                    String>(
                  value: state,
                  child: Text(
                    state,
                    overflow:
                    TextOverflow
                        .ellipsis,
                    style:
                    const TextStyle(
                      fontSize: 11,
                    ),
                  ),
                );
              },
            ).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedState =
                      value;
                });

                fetchFoodPrices();
              }
            },
          ),

          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            initialValue:
            selectedSort,
            isExpanded: true,
            decoration:
            dropdownDecoration(
              label: 'Sort Price',
              icon: Icons.sort,
            ),
            items: sortOptions.map(
                  (sort) {
                return DropdownMenuItem<
                    String>(
                  value: sort,
                  child: Text(
                    sort,
                    style:
                    const TextStyle(
                      fontSize: 11,
                    ),
                  ),
                );
              },
            ).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedSort =
                      value;
                });

                fetchFoodPrices();
              }
            },
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  selectedCategory =
                  'All Categories';

                  selectedState =
                  'All States';

                  selectedSort =
                  'Default';

                  searchController.clear();
                });

                fetchFoodPrices();
              },
              icon: const Icon(
                Icons.refresh,
                size: 18,
              ),
              label: const Text(
                'Reset Filters',
              ),
              style:
              OutlinedButton.styleFrom(
                foregroundColor:
                primaryGreen,
                side: const BorderSide(
                  color: primaryGreen,
                ),
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
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
    final itemCode =
    int.tryParse(
      food['item_code'].toString(),
    );

    final isSaved =
        itemCode != null &&
            savedItemCodes.contains(
              itemCode,
            );

    final isSaving =
        savingItemCode == itemCode;

    final price =
        double.tryParse(
          food['price'].toString(),
        ) ??
            0;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 11,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color:
          const Color(0xFFE3E9E6),
        ),
      ),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  FoodDetailsPage(
                    itemCode:
                    food['item_code'],
                    itemName:
                    food['item'],
                    unit:
                    food['unit'],
                  ),
            ),
          );
        },
        child: Padding(
          padding:
          const EdgeInsets.all(13),
          child: Row(
            crossAxisAlignment:
            CrossAxisAlignment.center,
            children: [
              Container(
                width: 55,
                height: 55,
                decoration:
                BoxDecoration(
                  color: lightGreen,
                  borderRadius:
                  BorderRadius
                      .circular(15),
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  color: primaryGreen,
                  size: 27,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      food['item']
                          .toString(),
                      maxLines: 2,
                      overflow:
                      TextOverflow
                          .ellipsis,
                      style:
                      const TextStyle(
                        fontSize: 13,
                        fontWeight:
                        FontWeight.w700,
                        color: textColor,
                      ),
                    ),

                    const SizedBox(
                        height: 5),

                    Row(
                      children: [
                        const Icon(
                          Icons
                              .category_outlined,
                          size: 13,
                          color:
                          Colors.black45,
                        ),

                        const SizedBox(
                            width: 4),

                        Expanded(
                          child: Text(
                            '${food['category']} • ${food['unit']}',
                            maxLines: 1,
                            overflow:
                            TextOverflow
                                .ellipsis,
                            style:
                            const TextStyle(
                              fontSize: 9,
                              color: Colors
                                  .black54,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                        height: 4),

                    Row(
                      children: [
                        const Icon(
                          Icons.store_outlined,
                          size: 13,
                          color:
                          Colors.black45,
                        ),

                        const SizedBox(
                            width: 4),

                        Expanded(
                          child: Text(
                            food['premise']
                                .toString(),
                            maxLines: 1,
                            overflow:
                            TextOverflow
                                .ellipsis,
                            style:
                            const TextStyle(
                              fontSize: 9,
                              color: Colors
                                  .black54,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                        height: 4),

                    Row(
                      children: [
                        const Icon(
                          Icons
                              .location_on_outlined,
                          size: 13,
                          color:
                          Colors.black45,
                        ),

                        const SizedBox(
                            width: 4),

                        Expanded(
                          child: Text(
                            '${food['district']}, ${food['state']}',
                            maxLines: 1,
                            overflow:
                            TextOverflow
                                .ellipsis,
                            style:
                            const TextStyle(
                              fontSize: 9,
                              color: Colors
                                  .black45,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                        height: 4),

                    Text(
                      'Updated: ${food['date']}',
                      style:
                      const TextStyle(
                        fontSize: 8,
                        color:
                        Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Column(
                mainAxisSize:
                MainAxisSize.min,
                crossAxisAlignment:
                CrossAxisAlignment
                    .end,
                children: [
                  Text(
                    'RM ${price.toStringAsFixed(2)}',
                    style:
                    const TextStyle(
                      fontSize: 15,
                      fontWeight:
                      FontWeight.bold,
                      color:
                      primaryGreen,
                    ),
                  ),

                  const SizedBox(
                      height: 2),

                  Text(
                    'per ${food['unit']}',
                    style:
                    const TextStyle(
                      fontSize: 8,
                      color:
                      Colors.black45,
                    ),
                  ),

                  const SizedBox(
                      height: 8),

                  if (isSaving)
                    const SizedBox(
                      width: 27,
                      height: 27,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                        primaryGreen,
                      ),
                    )
                  else
                    IconButton(
                      onPressed:
                      itemCode == null
                          ? null
                          : () {
                        toggleSavedItem(
                          itemCode,
                        );
                      },
                      icon: Icon(
                        isSaved
                            ? Icons.favorite
                            : Icons
                            .favorite_border,
                      ),
                      color: isSaved
                          ? Colors.red
                          : Colors.grey,
                      iconSize: 22,
                    ),
                ],
              ),
            ],
          ),
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
      backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding:
              const EdgeInsets
                  .fromLTRB(
                20,
                18,
                20,
                22,
              ),
              decoration:
              const BoxDecoration(
                gradient:
                LinearGradient(
                  begin:
                  Alignment.topLeft,
                  end: Alignment
                      .bottomRight,
                  colors: [
                    primaryGreen,
                    darkGreen,
                  ],
                ),
                borderRadius:
                BorderRadius.only(
                  bottomLeft:
                  Radius.circular(
                    28,
                  ),
                  bottomRight:
                  Radius.circular(
                    28,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  const Text(
                    'Find Food Prices',
                    style:
                    TextStyle(
                      color:
                      Colors.white,
                      fontSize: 23,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                      height: 5),

                  const Text(
                    'Search and compare food prices across Malaysia',
                    style:
                    TextStyle(
                      color: Color(
                        0xFFDCEDE6,
                      ),
                      fontSize: 11,
                    ),
                  ),

                  const SizedBox(
                      height: 18),

                  TextField(
                    controller:
                    searchController,
                    textInputAction:
                    TextInputAction
                        .search,
                    onSubmitted:
                        (value) {
                      fetchFoodPrices();
                    },
                    decoration:
                    InputDecoration(
                      hintText:
                      'Search food name...',
                      prefixIcon:
                      const Icon(
                        Icons.search,
                        color:
                        primaryGreen,
                      ),
                      suffixIcon:
                      searchController
                          .text
                          .isEmpty
                          ? null
                          : IconButton(
                        onPressed:
                            () {
                          searchController
                              .clear();

                          setState(
                                  () {});

                          fetchFoodPrices();
                        },
                        icon:
                        const Icon(
                          Icons.close,
                          size: 20,
                        ),
                      ),
                      filled: true,
                      fillColor:
                      Colors.white,
                      border:
                      OutlineInputBorder(
                        borderRadius:
                        BorderRadius
                            .circular(
                          16,
                        ),
                        borderSide:
                        BorderSide
                            .none,
                      ),
                      enabledBorder:
                      OutlineInputBorder(
                        borderRadius:
                        BorderRadius
                            .circular(
                          16,
                        ),
                        borderSide:
                        BorderSide
                            .none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),

            Expanded(
              child:
              SingleChildScrollView(
                padding:
                const EdgeInsets
                    .fromLTRB(
                  18,
                  17,
                  18,
                  25,
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    InkWell(
                      borderRadius:
                      BorderRadius
                          .circular(
                        14,
                      ),
                      onTap: () {
                        setState(() {
                          showFilters =
                          !showFilters;
                        });
                      },
                      child: Container(
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration:
                        BoxDecoration(
                          color:
                          lightGreen,
                          borderRadius:
                          BorderRadius
                              .circular(
                            14,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.tune,
                              size: 18,
                              color:
                              primaryGreen,
                            ),

                            const SizedBox(
                                width: 7),

                            const Text(
                              'Filters & Sort',
                              style:
                              TextStyle(
                                fontSize: 12,
                                fontWeight:
                                FontWeight
                                    .w600,
                                color:
                                primaryGreen,
                              ),
                            ),

                            const Spacer(),

                            Icon(
                              showFilters
                                  ? Icons
                                  .keyboard_arrow_up
                                  : Icons
                                  .keyboard_arrow_down,
                              color:
                              primaryGreen,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (showFilters)
                      buildFilterArea(),

                    const SizedBox(
                        height: 18),

                    Row(
                      children: [
                        Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                          children: [
                            const Text(
                              'Search Results',
                              style:
                              TextStyle(
                                fontSize: 18,
                                fontWeight:
                                FontWeight
                                    .w700,
                                color:
                                textColor,
                              ),
                            ),

                            const SizedBox(
                                height: 3),

                            Text(
                              '${foodPriceList.length} price record(s) found',
                              style:
                              const TextStyle(
                                fontSize: 10,
                                color:
                                Colors.black45,
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        if (selectedState !=
                            'All States')
                          Container(
                            padding:
                            const EdgeInsets
                                .symmetric(
                              horizontal: 9,
                              vertical: 5,
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
                              selectedState,
                              style:
                              const TextStyle(
                                fontSize: 9,
                                color:
                                primaryGreen,
                                fontWeight:
                                FontWeight
                                    .w600,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(
                        height: 12),

                    if (isLoading)
                      const Padding(
                        padding:
                        EdgeInsets.all(
                          45,
                        ),
                        child: Center(
                          child:
                          CircularProgressIndicator(
                            color:
                            primaryGreen,
                          ),
                        ),
                      )
                    else if (foodPriceList
                        .isEmpty)
                      Container(
                        width:
                        double.infinity,
                        padding:
                        const EdgeInsets
                            .symmetric(
                          vertical: 45,
                          horizontal: 20,
                        ),
                        decoration:
                        BoxDecoration(
                          color:
                          Colors.white,
                          borderRadius:
                          BorderRadius
                              .circular(
                            18,
                          ),
                          border:
                          Border.all(
                            color:
                            const Color(
                              0xFFE3E9E6,
                            ),
                          ),
                        ),
                        child:
                        const Column(
                          children: [
                            Icon(
                              Icons
                                  .search_off_outlined,
                              size: 50,
                              color: Colors
                                  .black26,
                            ),

                            SizedBox(
                                height: 12),

                            Text(
                              'No food price found',
                              style:
                              TextStyle(
                                fontSize: 15,
                                fontWeight:
                                FontWeight
                                    .w600,
                              ),
                            ),

                            SizedBox(
                                height: 5),

                            Text(
                              'Try another food name or change the filters.',
                              textAlign:
                              TextAlign
                                  .center,
                              style:
                              TextStyle(
                                fontSize: 11,
                                color:
                                Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics:
                        const NeverScrollableScrollPhysics(),
                        itemCount:
                        foodPriceList.length,
                        itemBuilder:
                            (
                            context,
                            index,
                            ) {
                          return foodCard(
                            foodPriceList[
                            index],
                          );
                        },
                      ),
                  ],
                ),
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