import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'food_details_page.dart';

class SavedPage extends StatefulWidget {
  final int initialTab;

  const SavedPage({
    super.key,
    this.initialTab = 0,
  });

  @override
  State<SavedPage> createState() =>
      SavedPageState();
}

class SavedPageState extends State<SavedPage> {
  static const Color primaryGreen = Color(0xFF176B52);
  static const Color darkGreen = Color(0xFF0F513D);
  static const Color backgroundColor = Color(0xFFF6F8F5);
  static const Color lightGreen = Color(0xFFEAF4EF);
  static const Color textColor = Color(0xFF1F2924);

  bool isLoading = true;

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
    });
    loadSavedItems();
  }

  Future<void> loadSavedItems({
    bool showLoading = true,
  }) async {
    final user =
        Supabase.instance.client.auth.currentUser;

    if (user == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        savedItems = [];
        notifications = [];
        isLoading = false;
      });

      return;
    }

    try {
      if (showLoading) {
        setState(() {
          isLoading = true;
        });
      }

      final savedData =
      await Supabase.instance.client
          .from('saved_items')
          .select()
          .eq(
        'user_id',
        user.id,
      )
          .order(
        'created_at',
        ascending: false,
      );

      List<Map<String, dynamic>>
      combinedSavedItems = [];

      List<Map<String, dynamic>>
      generatedNotifications = [];

      for (final saved in savedData) {
        final itemCode =
        int.tryParse(
          saved['item_code'].toString(),
        );

        if (itemCode == null) {
          continue;
        }

        final foodData =
        await Supabase.instance.client
            .from('food_items')
            .select()
            .eq(
          'item_code',
          itemCode,
        )
            .maybeSingle();

        if (foodData == null) {
          continue;
        }

        final priceData =
        await Supabase.instance.client
            .from('food_prices')
            .select(
          'date, price',
        )
            .eq(
          'item_code',
          itemCode,
        )
            .order(
          'date',
          ascending: false,
        );

        double latestAverage = 0;
        double previousAverage = 0;

        String latestDate = '';
        String previousDate = '';

        if (priceData.isNotEmpty) {
          latestDate =
              priceData.first['date']
                  .toString();

          for (final price in priceData) {
            final date =
            price['date'].toString();

            if (date != latestDate) {
              previousDate = date;
              break;
            }
          }

          List<double> latestPrices = [];

          List<double> previousPrices = [];

          for (final price in priceData) {
            final value =
                double.tryParse(
                  price['price']
                      .toString(),
                ) ??
                    0;

            final date =
            price['date'].toString();

            if (date == latestDate) {
              latestPrices.add(value);
            }

            if (previousDate.isNotEmpty &&
                date == previousDate) {
              previousPrices.add(value);
            }
          }

          if (latestPrices.isNotEmpty) {
            double total = 0;

            for (final price
            in latestPrices) {
              total += price;
            }

            latestAverage =
                total /
                    latestPrices.length;
          }

          if (previousPrices.isNotEmpty) {
            double total = 0;

            for (final price
            in previousPrices) {
              total += price;
            }

            previousAverage =
                total /
                    previousPrices.length;
          }
        }

        double changePercentage = 0;

        if (previousAverage != 0) {
          changePercentage =
              ((latestAverage -
                  previousAverage) /
                  previousAverage) *
                  100;
        }

        final item = {
          'saved_id': saved['id'],
          'item_code': itemCode,
          'item':
          foodData['item'] ??
              'Unknown Item',
          'category':
          foodData['item_category'] ??
              '',
          'unit':
          foodData['unit'] ??
              '',
          'alert_enabled':
          saved['alert_enabled'] ??
              true,
          'created_at':
          saved['created_at'],
          'latest_price':
          latestAverage,
          'previous_price':
          previousAverage,
          'change_percentage':
          changePercentage,
          'latest_date':
          latestDate,
        };

        combinedSavedItems.add(item);

        final alertEnabled =
            saved['alert_enabled'] == true;

        if (alertEnabled &&
            changePercentage.abs() >= 5) {
          generatedNotifications.add({
            ...item,
          });
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        savedItems =
            combinedSavedItems;

        notifications =
            generatedNotifications;

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
        'Error loading saved items: $e',
      );
    }
  }

  Future<void> removeSavedItem(
      int savedId,
      ) async {
    try {
      await Supabase.instance.client
          .from('saved_items')
          .delete()
          .eq(
        'id',
        savedId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        savedItems.removeWhere(
              (item) =>
          item['saved_id'] == savedId,
        );

        notifications.removeWhere(
              (item) =>
          item['saved_id'] == savedId,
        );
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
    final currentValue =
        item['alert_enabled'] == true;

    try {
      await Supabase.instance.client
          .from('saved_items')
          .update({
        'alert_enabled':
        !currentValue,
      }).eq(
        'id',
        item['saved_id'],
      );

      showMessage(
        currentValue
            ? 'Price alert turned off.'
            : 'Price alert turned on.',
      );

      await loadSavedItems();
    } catch (e) {
      showMessage(
        'Unable to update price alert.',
      );
    }
  }

  void openFoodComparison(
      Map<String, dynamic> item,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            FoodDetailsPage(
              itemCode:
              item['item_code'],
              itemName:
              item['item'],
              unit:
              item['unit'],
            ),
      ),
    );
  }

  Widget buildTabButton({
    required String title,
    required int index,
  }) {
    final selected =
        selectedTab == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            selectedTab = index;
          });
        },
        borderRadius:
        BorderRadius.circular(12),
        child: Container(
          padding:
          const EdgeInsets.symmetric(
            vertical: 10,
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
          alignment:
          Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : Colors.black54,
              fontSize: 11,
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildSavedItemCard(
      Map<String, dynamic> item,
      ) {
    final price =
    item['latest_price']
    as double;

    final change =
    item['change_percentage']
    as double;

    final alertEnabled =
        item['alert_enabled'] == true;

    final isIncrease =
        change > 0;

    final isDecrease =
        change < 0;

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 11,
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
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              openFoodComparison(
                item,
              );
            },
            borderRadius:
            const BorderRadius
                .only(
              topLeft:
              Radius.circular(
                18,
              ),
              topRight:
              Radius.circular(
                18,
              ),
            ),
            child: Padding(
              padding:
              const EdgeInsets
                  .all(
                13,
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
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
                    child:
                    const Icon(
                      Icons
                          .restaurant_menu,
                      color:
                      primaryGreen,
                      size: 26,
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
                        Text(
                          item['item']
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

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          '${item['category']} • ${item['unit']}',
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

                        const SizedBox(
                          height: 5,
                        ),

                        if (change != 0)
                          Row(
                            children: [
                              Icon(
                                isIncrease
                                    ? Icons
                                    .trending_up
                                    : Icons
                                    .trending_down,
                                size: 13,
                                color: isIncrease
                                    ? Colors.red
                                    : primaryGreen,
                              ),

                              const SizedBox(
                                width: 4,
                              ),

                              Text(
                                '${isIncrease ? '+' : ''}'
                                    '${change.toStringAsFixed(1)}%'
                                    ' from previous price',
                                style:
                                TextStyle(
                                  color: isIncrease
                                      ? Colors.red
                                      : isDecrease
                                      ? primaryGreen
                                      : Colors.grey,
                                  fontSize: 8,
                                  fontWeight:
                                  FontWeight
                                      .w600,
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
                        const TextStyle(
                          fontSize: 15,
                          fontWeight:
                          FontWeight
                              .bold,
                          color:
                          primaryGreen,
                        ),
                      ),

                      const SizedBox(
                        height: 2,
                      ),

                      const Text(
                        'Latest Avg',
                        style:
                        TextStyle(
                          fontSize: 8,
                          color: Colors.black38,
                        ),
                      ),
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
                    padding:
                    const EdgeInsets
                        .symmetric(
                      vertical: 10,
                    ),
                    decoration:
                    const BoxDecoration(
                      color:
                      lightGreen,
                      borderRadius:
                      BorderRadius
                          .only(
                        bottomLeft:
                        Radius
                            .circular(
                          18,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                      children: [
                        Icon(
                          alertEnabled
                              ? Icons
                              .notifications_active_outlined
                              : Icons
                              .notifications_off_outlined,
                          size: 15,
                          color:
                          primaryGreen,
                        ),

                        const SizedBox(
                          width: 5,
                        ),

                        Text(
                          alertEnabled
                              ? 'Alert On'
                              : 'Alert Off',
                          style:
                          const TextStyle(
                            color:
                            primaryGreen,
                            fontSize: 9,
                            fontWeight:
                            FontWeight
                                .w600,
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
                    padding:
                    const EdgeInsets
                        .symmetric(
                      vertical: 10,
                    ),
                    child:
                    const Row(
                      mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                      children: [
                        Icon(
                          Icons
                              .delete_outline,
                          size: 15,
                          color:
                          Colors.red,
                        ),

                        SizedBox(
                          width: 5,
                        ),

                        Text(
                          'Remove',
                          style:
                          TextStyle(
                            color:
                            Colors.red,
                            fontSize: 9,
                            fontWeight:
                            FontWeight
                                .w600,
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

  Widget buildNotificationCard(
      Map<String, dynamic> item,
      ) {
    final change =
    item['change_percentage']
    as double;

    final isIncrease =
        change > 0;

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 10,
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
          color:
          const Color(
            0xFFE3E9E6,
          ),
        ),
      ),
      child: InkWell(
        onTap: () {
          openFoodComparison(
            item,
          );
        },
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration:
              BoxDecoration(
                color: isIncrease
                    ? const Color(
                  0xFFFFEEEE,
                )
                    : lightGreen,
                shape:
                BoxShape.circle,
              ),
              child: Icon(
                isIncrease
                    ? Icons
                    .trending_up
                    : Icons
                    .trending_down,
                color: isIncrease
                    ? Colors.red
                    : primaryGreen,
                size: 18,
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
                  Text(
                    '${item['item']} '
                        '${isIncrease ? 'rose' : 'dropped'} '
                        '${change.abs().toStringAsFixed(1)}%',
                    maxLines: 2,
                    overflow:
                    TextOverflow
                        .ellipsis,
                    style:
                    const TextStyle(
                      fontSize: 11,
                      fontWeight:
                      FontWeight
                          .w700,
                      color:
                      textColor,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    'Latest: ${item['latest_date']}',
                    style:
                    const TextStyle(
                      fontSize: 8,
                      color: Colors
                          .black45,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            Text(
              'RM ${(item['latest_price'] as double).toStringAsFixed(2)}',
              style:
              const TextStyle(
                color:
                primaryGreen,
                fontWeight:
                FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSavedItemsTab() {
    if (savedItems.isEmpty) {
      return Container(
        width: double.infinity,
        padding:
        const EdgeInsets
            .symmetric(
          vertical: 55,
          horizontal: 20,
        ),
        decoration:
        BoxDecoration(
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
        ),
        child:
        const Column(
          children: [
            Icon(
              Icons
                  .favorite_border,
              size: 50,
              color:
              Colors.black26,
            ),

            SizedBox(
              height: 12,
            ),

            Text(
              'No saved food yet',
              style:
              TextStyle(
                fontSize: 15,
                fontWeight:
                FontWeight
                    .w600,
              ),
            ),

            SizedBox(
              height: 5,
            ),

            Text(
              'Tap the heart icon on the Search page to save food.',
              textAlign:
              TextAlign.center,
              style:
              TextStyle(
                fontSize: 10,
                color:
                Colors.black45,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: savedItems
          .map(
            (item) =>
            buildSavedItemCard(
              item,
            ),
      )
          .toList(),
    );
  }

  Widget buildNotificationsTab() {
    return Column(
      children: [
        if (notifications.isEmpty)
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
                      .notifications_none,
                  size: 48,
                  color:
                  Colors.black26,
                ),

                SizedBox(
                  height: 10,
                ),

                Text(
                  'No price alerts',
                  style:
                  TextStyle(
                    fontWeight:
                    FontWeight
                        .w600,
                  ),
                ),

                SizedBox(
                  height: 4,
                ),

                Text(
                  'Notifications appear when a saved food changes by 5% or more.',
                  textAlign:
                  TextAlign
                      .center,
                  style:
                  TextStyle(
                    fontSize: 9,
                    color: Colors
                        .black45,
                  ),
                ),
              ],
            ),
          ),

        if (notifications.isNotEmpty)
          ...notifications.map(
                (item) =>
                buildNotificationCard(
                  item,
                ),
          ),

        const SizedBox(
          height: 12,
        ),

        Container(
          width:
          double.infinity,
          padding:
          const EdgeInsets.all(
            14,
          ),
          decoration:
          BoxDecoration(
            color:
            const Color(
              0xFFFFF6E8,
            ),
            borderRadius:
            BorderRadius
                .circular(
              16,
            ),
            border: Border.all(
              color:
              Colors.orange,
            ),
          ),
          child:
          const Row(
            crossAxisAlignment:
            CrossAxisAlignment
                .start,
            children: [
              Icon(
                Icons
                    .notifications_active_outlined,
                size: 18,
                color:
                Colors.orange,
              ),

              SizedBox(
                width: 8,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      'Price Alert Active',
                      style:
                      TextStyle(
                        color:
                        Colors.orange,
                        fontWeight:
                        FontWeight
                            .bold,
                        fontSize: 11,
                      ),
                    ),

                    SizedBox(
                      height: 4,
                    ),

                    Text(
                      'You will see an alert when a saved food price changes by 5% or more.',
                      style:
                      TextStyle(
                        fontSize: 9,
                        color:
                        Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
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
        content:
        Text(message),
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
              width:
              double.infinity,
              padding:
              const EdgeInsets
                  .fromLTRB(
                18,
                16,
                18,
                15,
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
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons
                            .favorite,
                        color:
                        Colors.white,
                        size: 23,
                      ),

                      SizedBox(
                        width: 7,
                      ),

                      Text(
                        'Favourites',
                        style:
                        TextStyle(
                          color:
                          Colors.white,
                          fontSize: 22,
                          fontWeight:
                          FontWeight
                              .bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    '${savedItems.length} saved item(s)',
                    style:
                    const TextStyle(
                      color: Color(
                        0xFFDCEDE6,
                      ),
                      fontSize: 10,
                    ),
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  Container(
                    padding:
                    const EdgeInsets
                        .all(
                      4,
                    ),
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
                        14,
                      ),
                    ),
                    child: Row(
                      children: [
                        buildTabButton(
                          title:
                          'Saved Items',
                          index: 0,
                        ),

                        buildTabButton(
                          title:
                          'Notifications',
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
                color:
                primaryGreen,
                onRefresh:
                loadSavedItems,
                child:
                SingleChildScrollView(
                  physics:
                  const AlwaysScrollableScrollPhysics(),
                  padding:
                  const EdgeInsets
                      .fromLTRB(
                    16,
                    16,
                    16,
                    25,
                  ),
                  child: isLoading
                      ? const Padding(
                    padding:
                    EdgeInsets
                        .all(
                      50,
                    ),
                    child:
                    Center(
                      child:
                      CircularProgressIndicator(
                        color:
                        primaryGreen,
                      ),
                    ),
                  )
                      : selectedTab ==
                      0
                      ? buildSavedItemsTab()
                      : buildNotificationsTab(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}