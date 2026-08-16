import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'food_comparison_page.dart';

class FoodPricePage extends StatefulWidget {
  final String? initialCategory;

  const FoodPricePage({
    super.key,
    this.initialCategory,
  });

  @override
  State<FoodPricePage> createState() =>
      _FoodPricePageState();
}

class _FoodPricePageState extends State<FoodPricePage> {
  List<Map<String, dynamic>> foodPriceList = [];

  bool isLoading = true;
  bool showFilters = false;

  final searchController =
  TextEditingController();

  String selectedCategory =
      'All Categories';

  String selectedState =
      'All States';

  String selectedSort =
      'Default';

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
        widget.initialCategory ??
            'All Categories';

    loadStates();
    fetchFoodPrices();
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
            (state) =>
        state.isNotEmpty,
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

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Error loading states: $e',
          ),
        ),
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
            item['item_category']
                .toString();

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
              premise[
              'premise_code'],
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
        price[
        'premise_code'],
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
          'date':
          price['date'],
          'price':
          price['price'],
          'item_code':
          price['item_code'],
          'premise_code':
          price['premise_code'],
          'item':
          item['item'],
          'unit':
          item['unit'],
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

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
          ),
        ),
      );
    }
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
        color: const Color(
          0xFF159A7D,
        ),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      border: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(13),
        borderSide: BorderSide.none,
      ),
      enabledBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Color(
            0xFFE3E9E6,
          ),
        ),
      ),
      focusedBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Color(
            0xFF159A7D,
          ),
        ),
      ),
    );
  }

  Widget buildFilterArea() {
    return Container(
      margin:
      const EdgeInsets.only(
        top: 10,
      ),
      padding:
      const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
        const Color(
          0xFFF0F5F3,
        ),
        borderRadius:
        BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value:
            selectedCategory,
            isExpanded: true,
            decoration:
            dropdownDecoration(
              label: 'Category',
              icon:
              Icons.category_outlined,
            ),
            items:
            categories.map(
                  (category) {
                return DropdownMenuItem<
                    String>(
                  value:
                  category,
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

          const SizedBox(
            height: 9,
          ),

          DropdownButtonFormField<String>(
            value:
            selectedState,
            isExpanded: true,
            decoration:
            dropdownDecoration(
              label: 'State',
              icon: Icons
                  .location_on_outlined,
            ),
            items:
            states.map(
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

          const SizedBox(
            height: 9,
          ),

          DropdownButtonFormField<String>(
            value:
            selectedSort,
            isExpanded: true,
            decoration:
            dropdownDecoration(
              label: 'Sort Price',
              icon: Icons.sort,
            ),
            items:
            sortOptions.map(
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
        ],
      ),
    );
  }

  Widget foodCard(
      Map<String, dynamic> food,
      ) {
    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 5,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  FoodComparisonPage(
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
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color:
            Colors.teal.shade50,
            borderRadius:
            BorderRadius.circular(
              12,
            ),
          ),
          child: const Icon(
            Icons.fastfood,
            color: Colors.teal,
          ),
        ),
        title: Text(
          food['item'].toString(),
          maxLines: 2,
          overflow:
          TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight:
            FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${food['category']} • ${food['unit']}\n'
              '${food['premise']}\n'
              '${food['date']}',
          maxLines: 3,
          overflow:
          TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 9,
            color: Colors.black54,
          ),
        ),
        trailing: Text(
          'RM ${double.parse(food['price'].toString()).toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight:
            FontWeight.bold,
            color: Color(
              0xFF0C8F72,
            ),
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
      const Color(
        0xFFF5F7F6,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.fromLTRB(
            16,
            12,
            16,
            18,
          ),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [
              const Text(
                'Find Food Prices',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              TextField(
                controller:
                searchController,
                onSubmitted:
                    (value) {
                  fetchFoodPrices();
                },
                decoration:
                InputDecoration(
                  hintText:
                  'Search by food name...',
                  prefixIcon:
                  const Icon(
                    Icons.search,
                    color:
                    Color(
                      0xFF159A7D,
                    ),
                  ),
                  suffixIcon:
                  IconButton(
                    onPressed: () {
                      fetchFoodPrices();
                    },
                    icon:
                    const Icon(
                      Icons.search,
                      color:
                      Color(
                        0xFF159A7D,
                      ),
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
                      14,
                    ),
                    borderSide:
                    BorderSide.none,
                  ),
                  enabledBorder:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius
                        .circular(
                      14,
                    ),
                    borderSide:
                    const BorderSide(
                      color:
                      Color(
                        0xFFE2E8E5,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              InkWell(
                borderRadius:
                BorderRadius.circular(
                  10,
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
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    const Color(
                      0xFFE5F5F0,
                    ),
                    borderRadius:
                    BorderRadius
                        .circular(
                      10,
                    ),
                  ),
                  child: Row(
                    mainAxisSize:
                    MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.tune,
                        size: 17,
                        color:
                        Color(
                          0xFF0C8F72,
                        ),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      const Text(
                        'Filters & Sort',
                        style:
                        TextStyle(
                          fontSize: 11,
                          fontWeight:
                          FontWeight
                              .bold,
                          color:
                          Color(
                            0xFF0C8F72,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      Icon(
                        showFilters
                            ? Icons
                            .keyboard_arrow_up
                            : Icons
                            .keyboard_arrow_down,
                        size: 18,
                        color:
                        const Color(
                          0xFF0C8F72,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (showFilters)
                buildFilterArea(),

              const SizedBox(
                height: 12,
              ),

              Row(
                children: [
                  Text(
                    '${foodPriceList.length} result(s)',
                    style:
                    const TextStyle(
                      fontSize: 11,
                      color:
                      Colors.black54,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    selectedState,
                    style:
                    const TextStyle(
                      fontSize: 10,
                      color:
                      Color(
                        0xFF0C8F72,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 10,
              ),

              if (isLoading)
                const Padding(
                  padding:
                  EdgeInsets.all(
                    40,
                  ),
                  child: Center(
                    child:
                    CircularProgressIndicator(),
                  ),
                )
              else if (foodPriceList
                  .isEmpty)
                const Padding(
                  padding:
                  EdgeInsets.all(
                    40,
                  ),
                  child: Center(
                    child: Text(
                      'No food found',
                    ),
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
                      (context, index) {
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
    );
  }

  @override
  void dispose() {
    searchController.dispose();

    super.dispose();
  }
}