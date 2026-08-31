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
  Color(0xFFF5F7F4);

  static const Color lightGreen =
  Color(0xFFE8F3EE);

  static const Color softGreen =
  Color(0xFFF1F8F5);

  static const Color textColor =
  Color(0xFF1D2923);

  static const Color secondaryText =
  Color(0xFF6B756F);

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

  Future<bool> getDefaultSavedItemAlert() async {
    final user =
        Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return true;
    }

    try {
      final profileData =
      await Supabase.instance.client
          .from('profiles')
          .select('saved_item_alert')
          .eq(
        'id',
        user.id,
      )
          .maybeSingle();

      if (profileData == null) {
        return true;
      }

      return profileData['saved_item_alert'] ==
          true;
    } catch (e) {
      return true;
    }
  }

  Future<void> checkSavedItem() async {
    final user =
        Supabase.instance.client.auth.currentUser;

    if (user == null) {
      setState(() {
        isSaved = false;
      });

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

      setState(() {
        isSaved = data != null;
      });
    } catch (e) {
      setState(() {
        isSaved = false;
      });
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

    setState(() {
      isSaving = true;
    });

    try {
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

        setState(() {
          isSaved = false;
        });

        showMessage(
          'Removed from favourites.',
        );
      } else {
        final defaultAlert =
        await getDefaultSavedItemAlert();

        await Supabase.instance.client
            .from('saved_items')
            .insert({
          'user_id': user.id,
          'item_code': widget.itemCode,
          'alert_enabled': defaultAlert,
        });

        setState(() {
          isSaved = true;
        });

        showMessage(
          'Added to favourites.',
        );
      }
    } catch (e) {
      showMessage(
        'Unable to update favourite.',
      );
    }

    setState(() {
      isSaving = false;
    });
  }

  Future<void> fetchComparisonData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final foodData =
      await Supabase.instance.client
          .from('food_items')
          .select(
        'item_code, item, item_category, unit',
      )
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
        setState(() {
          comparisonList = [];
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
          .select(
        'item_code, premise_code, date, price',
      )
          .eq(
        'item_code',
        widget.itemCode,
      )
          .eq(
        'date',
        newestDate,
      );

      if (priceData.isEmpty) {
        setState(() {
          comparisonList = [];
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
          .where(
            (code) => code != null,
      )
          .toSet()
          .toList();

      if (premiseCodes.isEmpty) {
        setState(() {
          comparisonList = [];
          isLoading = false;
        });

        return;
      }

      final premiseData =
      await Supabase.instance.client
          .from('premises')
          .select(
        'premise_code, premise, state, district',
      )
          .inFilter(
        'premise_code',
        premiseCodes,
      );

      final premiseList =
      List<Map<String, dynamic>>.from(
        premiseData,
      );

      final Map<dynamic,
          Map<String, dynamic>>
      premiseMap = {};

      for (final premise in premiseList) {
        premiseMap[
        premise['premise_code']] =
            premise;
      }

      List<Map<String, dynamic>>
      latestStorePrices = [];

      for (final price in priceData) {
        final premise =
        premiseMap[
        price['premise_code']];

        latestStorePrices.add({
          'date': price['date'],
          'price': price['price'],
          'premise_code':
          price['premise_code'],
          'premise':
          premise?['premise'] ??
              'Unknown Premise',
          'state':
          premise?['state'] ?? '',
          'district':
          premise?['district'] ?? '',
        });
      }

      latestStorePrices.sort(
            (a, b) {
          final priceA =
              double.tryParse(
                a['price'].toString(),
              ) ??
                  0;

          final priceB =
              double.tryParse(
                b['price'].toString(),
              ) ??
                  0;

          return priceA.compareTo(
            priceB,
          );
        },
      );

      final priceValues =
      latestStorePrices
          .map(
            (item) =>
        double.tryParse(
          item['price']
              .toString(),
        ) ??
            0,
      )
          .toList();

      if (priceValues.isEmpty) {
        setState(() {
          comparisonList = [];
          isLoading = false;
        });

        return;
      }

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
              .where(
                (code) => code != null,
          )
              .toSet()
              .length;

      setState(() {
        comparisonList =
            latestStorePrices;

        lowestPrice = lowest;

        highestPrice = highest;

        averagePrice = average;

        latestDate = newestDate;

        totalStores = storeCount;

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        comparisonList = [];
        isLoading = false;
      });

      showMessage(
        'Unable to load food details.',
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
        duration:
        const Duration(
          seconds: 2,
        ),
      ),
    );
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
    required String subtitle,
  }) {
    return Expanded(
      child: Container(
        padding:
        const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(
            18,
          ),
          border: Border.all(
            color:
            const Color(
              0xFFE3E9E6,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color:
              Colors.black.withValues(
                alpha: 0.025,
              ),
              blurRadius: 10,
              offset:
              const Offset(
                0,
                4,
              ),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration:
              const BoxDecoration(
                color:
                lightGreen,
                shape:
                BoxShape.circle,
              ),
              child: Icon(
                icon,
                color:
                primaryGreen,
                size: 18,
              ),
            ),
            const SizedBox(
              height: 9,
            ),
            Text(
              title,
              style:
              const TextStyle(
                fontSize: 10,
                color:
                secondaryText,
                fontWeight:
                FontWeight.w500,
              ),
            ),
            const SizedBox(
              height: 3,
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
            const SizedBox(
              height: 2,
            ),
            Text(
              subtitle,
              style:
              const TextStyle(
                fontSize: 8,
                color:
                Colors.black38,
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
        double.tryParse(
          store['price'].toString(),
        ) ??
            0;

    final isCheapest =
        index == 0;

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 11,
      ),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        border:
        Border.all(
          color: isCheapest
              ? primaryGreen
              : const Color(
            0xFFE2E8E5,
          ),
          width: isCheapest
              ? 1.3
              : 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withValues(
              alpha: 0.025,
            ),
            blurRadius: 10,
            offset:
            const Offset(
              0,
              4,
            ),
          ),
        ],
      ),
      child: Padding(
        padding:
        const EdgeInsets.all(
          13,
        ),
        child: Row(
          children: [
            Container(
              width: 47,
              height: 47,
              decoration:
              BoxDecoration(
                color: isCheapest
                    ? primaryGreen
                    : lightGreen,
                borderRadius:
                BorderRadius.circular(
                  14,
                ),
              ),
              alignment:
              Alignment.center,
              child: Text(
                '${index + 1}',
                style:
                TextStyle(
                  color: isCheapest
                      ? Colors.white
                      : primaryGreen,
                  fontSize: 16,
                  fontWeight:
                  FontWeight.bold,
                ),
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
                            left: 6,
                          ),
                          padding:
                          const EdgeInsets
                              .symmetric(
                            horizontal:
                            8,
                            vertical:
                            4,
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
                          child:
                          const Text(
                            'BEST',
                            style:
                            TextStyle(
                              fontSize:
                              8,
                              color:
                              primaryGreen,
                              fontWeight:
                              FontWeight
                                  .bold,
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
                            Colors
                                .black45,
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
              CrossAxisAlignment
                  .end,
              children: [
                Text(
                  'RM ${price.toStringAsFixed(2)}',
                  style:
                  TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.bold,
                    color: isCheapest
                        ? primaryGreen
                        : textColor,
                  ),
                ),
                const SizedBox(
                  height: 2,
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
        elevation: 0,
        backgroundColor:
        backgroundColor,
        foregroundColor:
        textColor,
        title:
        const Text(
          'Food Details',
          style:
          TextStyle(
            fontWeight:
            FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding:
            const EdgeInsets.only(
              right: 10,
            ),
            child: isSaving
                ? const Padding(
              padding:
              EdgeInsets.all(
                12,
              ),
              child:
              SizedBox(
                width: 22,
                height: 22,
                child:
                CircularProgressIndicator(
                  strokeWidth:
                  2,
                  color:
                  primaryGreen,
                ),
              ),
            )
                : Container(
              margin:
              const EdgeInsets
                  .all(
                6,
              ),
              decoration:
              BoxDecoration(
                color:
                Colors.white,
                shape:
                BoxShape.circle,
                border:
                Border.all(
                  color:
                  const Color(
                    0xFFE2E8E5,
                  ),
                ),
              ),
              child:
              IconButton(
                onPressed:
                toggleSavedItem,
                icon:
                Icon(
                  isSaved
                      ? Icons
                      .favorite
                      : Icons
                      .favorite_border,
                  color: isSaved
                      ? Colors
                      .redAccent
                      : primaryGreen,
                ),
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: primaryGreen,
        ),
      )
          : comparisonList.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: lightGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 34,
                color: primaryGreen,
              ),
            ),
            const SizedBox(
              height: 14,
            ),
            const Text(
              'No food price data found',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      )
          : CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              16,
              6,
              16,
              0,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(
                      20,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryGreen,
                          darkGreen,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(
                        24,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryGreen.withValues(
                            alpha: 0.16,
                          ),
                          blurRadius: 18,
                          offset: const Offset(
                            0,
                            7,
                          ),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding:
                              const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white
                                    .withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius:
                                BorderRadius.circular(
                                  20,
                                ),
                              ),
                              child: Text(
                                category,
                                style:
                                const TextStyle(
                                  color:
                                  Colors.white,
                                  fontSize: 9,
                                  fontWeight:
                                  FontWeight
                                      .w600,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              width: 45,
                              height: 45,
                              decoration:
                              BoxDecoration(
                                color: Colors.white
                                    .withValues(
                                  alpha: 0.13,
                                ),
                                borderRadius:
                                BorderRadius
                                    .circular(
                                  14,
                                ),
                              ),
                              child:
                              const Icon(
                                Icons
                                    .restaurant_menu_rounded,
                                color:
                                Colors.white,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 17,
                        ),
                        Text(
                          widget.itemName,
                          style:
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            height: 1.2,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 7,
                        ),
                        Text(
                          'Price comparison per ${widget.unit}',
                          style:
                          const TextStyle(
                            color: Color(
                              0xFFDCEDE6,
                            ),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(
                          height: 18,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding:
                                const EdgeInsets
                                    .all(
                                  11,
                                ),
                                decoration:
                                BoxDecoration(
                                  color: Colors
                                      .white
                                      .withValues(
                                    alpha:
                                    0.11,
                                  ),
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                    14,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons
                                          .calendar_today_outlined,
                                      size: 15,
                                      color:
                                      Colors
                                          .white70,
                                    ),
                                    const SizedBox(
                                      width: 6,
                                    ),
                                    Expanded(
                                      child:
                                      Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          const Text(
                                            'Updated',
                                            style:
                                            TextStyle(
                                              fontSize:
                                              8,
                                              color:
                                              Colors.white60,
                                            ),
                                          ),
                                          Text(
                                            latestDate,
                                            style:
                                            const TextStyle(
                                              fontSize:
                                              10,
                                              fontWeight:
                                              FontWeight.w600,
                                              color:
                                              Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 9,
                            ),
                            Expanded(
                              child: Container(
                                padding:
                                const EdgeInsets
                                    .all(
                                  11,
                                ),
                                decoration:
                                BoxDecoration(
                                  color: Colors
                                      .white
                                      .withValues(
                                    alpha:
                                    0.11,
                                  ),
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                    14,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons
                                          .store_outlined,
                                      size: 16,
                                      color:
                                      Colors
                                          .white70,
                                    ),
                                    const SizedBox(
                                      width: 6,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                      children: [
                                        const Text(
                                          'Available at',
                                          style:
                                          TextStyle(
                                            fontSize:
                                            8,
                                            color:
                                            Colors.white60,
                                          ),
                                        ),
                                        Text(
                                          '$totalStores stores',
                                          style:
                                          const TextStyle(
                                            fontSize:
                                            10,
                                            fontWeight:
                                            FontWeight.w600,
                                            color:
                                            Colors.white,
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
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  const Text(
                    'Price Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                      FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  const Text(
                    'Compare the latest prices from available stores',
                    style: TextStyle(
                      fontSize: 10,
                      color: secondaryText,
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  Row(
                    children: [
                      priceSummary(
                        title: 'Lowest',
                        price: lowestPrice,
                        icon:
                        Icons.south_rounded,
                        subtitle:
                        'Best deal',
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      priceSummary(
                        title: 'Average',
                        price:
                        averagePrice,
                        icon: Icons
                            .horizontal_rule_rounded,
                        subtitle:
                        'Typical',
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      priceSummary(
                        title: 'Highest',
                        price:
                        highestPrice,
                        icon:
                        Icons.north_rounded,
                        subtitle:
                        'Top range',
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  Container(
                    width:
                    double.infinity,
                    padding:
                    const EdgeInsets.all(
                      17,
                    ),
                    decoration:
                    BoxDecoration(
                      color:
                      primaryGreen,
                      borderRadius:
                      BorderRadius
                          .circular(
                        20,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration:
                          BoxDecoration(
                            color: Colors
                                .white
                                .withValues(
                              alpha:
                              0.15,
                            ),
                            borderRadius:
                            BorderRadius
                                .circular(
                              15,
                            ),
                          ),
                          child:
                          const Icon(
                            Icons
                                .local_offer_outlined,
                            color:
                            Colors.white,
                            size: 25,
                          ),
                        ),
                        const SizedBox(
                          width: 13,
                        ),
                        Expanded(
                          child:
                          Column(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                            children: [
                              const Text(
                                'Best Price Available',
                                style:
                                TextStyle(
                                  color:
                                  Colors.white70,
                                  fontSize:
                                  9,
                                ),
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                comparisonList
                                    .first[
                                'premise']
                                    .toString(),
                                maxLines: 2,
                                overflow:
                                TextOverflow
                                    .ellipsis,
                                style:
                                const TextStyle(
                                  color:
                                  Colors.white,
                                  fontSize:
                                  12,
                                  fontWeight:
                                  FontWeight
                                      .w700,
                                ),
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                '${comparisonList.first['district']}, ${comparisonList.first['state']}',
                                style:
                                const TextStyle(
                                  fontSize:
                                  9,
                                  color:
                                  Colors.white60,
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
                            const Text(
                              'LOWEST',
                              style:
                              TextStyle(
                                color:
                                Colors.white60,
                                fontSize:
                                8,
                                fontWeight:
                                FontWeight
                                    .bold,
                              ),
                            ),
                            const SizedBox(
                              height: 2,
                            ),
                            Text(
                              'RM ${lowestPrice.toStringAsFixed(2)}',
                              style:
                              const TextStyle(
                                color:
                                Colors.white,
                                fontSize:
                                18,
                                fontWeight:
                                FontWeight
                                    .bold,
                              ),
                            ),
                            Text(
                              'per ${widget.unit}',
                              style:
                              const TextStyle(
                                color:
                                Colors.white60,
                                fontSize:
                                8,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 25,
                  ),
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                          children: [
                            Text(
                              'Store Comparison',
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
                            SizedBox(
                              height: 3,
                            ),
                            Text(
                              'Ranked from lowest price',
                              style:
                              TextStyle(
                                fontSize:
                                10,
                                color:
                                secondaryText,
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
                          10,
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
                          '$totalStores stores',
                          style:
                          const TextStyle(
                            fontSize: 9,
                            fontWeight:
                            FontWeight
                                .w600,
                            color:
                            primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              16,
              0,
              16,
              30,
            ),
            sliver: SliverList(
              delegate:
              SliverChildBuilderDelegate(
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
                childCount:
                comparisonList.length >
                    10
                    ? 10
                    : comparisonList
                    .length,
              ),
            ),
          ),
        ],
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
        selectedFontSize:
        11,
        unselectedFontSize:
        10,
        elevation: 8,
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
              Icons.home_rounded,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.search_rounded,
            ),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.map_outlined,
            ),
            activeIcon: Icon(
              Icons.map_rounded,
            ),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.show_chart_rounded,
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