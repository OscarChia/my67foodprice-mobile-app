import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/main_navigation_page.dart';

class FoodDetailsPage extends StatefulWidget {
  final int itemCode;
  final String itemName;
  final String unit;

  const FoodDetailsPage({
    super.key,
    required this.itemCode,
    required this.itemName,
    required this.unit,
  });

  @override
  State<FoodDetailsPage> createState() =>
      _FoodDetailsPageState();
}

class _FoodDetailsPageState
    extends State<FoodDetailsPage> {
  static const Color primaryGreen =
  Color(0xFF176B52);

  static const Color darkGreen =
  Color(0xFF0F513D);

  static const Color backgroundColor =
  Color(0xFFF6F8F5);

  static const Color lightGreen =
  Color(0xFFEAF4EF);

  static const Color textColor =
  Color(0xFF1F2924);

  bool isLoading = true;

  bool isSaved = false;

  bool isSaving = false;

  List<Map<String, dynamic>> comparisonList = [];

  double lowestPrice = 0;

  double highestPrice = 0;

  double averagePrice = 0;

  String category = '';

  String latestDate = '';

  int totalStores = 0;

  @override
  void initState() {
    super.initState();

    fetchComparisonData();

    checkSavedItem();
  }

  Future<void> checkSavedItem() async {
    final user =
        Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      final data =
      await Supabase.instance.client
          .from('saved_items')
          .select('id')
          .eq(
        'user_id',
        user.id,
      )
          .eq(
        'item_code',
        widget.itemCode,
      )
          .maybeSingle();

      if (!mounted) {
        return;
      }

      setState(() {
        isSaved = data != null;
      });
    } catch (e) {
      debugPrint(
        'Error checking favourite: $e',
      );
    }
  }

  Future<void> toggleSavedItem() async {
    if (isSaving) {
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

    try {
      setState(() {
        isSaving = true;
      });

      if (isSaved) {
        await Supabase.instance.client
            .from('saved_items')
            .delete()
            .eq(
          'user_id',
          user.id,
        )
            .eq(
          'item_code',
          widget.itemCode,
        );

        if (!mounted) {
          return;
        }

        setState(() {
          isSaved = false;
        });

        showMessage(
          'Removed from favourites.',
        );
      } else {
        await Supabase.instance.client
            .from('saved_items')
            .insert({
          'user_id': user.id,
          'item_code': widget.itemCode,
          'alert_enabled': true,
        });

        if (!mounted) {
          return;
        }

        setState(() {
          isSaved = true;
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
          isSaving = false;
        });
      }
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
        content: Text(
          message,
        ),
        duration: const Duration(
          seconds: 2,
        ),
      ),
    );
  }

  Future<void> fetchComparisonData() async {
    try {
      final foodData =
      await Supabase.instance.client
          .from('food_items')
          .select()
          .eq(
        'item_code',
        widget.itemCode,
      )
          .maybeSingle();

      if (foodData != null) {
        category =
            foodData['item_category']
                ?.toString() ??
                '';
      }

      final latestPriceData =
      await Supabase.instance.client
          .from('food_prices')
          .select('date')
          .eq(
        'item_code',
        widget.itemCode,
      )
          .order(
        'date',
        ascending: false,
      )
          .limit(1);

      if (latestPriceData.isEmpty) {
        if (!mounted) {
          return;
        }

        setState(() {
          isLoading = false;
        });

        return;
      }

      final newestDate =
      latestPriceData.first['date']
          .toString();

      final priceData =
      await Supabase.instance.client
          .from('food_prices')
          .select()
          .eq(
        'item_code',
        widget.itemCode,
      )
          .eq(
        'date',
        newestDate,
      );

      if (priceData.isEmpty) {
        if (!mounted) {
          return;
        }

        setState(() {
          isLoading = false;
        });

        return;
      }

      final premiseCodes =
      priceData
          .map(
            (price) =>
        price['premise_code'],
      )
          .toSet()
          .toList();

      final premiseData =
      await Supabase.instance.client
          .from('premises')
          .select()
          .inFilter(
        'premise_code',
        premiseCodes,
      );

      final premiseList =
      List<Map<String, dynamic>>.from(
        premiseData,
      );

      List<Map<String, dynamic>>
      latestStorePrices = [];

      for (final price in priceData) {
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

        latestStorePrices.add({
          'date': price['date'],
          'price': price['price'],
          'premise_code':
          price['premise_code'],
          'premise':
          premise['premise'],
          'state':
          premise['state'],
          'district':
          premise['district'],
        });
      }

      latestStorePrices.sort(
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

      final priceValues =
      latestStorePrices.map(
            (item) {
          return double.parse(
            item['price'].toString(),
          );
        },
      ).toList();

      final lowest =
          priceValues.first;

      final highest =
          priceValues.last;

      double total = 0;

      for (final price in priceValues) {
        total += price;
      }

      final average =
          total / priceValues.length;

      final storeCount =
          latestStorePrices
              .map(
                (item) =>
            item['premise_code'],
          )
              .toSet()
              .length;

      if (!mounted) {
        return;
      }

      setState(() {
        comparisonList =
            latestStorePrices;

        lowestPrice =
            lowest;

        highestPrice =
            highest;

        averagePrice =
            average;

        latestDate =
            newestDate;

        totalStores =
            storeCount;

        isLoading =
        false;
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

  void goToMainPage(
      int index,
      ) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MainNavigationPage(
              initialIndex: index,
            ),
      ),
          (route) => false,
    );
  }

  Widget priceSummary({
    required String title,
    required double price,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding:
        const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 5,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(
            16,
          ),
          border: Border.all(
            color: const Color(
              0xFFE3E9E6,
            ),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: primaryGreen,
              size: 20,
            ),
            const SizedBox(
              height: 7,
            ),
            Text(
              title,
              style:
              const TextStyle(
                fontSize: 10,
                color:
                Colors.black54,
              ),
            ),
            const SizedBox(
              height: 4,
            ),
            Text(
              'RM ${price.toStringAsFixed(2)}',
              style:
              const TextStyle(
                fontSize: 15,
                fontWeight:
                FontWeight.bold,
                color:
                textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget storeCard(
      Map<String, dynamic> store,
      int index,
      ) {
    final price =
    double.parse(
      store['price'].toString(),
    );

    final bool isCheapest =
        index == 0;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.all(
        13,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          17,
        ),
        border: Border.all(
          color: isCheapest
              ? primaryGreen
              : const Color(
            0xFFE3E9E6,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius:
              BorderRadius.circular(
                13,
              ),
            ),
            alignment:
            Alignment.center,
            child: Text(
              '${index + 1}',
              style:
              const TextStyle(
                fontWeight:
                FontWeight.bold,
                color:
                primaryGreen,
              ),
            ),
          ),

          const SizedBox(
            width: 11,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        store['premise']
                            .toString(),
                        maxLines: 2,
                        overflow:
                        TextOverflow
                            .ellipsis,
                        style:
                        const TextStyle(
                          fontSize: 12,
                          fontWeight:
                          FontWeight
                              .w700,
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
                          horizontal:
                          7,
                          vertical:
                          3,
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
                            fontSize: 8,
                            fontWeight:
                            FontWeight
                                .bold,
                            color:
                            primaryGreen,
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
                      Icons
                          .location_on_outlined,
                      size: 13,
                      color:
                      Colors.black45,
                    ),
                    const SizedBox(
                      width: 3,
                    ),
                    Expanded(
                      child: Text(
                        '${store['district']}, ${store['state']}',
                        maxLines: 1,
                        overflow:
                        TextOverflow
                            .ellipsis,
                        style:
                        const TextStyle(
                          fontSize: 9,
                          color:
                          Colors.black45,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          Column(
            crossAxisAlignment:
            CrossAxisAlignment.end,
            children: [
              Text(
                'RM ${price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                  FontWeight.bold,
                  color: isCheapest
                      ? primaryGreen
                      : textColor,
                ),
              ),
              const SizedBox(
                height: 3,
              ),
              Text(
                'per ${widget.unit}',
                style:
                const TextStyle(
                  fontSize: 8,
                  color:
                  Colors.black45,
                ),
              ),
            ],
          ),
        ],
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

      appBar: AppBar(
        title: const Text(
          'Food Details',
        ),
        backgroundColor:
        Colors.white,
        foregroundColor:
        textColor,
        elevation: 0,

        actions: [
          if (isSaving)
            const Padding(
              padding:
              EdgeInsets.all(
                14,
              ),
              child: SizedBox(
                width: 22,
                height: 22,
                child:
                CircularProgressIndicator(
                  strokeWidth: 2,
                  color:
                  primaryGreen,
                ),
              ),
            )
          else
            IconButton(
              onPressed:
              toggleSavedItem,
              icon: Icon(
                isSaved
                    ? Icons.favorite
                    : Icons
                    .favorite_border,
                color: isSaved
                    ? Colors.redAccent
                    : textColor,
              ),
            ),
        ],
      ),

      body: isLoading
          ? const Center(
        child:
        CircularProgressIndicator(
          color:
          primaryGreen,
        ),
      )
          : comparisonList.isEmpty
          ? const Center(
        child: Text(
          'No food price data found',
        ),
      )
          : SingleChildScrollView(
        padding:
        const EdgeInsets
            .fromLTRB(
          16,
          10,
          16,
          25,
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment
              .start,
          children: [
            Container(
              width:
              double.infinity,
              padding:
              const EdgeInsets
                  .all(
                19,
              ),
              decoration:
              BoxDecoration(
                gradient:
                const LinearGradient(
                  begin:
                  Alignment
                      .topLeft,
                  end:
                  Alignment
                      .bottomRight,
                  colors: [
                    primaryGreen,
                    darkGreen,
                  ],
                ),
                borderRadius:
                BorderRadius
                    .circular(
                  22,
                ),
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  Container(
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal:
                      10,
                      vertical:
                      5,
                    ),
                    decoration:
                    BoxDecoration(
                      color: Colors
                          .white
                          .withValues(
                        alpha:
                        0.16,
                      ),
                      borderRadius:
                      BorderRadius
                          .circular(
                        15,
                      ),
                    ),
                    child: Text(
                      category,
                      style:
                      const TextStyle(
                        color:
                        Colors.white,
                        fontSize:
                        10,
                        fontWeight:
                        FontWeight
                            .w600,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  Text(
                    widget.itemName,
                    style:
                    const TextStyle(
                      color:
                      Colors.white,
                      fontSize:
                      22,
                      fontWeight:
                      FontWeight
                          .bold,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    'Unit: ${widget.unit}',
                    style:
                    const TextStyle(
                      color: Color(
                        0xFFDCEDE6,
                      ),
                      fontSize:
                      11,
                    ),
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  Row(
                    children: [
                      const Icon(
                        Icons
                            .calendar_today_outlined,
                        size:
                        14,
                        color:
                        Colors.white70,
                      ),

                      const SizedBox(
                        width:
                        5,
                      ),

                      Text(
                        'Latest Price: $latestDate',
                        style:
                        const TextStyle(
                          color:
                          Colors.white70,
                          fontSize:
                          10,
                        ),
                      ),

                      const SizedBox(
                        width:
                        15,
                      ),

                      const Icon(
                        Icons
                            .store_outlined,
                        size:
                        14,
                        color:
                        Colors.white70,
                      ),

                      const SizedBox(
                        width:
                        5,
                      ),

                      Text(
                        '$totalStores stores',
                        style:
                        const TextStyle(
                          color:
                          Colors.white70,
                          fontSize:
                          10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 22,
            ),

            const Text(
              'Latest Price Summary',
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
              height: 10,
            ),

            Row(
              children: [
                priceSummary(
                  title:
                  'Lowest',
                  price:
                  lowestPrice,
                  icon: Icons
                      .arrow_downward,
                ),

                const SizedBox(
                  width: 8,
                ),

                priceSummary(
                  title:
                  'Average',
                  price:
                  averagePrice,
                  icon:
                  Icons.remove,
                ),

                const SizedBox(
                  width: 8,
                ),

                priceSummary(
                  title:
                  'Highest',
                  price:
                  highestPrice,
                  icon: Icons
                      .arrow_upward,
                ),
              ],
            ),

            const SizedBox(
              height: 22,
            ),

            const Text(
              'Best Price',
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
              height: 10,
            ),

            Container(
              width:
              double.infinity,
              padding:
              const EdgeInsets
                  .all(
                16,
              ),
              decoration:
              BoxDecoration(
                color:
                lightGreen,
                borderRadius:
                BorderRadius
                    .circular(
                  18,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration:
                    BoxDecoration(
                      color:
                      Colors.white,
                      borderRadius:
                      BorderRadius
                          .circular(
                        14,
                      ),
                    ),
                    child:
                    const Icon(
                      Icons
                          .store_outlined,
                      color:
                      primaryGreen,
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        Text(
                          comparisonList
                              .first[
                          'premise']
                              .toString(),
                          maxLines:
                          2,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style:
                          const TextStyle(
                            fontSize:
                            12,
                            fontWeight:
                            FontWeight
                                .w700,
                            color:
                            textColor,
                          ),
                        ),

                        const SizedBox(
                          height:
                          4,
                        ),

                        Text(
                          '${comparisonList.first['district']}, ${comparisonList.first['state']}',
                          style:
                          const TextStyle(
                            fontSize:
                            9,
                            color:
                            Colors
                                .black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  Text(
                    'RM ${lowestPrice.toStringAsFixed(2)}',
                    style:
                    const TextStyle(
                      fontSize:
                      17,
                      fontWeight:
                      FontWeight
                          .bold,
                      color:
                      primaryGreen,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 22,
            ),

            Row(
              children: [
                const Text(
                  'Latest Prices by Store',
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

                const Spacer(),

                Text(
                  '$totalStores store(s)',
                  style:
                  const TextStyle(
                    fontSize:
                    10,
                    color:
                    Colors.black45,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 10,
            ),

            ListView.builder(
              shrinkWrap: true,
              physics:
              const NeverScrollableScrollPhysics(),
              itemCount:
              comparisonList
                  .length >
                  10
                  ? 10
                  : comparisonList
                  .length,
              itemBuilder:
                  (
                  context,
                  index,
                  ) {
                return storeCard(
                  comparisonList[
                  index],
                  index,
                );
              },
            ),
          ],
        ),
      ),

      bottomNavigationBar:
      BottomNavigationBar(
        type:
        BottomNavigationBarType
            .fixed,

        currentIndex: 1,

        backgroundColor:
        Colors.white,

        selectedItemColor:
        primaryGreen,

        unselectedItemColor:
        Colors.grey,

        selectedFontSize: 11,

        unselectedFontSize: 10,

        onTap: (index) {
          goToMainPage(
            index,
          );
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home_outlined,
            ),
            activeIcon: Icon(
              Icons.home,
            ),
            label: 'Home',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.search,
            ),
            label: 'Search',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.map_outlined,
            ),
            activeIcon: Icon(
              Icons.map,
            ),
            label: 'Map',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.show_chart,
            ),
            label: 'Trend',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.favorite_border,
            ),
            activeIcon: Icon(
              Icons.favorite,
            ),
            label: 'Saved',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.person_outline,
            ),
            activeIcon: Icon(
              Icons.person,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}