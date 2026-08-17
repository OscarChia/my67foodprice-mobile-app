import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const Color primaryGreen = Color(0xFF176B52);
  static const Color darkGreen = Color(0xFF0F513D);
  static const Color backgroundColor = Color(0xFFF6F8F5);
  static const Color lightGreen = Color(0xFFEAF4EF);
  static const Color textColor = Color(0xFF1F2924);

  final MapController mapController = MapController();

  bool isLoading = true;

  int? selectedItemCode;

  String selectedState = 'All States';

  Map<String, dynamic>? selectedStore;

  List<Map<String, dynamic>> foodItems = [];

  List<Map<String, dynamic>> storeList = [];

  List<String> states = [
    'All States',
  ];

  @override
  void initState() {
    super.initState();

    loadInitialData();
  }

  Future<void> loadInitialData() async {
    await loadStates();
    await loadFoodItemsWithPrices();
  }

  Future<void> loadStates() async {
    try {
      final data =
      await Supabase.instance.client
          .from('premises')
          .select('state');

      final stateSet = data
          .map(
            (row) =>
        row['state']
            ?.toString()
            .trim() ??
            '',
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
      debugPrint(
        'Error loading states: $e',
      );
    }
  }

  Future<void> loadFoodItemsWithPrices() async {
    try {
      setState(() {
        isLoading = true;
      });

      final priceData =
      await Supabase.instance.client
          .from(
        'monthly_food_price_summary',
      )
          .select(
        'item_code',
      );

      final itemCodeSet = priceData
          .map(
            (row) =>
        row['item_code'],
      )
          .where(
            (code) => code != null,
      )
          .toSet();

      if (itemCodeSet.isEmpty) {
        if (!mounted) {
          return;
        }

        setState(() {
          foodItems = [];
          storeList = [];
          selectedItemCode = null;
          isLoading = false;
        });

        return;
      }

      final itemCodes =
      itemCodeSet.toList();

      final List<Map<String, dynamic>>
      allFoodItems = [];

      const batchSize = 200;

      for (
      int i = 0;
      i < itemCodes.length;
      i += batchSize
      ) {
        final end =
        i + batchSize < itemCodes.length
            ? i + batchSize
            : itemCodes.length;

        final batch =
        itemCodes.sublist(
          i,
          end,
        );

        final data =
        await Supabase.instance.client
            .from('food_items')
            .select()
            .inFilter(
          'item_code',
          batch,
        );

        allFoodItems.addAll(
          List<Map<String, dynamic>>.from(
            data,
          ),
        );
      }

      allFoodItems.sort(
            (a, b) {
          final nameA =
              a['item']
                  ?.toString()
                  .toUpperCase() ??
                  '';

          final nameB =
              b['item']
                  ?.toString()
                  .toUpperCase() ??
                  '';

          return nameA.compareTo(
            nameB,
          );
        },
      );

      if (!mounted) {
        return;
      }

      setState(() {
        foodItems = allFoodItems;

        if (foodItems.isNotEmpty) {
          selectedItemCode =
          foodItems.first[
          'item_code'];
        } else {
          selectedItemCode = null;
        }
      });

      if (selectedItemCode != null) {
        await loadStores();
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });

      showMessage(
        'Error loading food items: $e',
      );
    }
  }

  Future<void> loadStores() async {
    if (selectedItemCode == null) {
      return;
    }

    setState(() {
      isLoading = true;
      selectedStore = null;
      storeList = [];
    });

    try {
      final priceData =
      await Supabase.instance.client
          .from('food_prices')
          .select()
          .eq(
        'item_code',
        selectedItemCode!,
      )
          .order(
        'date',
        ascending: false,
      )
          .limit(5000);

      if (priceData.isEmpty) {
        if (!mounted) {
          return;
        }

        setState(() {
          storeList = [];
          isLoading = false;
        });

        resetMap();

        return;
      }

      final Map<
          dynamic,
          Map<String, dynamic>>
      latestPrices = {};

      for (final price in priceData) {
        final premiseCode =
        price['premise_code'];

        if (premiseCode == null) {
          continue;
        }

        if (!latestPrices.containsKey(
          premiseCode,
        )) {
          latestPrices[premiseCode] =
          Map<String, dynamic>.from(
            price,
          );
        }
      }

      final premiseCodes =
      latestPrices.keys.toList();

      if (premiseCodes.isEmpty) {
        if (!mounted) {
          return;
        }

        setState(() {
          storeList = [];
          isLoading = false;
        });

        resetMap();

        return;
      }

      final List<Map<String, dynamic>>
      premises = [];

      const batchSize = 200;

      for (
      int i = 0;
      i < premiseCodes.length;
      i += batchSize
      ) {
        final end =
        i + batchSize <
            premiseCodes.length
            ? i + batchSize
            : premiseCodes.length;

        final batch =
        premiseCodes.sublist(
          i,
          end,
        );

        final data =
        await Supabase.instance.client
            .from('premises')
            .select()
            .inFilter(
          'premise_code',
          batch,
        );

        premises.addAll(
          List<Map<String, dynamic>>.from(
            data,
          ),
        );
      }

      List<Map<String, dynamic>>
      combinedList = [];

      for (final premise in premises) {
        final premiseState =
            premise['state']
                ?.toString()
                .trim() ??
                '';

        if (selectedState !=
            'All States' &&
            premiseState !=
                selectedState) {
          continue;
        }

        final price =
        latestPrices[
        premise['premise_code']];

        if (price == null) {
          continue;
        }

        combinedList.add({
          'premise_code':
          premise['premise_code'],
          'premise':
          premise['premise'],
          'address':
          premise['address'],
          'district':
          premise['district'],
          'state':
          premise['state'],
          'premise_type':
          premise['premise_type'],
          'latitude':
          premise['latitude'],
          'longitude':
          premise['longitude'],
          'geocode_status':
          premise['geocode_status'],
          'price':
          price['price'],
          'date':
          price['date'],
        });
      }

      combinedList.sort(
            (a, b) {
          final priceA =
              double.tryParse(
                a['price'].toString(),
              ) ??
                  999999;

          final priceB =
              double.tryParse(
                b['price'].toString(),
              ) ??
                  999999;

          return priceA.compareTo(
            priceB,
          );
        },
      );

      combinedList =
          combinedList.take(10).toList();

      if (!mounted) {
        return;
      }

      setState(() {
        storeList = combinedList;
        isLoading = false;
      });

      moveMapToFirstVerifiedStore();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });

      showMessage(
        'Error loading stores: $e',
      );
    }
  }

  void moveMapToFirstVerifiedStore() {
    for (final store in storeList) {
      final status =
          store['geocode_status']
              ?.toString() ??
              '';

      final latitude =
      double.tryParse(
        store['latitude']
            ?.toString() ??
            '',
      );

      final longitude =
      double.tryParse(
        store['longitude']
            ?.toString() ??
            '',
      );

      if (status == 'verified' &&
          latitude != null &&
          longitude != null) {
        Future.delayed(
          const Duration(
            milliseconds: 300,
          ),
              () {
            if (!mounted) {
              return;
            }

            mapController.move(
              LatLng(
                latitude,
                longitude,
              ),
              12,
            );
          },
        );

        return;
      }
    }

    resetMap();
  }

  void resetMap() {
    Future.delayed(
      const Duration(
        milliseconds: 300,
      ),
          () {
        if (!mounted) {
          return;
        }

        mapController.move(
          const LatLng(
            4.2105,
            101.9758,
          ),
          5.5,
        );
      },
    );
  }

  void locateStore(
      Map<String, dynamic> store,
      ) {
    final status =
        store['geocode_status']
            ?.toString() ??
            '';

    final latitude =
    double.tryParse(
      store['latitude']
          ?.toString() ??
          '',
    );

    final longitude =
    double.tryParse(
      store['longitude']
          ?.toString() ??
          '',
    );

    setState(() {
      selectedStore = store;
    });

    if (status != 'verified' ||
        latitude == null ||
        longitude == null) {
      showMessage(
        'Verified store location is not available yet.',
      );

      return;
    }

    mapController.move(
      LatLng(
        latitude,
        longitude,
      ),
      16,
    );
  }

  String getSelectedFoodName() {
    if (selectedItemCode == null) {
      return '';
    }

    for (final food in foodItems) {
      if (food['item_code'] ==
          selectedItemCode) {
        return food['item']
            ?.toString() ??
            '';
      }
    }

    return '';
  }

  List<Marker> buildMarkers() {
    final List<Marker> markers = [];

    for (
    int i = 0;
    i < storeList.length;
    i++
    ) {
      final store =
      storeList[i];

      final status =
          store['geocode_status']
              ?.toString() ??
              '';

      if (status != 'verified') {
        continue;
      }

      final latitude =
      double.tryParse(
        store['latitude']
            ?.toString() ??
            '',
      );

      final longitude =
      double.tryParse(
        store['longitude']
            ?.toString() ??
            '',
      );

      if (latitude == null ||
          longitude == null) {
        continue;
      }

      final isSelected =
          selectedStore?[
          'premise_code'] ==
              store['premise_code'];

      final isCheapest =
          i == 0;

      markers.add(
        Marker(
          point: LatLng(
            latitude,
            longitude,
          ),
          width: 50,
          height: 50,
          child: GestureDetector(
            onTap: () {
              setState(() {
                selectedStore =
                    store;
              });

              mapController.move(
                LatLng(
                  latitude,
                  longitude,
                ),
                16,
              );
            },
            child: Icon(
              Icons.location_on,
              size: isCheapest
                  ? 46
                  : isSelected
                  ? 43
                  : 37,
              color: isCheapest
                  ? Colors.orange
                  : isSelected
                  ? Colors.red
                  : primaryGreen,
            ),
          ),
        ),
      );
    }

    return markers;
  }

  Widget buildFoodDropdown() {
    return DropdownButtonFormField<int>(
      initialValue: selectedItemCode,
      isExpanded: true,
      menuMaxHeight: 350,

      decoration: InputDecoration(
        prefixIcon: const Icon(
          Icons.restaurant_menu,
          color: primaryGreen,
          size: 20,
        ),

        prefixIconConstraints: const BoxConstraints(
          minWidth: 45,
          minHeight: 45,
        ),

        filled: true,
        fillColor: Colors.white,
        isDense: true,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 15,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFE3E9E6),
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: primaryGreen,
            width: 1.5,
          ),
        ),
      ),

      items: foodItems.map(
            (food) {
          return DropdownMenuItem<int>(
            value: food['item_code'],
            child: Text(
              food['item']?.toString() ?? '',
              maxLines: 1,
              style: const TextStyle(
                fontSize: 12,
                color: textColor,
              ),
            ),
          );
        },
      ).toList(),

      onChanged: (value) {
        if (value == null) {
          return;
        }

        setState(() {
          selectedItemCode = value;
          selectedStore = null;
        });

        loadStores();
      },
    );
  }

  Widget buildStateDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: selectedState,
      isExpanded: true,
      menuMaxHeight: 350,

      decoration: InputDecoration(
        prefixIcon: const Icon(
          Icons.location_on_outlined,
          color: primaryGreen,
          size: 20,
        ),

        prefixIconConstraints: const BoxConstraints(
          minWidth: 45,
          minHeight: 45,
        ),

        filled: true,
        fillColor: Colors.white,
        isDense: true,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 15,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFE3E9E6),
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: primaryGreen,
            width: 1.5,
          ),
        ),
      ),

      items: states.map(
            (state) {
          return DropdownMenuItem<String>(
            value: state,
            child: Text(
              state,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 12,
                color: textColor,
              ),
            ),
          );
        },
      ).toList(),

      onChanged: (value) {
        if (value == null) {
          return;
        }

        setState(() {
          selectedState = value;
          selectedStore = null;
        });

        loadStores();
      },
    );
  }

  Widget buildCheapestBadge() {
    if (storeList.isEmpty) {
      return const SizedBox.shrink();
    }

    final cheapest =
        storeList.first;

    final price =
        double.tryParse(
          cheapest['price']
              .toString(),
        ) ??
            0;

    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        width: 145,
        padding:
        const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(
            13,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(
                0,
                2,
              ),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const Text(
              'CHEAPEST',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 8,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 2,
            ),

            Text(
              cheapest['premise']
                  ?.toString() ??
                  '',
              maxLines: 1,
              overflow:
              TextOverflow.ellipsis,
              style:
              const TextStyle(
                color: primaryGreen,
                fontSize: 11,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            Text(
              'RM ${price.toStringAsFixed(2)}',
              style:
              const TextStyle(
                color: primaryGreen,
                fontSize: 14,
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSelectedStoreCard() {
    if (selectedStore == null) {
      return const SizedBox.shrink();
    }

    final price =
        double.tryParse(
          selectedStore!['price']
              .toString(),
        ) ??
            0;

    final status =
        selectedStore![
        'geocode_status']
            ?.toString() ??
            '';

    final isVerified =
        status == 'verified';

    final isCheapest =
        storeList.isNotEmpty &&
            selectedStore![
            'premise_code'] ==
                storeList.first[
                'premise_code'];

    return Container(
      margin:
      const EdgeInsets.fromLTRB(
        14,
        12,
        14,
        0,
      ),
      padding:
      const EdgeInsets.all(
        13,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          17,
        ),
        border: Border.all(
          color: isVerified
              ? primaryGreen
              : Colors.orange,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration:
                BoxDecoration(
                  color: isVerified
                      ? primaryGreen
                      : Colors.orange,
                  borderRadius:
                  BorderRadius
                      .circular(
                    12,
                  ),
                ),
                child: const Icon(
                  Icons.store,
                  color: Colors.white,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      selectedStore![
                      'premise']
                          ?.toString() ??
                          '',
                      maxLines: 1,
                      overflow:
                      TextOverflow
                          .ellipsis,
                      style:
                      const TextStyle(
                        fontWeight:
                        FontWeight
                            .bold,
                        fontSize: 13,
                        color:
                        textColor,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      '${selectedStore!['district'] ?? ''}, '
                          '${selectedStore!['state'] ?? ''}',
                      style:
                      const TextStyle(
                        color:
                        Colors.grey,
                        fontSize: 9,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      selectedStore![
                      'address']
                          ?.toString() ??
                          '',
                      maxLines: 3,
                      overflow:
                      TextOverflow
                          .ellipsis,
                      style:
                      const TextStyle(
                        color:
                        Colors.black54,
                        fontSize: 9,
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      isVerified
                          ? 'Verified location'
                          : 'Location not verified yet',
                      style: TextStyle(
                        color: isVerified
                            ? primaryGreen
                            : Colors.orange,
                        fontSize: 9,
                        fontWeight:
                        FontWeight
                            .w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .end,
                children: [
                  Text(
                    'RM ${price.toStringAsFixed(2)}',
                    style:
                    const TextStyle(
                      color:
                      primaryGreen,
                      fontWeight:
                      FontWeight
                          .bold,
                      fontSize: 16,
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      locateStore(
                        selectedStore!,
                      );
                    },
                    icon: const Icon(
                      Icons.navigation,
                      size: 20,
                    ),
                    color: isVerified
                        ? primaryGreen
                        : Colors.orange,
                  ),
                ],
              ),
            ],
          ),

          if (isCheapest)
            Container(
              width:
              double.infinity,
              margin:
              const EdgeInsets
                  .only(
                top: 9,
              ),
              padding:
              const EdgeInsets
                  .symmetric(
                vertical: 7,
              ),
              decoration:
              BoxDecoration(
                color: lightGreen,
                borderRadius:
                BorderRadius
                    .circular(
                  9,
                ),
              ),
              child: Text(
                'Best price for '
                    '${getSelectedFoodName()}',
                textAlign:
                TextAlign.center,
                style:
                const TextStyle(
                  color:
                  primaryGreen,
                  fontSize: 10,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildStoreCard(
      Map<String, dynamic> store,
      int index,
      ) {
    final price =
        double.tryParse(
          store['price']
              .toString(),
        ) ??
            0;

    final status =
        store['geocode_status']
            ?.toString() ??
            '';

    final isVerified =
        status == 'verified';

    final isCheapest =
        index == 0;

    final isSelected =
        selectedStore?[
        'premise_code'] ==
            store['premise_code'];

    return InkWell(
      onTap: () {
        setState(() {
          selectedStore = store;
        });
      },
      borderRadius:
      BorderRadius.circular(
        16,
      ),
      child: Container(
        margin:
        const EdgeInsets.only(
          bottom: 9,
        ),
        padding:
        const EdgeInsets.all(
          11,
        ),
        decoration:
        BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(
            16,
          ),
          border: Border.all(
            color: isSelected
                ? primaryGreen
                : const Color(
              0xFFE7EBEA,
            ),
            width:
            isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment:
              Alignment.center,
              decoration:
              BoxDecoration(
                color: isCheapest
                    ? primaryGreen
                    : lightGreen,
                shape:
                BoxShape.circle,
              ),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: isCheapest
                      ? Colors.white
                      : primaryGreen,
                  fontWeight:
                  FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),

            const SizedBox(
              width: 10,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration:
                        BoxDecoration(
                          color: isVerified
                              ? primaryGreen
                              : Colors
                              .orange,
                          shape:
                          BoxShape
                              .circle,
                        ),
                      ),

                      const SizedBox(
                        width: 5,
                      ),

                      Expanded(
                        child: Text(
                          store['premise']
                              ?.toString() ??
                              '',
                          maxLines: 1,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style:
                          const TextStyle(
                            fontSize: 12,
                            fontWeight:
                            FontWeight
                                .bold,
                            color:
                            textColor,
                          ),
                        ),
                      ),

                      if (isCheapest)
                        Container(
                          margin:
                          const EdgeInsets
                              .only(
                            left: 5,
                          ),
                          padding:
                          const EdgeInsets
                              .symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration:
                          BoxDecoration(
                            color:
                            lightGreen,
                            borderRadius:
                            BorderRadius
                                .circular(
                              10,
                            ),
                          ),
                          child:
                          const Text(
                            'BEST',
                            style:
                            TextStyle(
                              color:
                              primaryGreen,
                              fontSize: 8,
                              fontWeight:
                              FontWeight
                                  .bold,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(
                    height: 3,
                  ),

                  Text(
                    '${store['district'] ?? ''}, '
                        '${store['state'] ?? ''}',
                    style:
                    const TextStyle(
                      color:
                      Colors.grey,
                      fontSize: 9,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    store['address']
                        ?.toString() ??
                        '',
                    maxLines: 2,
                    overflow:
                    TextOverflow
                        .ellipsis,
                    style:
                    const TextStyle(
                      color:
                      Colors.black54,
                      fontSize: 8.5,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(
                    height: 3,
                  ),

                  Text(
                    isVerified
                        ? 'Verified location'
                        : 'Location not verified yet',
                    style: TextStyle(
                      color: isVerified
                          ? primaryGreen
                          : Colors.orange,
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              width: 7,
            ),

            Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .end,
              children: [
                Text(
                  'RM ${price.toStringAsFixed(2)}',
                  style:
                  const TextStyle(
                    fontWeight:
                    FontWeight.bold,
                    fontSize: 13,
                    color:
                    primaryGreen,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                InkWell(
                  onTap: () {
                    locateStore(
                      store,
                    );
                  },
                  borderRadius:
                  BorderRadius
                      .circular(
                    30,
                  ),
                  child: Container(
                    width: 35,
                    height: 35,
                    decoration:
                    BoxDecoration(
                      color: isVerified
                          ? lightGreen
                          : const Color(
                        0xFFFFF3E0,
                      ),
                      shape:
                      BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.navigation,
                      size: 18,
                      color: isVerified
                          ? primaryGreen
                          : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
        content: Text(
          message,
        ),
        duration:
        const Duration(
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
      backgroundColor:
      backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                20, 14, 20, 16,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryGreen, darkGreen,
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 22,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'Store Map',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 3),

                  const Text(
                    'Find stores and compare the latest food prices',
                    style: TextStyle(
                      color: Color(0xFFDCEDE6),
                      fontSize: 10,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        flex: 3, child: buildFoodDropdown(),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        flex: 2, child: buildStateDropdown(),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: isLoading
                  ? const Center(
                child:
                CircularProgressIndicator(
                  color:
                  primaryGreen,
                ),
              )
                  : SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding:
                      const EdgeInsets
                          .fromLTRB(
                        14,
                        14,
                        14,
                        0,
                      ),
                      child: Container(
                        height: 300,
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
                        clipBehavior:
                        Clip.antiAlias,
                        child: Stack(
                          children: [
                            FlutterMap(
                              mapController:
                              mapController,
                              options:
                              const MapOptions(
                                initialCenter:
                                LatLng(
                                  4.2105,
                                  101.9758,
                                ),
                                initialZoom:
                                5.5,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName:
                                  'com.example.my67food_price',
                                ),

                                MarkerLayer(
                                  markers:
                                  buildMarkers(),
                                ),

                                const RichAttributionWidget(
                                  attributions: [
                                    TextSourceAttribution(
                                      'OpenStreetMap contributors',
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            buildCheapestBadge(),
                          ],
                        ),
                      ),
                    ),

                    buildSelectedStoreCard(),

                    Padding(
                      padding:
                      const EdgeInsets
                          .fromLTRB(
                        16,
                        18,
                        16,
                        9,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child:
                            Column(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                              children: [
                                const Text(
                                  'Cheapest Stores',
                                  style:
                                  TextStyle(
                                    fontSize:
                                    18,
                                    fontWeight:
                                    FontWeight
                                        .w700,
                                    color:
                                    textColor,
                                  ),
                                ),

                                const SizedBox(
                                  height:
                                  3,
                                ),

                                Text(
                                  getSelectedFoodName(),
                                  maxLines:
                                  1,
                                  overflow:
                                  TextOverflow
                                      .ellipsis,
                                  style:
                                  const TextStyle(
                                    fontSize:
                                    9,
                                    color: Colors
                                        .black45,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Container(
                            padding:
                            const EdgeInsets
                                .symmetric(
                              horizontal:
                              9,
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
                              '${storeList.length}/10 stores',
                              style:
                              const TextStyle(
                                color:
                                primaryGreen,
                                fontSize:
                                9,
                                fontWeight:
                                FontWeight
                                    .w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (storeList.isEmpty)
                      Container(
                        margin:
                        const EdgeInsets
                            .symmetric(
                          horizontal:
                          16,
                        ),
                        width:
                        double.infinity,
                        padding:
                        const EdgeInsets
                            .symmetric(
                          vertical:
                          45,
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
                                  .store_mall_directory_outlined,
                              size: 48,
                              color: Colors
                                  .black26,
                            ),

                            SizedBox(
                              height:
                              10,
                            ),

                            Text(
                              'No store price data found',
                              style:
                              TextStyle(
                                fontWeight:
                                FontWeight
                                    .w600,
                              ),
                            ),

                            SizedBox(
                              height:
                              4,
                            ),

                            Text(
                              'Try another food item or state.',
                              style:
                              TextStyle(
                                color:
                                Colors.black45,
                                fontSize:
                                10,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (storeList.isNotEmpty)
                      Padding(
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal:
                          14,
                        ),
                        child:
                        ListView.builder(
                          shrinkWrap:
                          true,
                          physics:
                          const NeverScrollableScrollPhysics(),
                          itemCount:
                          storeList
                              .length,
                          itemBuilder:
                              (
                              context,
                              index,
                              ) {
                            return buildStoreCard(
                              storeList[
                              index],
                              index,
                            );
                          },
                        ),
                      ),

                    const SizedBox(
                      height: 25,
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
    mapController.dispose();
    super.dispose();
  }
}