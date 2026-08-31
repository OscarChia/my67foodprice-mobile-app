import 'dart:math';
import 'package:flutter/material.dart';
import '../services/database_service.dart';

class TrendPage extends StatefulWidget {
  const TrendPage({super.key});

  @override
  State<TrendPage> createState() => _TrendPageState();
}

class _TrendPageState extends State<TrendPage> {
  static const Color primaryGreen = Color(0xFF176B52);
  static const Color darkGreen = Color(0xFF0F513D);
  static const Color backgroundColor = Color(0xFFF6F8F5);
  static const Color lightGreen = Color(0xFFEAF4EF);
  static const Color textColor = Color(0xFF1F2924);

  final DatabaseService databaseService = DatabaseService();

  bool isLoading = true;
  bool isMonthlyLoading = false;

  int? selectedItemCode;
  int? selectedPointIndex;

  String selectedPeriod = 'Daily';

  List<Map<String, dynamic>> foodItems = [];
  List<Map<String, dynamic>> trendData = [];
  List<Map<String, dynamic>> monthlyItems = [];

  final List<String> periods = [
    'Daily',
    'Weekly',
    'Monthly',
  ];

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    await loadFoodItemsWithPrices();
  }

  Future<void>
  loadFoodItemsWithPrices() async {
    try {
      setState(() {
        isLoading = true;
      });

      final allFoodItems =
      await databaseService
          .getTrendFoodItems();

      if (allFoodItems.isEmpty) {
        setState(() {
          foodItems = [];
          trendData = [];
          monthlyItems = [];
          selectedItemCode = null;
          isLoading = false;
        });

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
        await loadTrendData();
        await loadMonthlyItems();
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      showMessage(
        'Error loading food items: $e',
      );
    }
  }

  Future<void> loadTrendData() async {
    if (selectedItemCode == null) {
      return;
    }

    try {
      setState(() {
        isLoading = true;
        selectedPointIndex = null;
      });

      List<Map<String, dynamic>> result;

      if (selectedPeriod == 'Daily') {
        result =
        await loadDailyTrend();
      } else if (
      selectedPeriod == 'Weekly') {
        result =
        await loadWeeklyTrend();
      } else {
        result =
        await loadMonthlyTrend();
      }

      setState(() {
        trendData = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      showMessage(
        'Error loading trend: $e',
      );
    }
  }

  Future<List<Map<String, dynamic>>>
  loadDailyTrend() async {
    final data =
    await databaseService
        .getDailyTrend(
      selectedItemCode!,
    );

    final rows =
    data.reversed.toList();

    final List<Map<String, dynamic>>
    result = [];

    for (final row in rows) {
      final date =
      DateTime.tryParse(
        row['date'].toString(),
      );

      final price =
      double.tryParse(
        row['avg_price'].toString(),
      );

      if (date == null ||
          price == null) {
        continue;
      }

      result.add({
        'date':
        row['date'],

        'label':
        '${monthName(date.month)} ${date.day}',

        'price':
        price,
      });
    }

    return result;
  }

  Future<List<Map<String, dynamic>>>
  loadWeeklyTrend() async {
    final rows =
    await databaseService
        .getWeeklyTrend(
      selectedItemCode!,
    );

    final List<Map<String, dynamic>>
    result = [];

    for (final row in rows) {
      final startDate =
      DateTime.tryParse(
        row['start_date'].toString(),
      );

      final endDate =
      DateTime.tryParse(
        row['end_date'].toString(),
      );

      final price =
      double.tryParse(
        row['avg_price'].toString(),
      );

      if (startDate == null ||
          endDate == null ||
          price == null) {
        continue;
      }

      String label;

      if (startDate.day ==
          endDate.day) {
        label =
        '${monthName(startDate.month)} ${startDate.day}';
      } else {
        label =
        '${monthName(startDate.month)} '
            '${startDate.day}–${endDate.day}';
      }

      result.add({
        'date':
        row['start_date'],

        'label':
        label,

        'price':
        price,
      });
    }

    if (result.length > 8) {
      return result.sublist(
        result.length - 8,
      );
    }

    return result;
  }

  Future<List<Map<String, dynamic>>>
  loadMonthlyTrend() async {
    final rows =
    await databaseService
        .getMonthlyTrend(
      selectedItemCode!,
    );

    final List<Map<String, dynamic>>
    result = [];

    for (final row in rows) {
      final date =
      DateTime.tryParse(
        row['month'].toString(),
      );

      final price =
      double.tryParse(
        row['avg_price'].toString(),
      );

      if (date == null ||
          price == null) {
        continue;
      }

      result.add({
        'date':
        row['month'],

        'label':
        '${monthName(date.month)} ${date.year}',

        'price':
        price,
      });
    }

    return result;
  }

  Future<void> loadMonthlyItems() async {
    try {
      setState(() {
        isMonthlyLoading = true;
      });

      final latestData =
      await databaseService
          .getLatestMonthData();

      if (latestData.isEmpty) {
        setState(() {
          monthlyItems = [];
          isMonthlyLoading = false;
        });

        return;
      }

      final latestMonth =
      DateTime.tryParse(
        latestData.first['month']
            .toString(),
      );

      if (latestMonth == null) {
        setState(() {
          monthlyItems = [];
          isMonthlyLoading = false;
        });

        return;
      }

      final previousMonth =
      DateTime(
        latestMonth.year,
        latestMonth.month - 1,
        1,
      );

      final latestMonthText =
          '${latestMonth.year}-'
          '${two(latestMonth.month)}-01';

      final previousMonthText =
          '${previousMonth.year}-'
          '${two(previousMonth.month)}-01';

      final currentRows =
      await databaseService
          .getMonthlyPrices(
        latestMonthText,
      );

      final previousRows =
      await databaseService
          .getMonthlyPrices(
        previousMonthText,
      );

      final Map<dynamic, double>
      currentPrices = {};

      final Map<dynamic, double>
      previousPrices = {};

      for (final row in currentRows) {
        final code =
        row['item_code'];

        final price =
        double.tryParse(
          row['avg_price']
              .toString(),
        );

        if (code != null &&
            price != null) {
          currentPrices[code] =
              price;
        }
      }

      for (final row in previousRows) {
        final code =
        row['item_code'];

        final price =
        double.tryParse(
          row['avg_price']
              .toString(),
        );

        if (code != null &&
            price != null) {
          previousPrices[code] =
              price;
        }
      }

      final List<Map<String, dynamic>>
      itemsToShow = [];

      if (selectedItemCode != null) {
        for (final item in foodItems) {
          if (item['item_code'] ==
              selectedItemCode &&
              currentPrices.containsKey(
                selectedItemCode,
              )) {
            itemsToShow.add(
              item,
            );

            break;
          }
        }
      }

      for (final item in foodItems) {
        if (itemsToShow.length >= 8) {
          break;
        }

        final code =
        item['item_code'];

        if (code ==
            selectedItemCode) {
          continue;
        }

        if (!currentPrices
            .containsKey(code)) {
          continue;
        }

        itemsToShow.add(
          item,
        );
      }

      final List<Map<String, dynamic>>
      result = [];

      for (final item in itemsToShow) {
        final code =
        item['item_code'];

        final current =
        currentPrices[code];

        if (current == null) {
          continue;
        }

        final previous =
        previousPrices[code];

        double change = 0;

        if (previous != null &&
            previous != 0) {
          change =
              ((current - previous) /
                  previous) *
                  100;
        }

        result.add({
          'item_code':
          code,

          'item':
          item['item'],

          'unit':
          item['unit'],

          'price':
          current,

          'change':
          change,
        });
      }

      setState(() {
        monthlyItems = result;
        isMonthlyLoading = false;
      });
    } catch (e) {
      setState(() {
        isMonthlyLoading = false;
      });

      debugPrint(
        'Monthly items error: $e',
      );
    }
  }

  String two(int value) {
    return value.toString().padLeft(
      2,
      '0',
    );
  }

  String monthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month];
  }

  String getSelectedFoodName() {
    if (selectedItemCode == null) {
      return '';
    }

    for (final item in foodItems) {
      if (item['item_code'] ==
          selectedItemCode) {
        return item['item']
            ?.toString() ??
            '';
      }
    }

    return '';
  }

  String getSelectedFoodUnit() {
    if (selectedItemCode == null) {
      return '';
    }

    for (final item in foodItems) {
      if (item['item_code'] ==
          selectedItemCode) {
        return item['unit']
            ?.toString() ??
            '';
      }
    }

    return '';
  }

  double getCurrentPrice() {
    if (trendData.isEmpty) {
      return 0;
    }

    return trendData.last['price']
    as double;
  }

  double getStartPrice() {
    if (trendData.isEmpty) {
      return 0;
    }

    return trendData.first['price']
    as double;
  }

  double getLowPrice() {
    if (trendData.isEmpty) {
      return 0;
    }

    return trendData
        .map<double>(
          (item) =>
      item['price'] as double,
    )
        .reduce(min);
  }

  double getHighPrice() {
    if (trendData.isEmpty) {
      return 0;
    }

    return trendData
        .map<double>(
          (item) =>
      item['price'] as double,
    )
        .reduce(max);
  }

  double getAveragePrice() {
    if (trendData.isEmpty) {
      return 0;
    }

    double total = 0;

    for (final item in trendData) {
      total +=
      item['price'] as double;
    }

    return total / trendData.length;
  }

  double getNetChange() {
    return getCurrentPrice() -
        getStartPrice();
  }

  double getPercentageChange() {
    final start = getStartPrice();

    if (start == 0) {
      return 0;
    }

    return (getNetChange() / start) *
        100;
  }

  String getCurrentLabel() {
    if (selectedPeriod == 'Daily') {
      return 'Current Price';
    }

    if (selectedPeriod == 'Weekly') {
      return 'Latest Week Avg';
    }

    return 'Latest Month Avg';
  }

  String getStartLabel() {
    if (selectedPeriod == 'Daily') {
      return 'Period Start';
    }

    if (selectedPeriod == 'Weekly') {
      return 'First Week Avg';
    }

    return 'First Month Avg';
  }

  Widget buildHeader() {
    return Container(
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
          bottomLeft:
          Radius.circular(28),
          bottomRight:
          Radius.circular(28),
        ),
      ),
      child: const Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.show_chart,
                color: Colors.white,
                size: 25,
              ),
              SizedBox(width: 9),
              Text(
                'Price Trends',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            'Track and analyse food price changes over time',
            style: TextStyle(
              color:
              Color(0xFFDCEDE6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFoodSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        0,
      ),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color:
          const Color(0xFFE3E9E6),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Food Item',
            style: TextStyle(
              fontSize: 13,
              fontWeight:
              FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            initialValue:
            selectedItemCode,
            isExpanded: true,
            menuMaxHeight: 350,
            decoration:
            InputDecoration(
              prefixIcon:
              const Icon(
                Icons.restaurant_menu,
                color:
                primaryGreen,
                size: 20,
              ),
              filled: true,
              fillColor:
              backgroundColor,
              contentPadding:
              const EdgeInsets
                  .symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              border:
              OutlineInputBorder(
                borderRadius:
                BorderRadius
                    .circular(14),
                borderSide:
                const BorderSide(
                  color: Color(
                    0xFFE3E9E6,
                  ),
                ),
              ),
              enabledBorder:
              OutlineInputBorder(
                borderRadius:
                BorderRadius
                    .circular(14),
                borderSide:
                const BorderSide(
                  color: Color(
                    0xFFE3E9E6,
                  ),
                ),
              ),
              focusedBorder:
              OutlineInputBorder(
                borderRadius:
                BorderRadius
                    .circular(14),
                borderSide:
                const BorderSide(
                  color:
                  primaryGreen,
                ),
              ),
            ),
            items: foodItems.map(
                  (item) {
                return DropdownMenuItem<
                    int>(
                  value:
                  item['item_code'],
                  child: Text(
                    '${item['item'] ?? ''} '
                        '(${item['unit'] ?? ''})',
                    maxLines: 1,
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
            onChanged:
                (value) async {
              if (value == null) {
                return;
              }

              setState(() {
                selectedItemCode =
                    value;
                selectedPointIndex =
                null;
              });

              await loadTrendData();
              await loadMonthlyItems();
            },
          ),
        ],
      ),
    );
  }

  Widget buildPeriodSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        0,
      ),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color:
          const Color(0xFFE3E9E6),
        ),
      ),
      child: Row(
        children: periods.map(
              (period) {
            final selected =
                selectedPeriod ==
                    period;

            return Expanded(
              child: InkWell(
                onTap: () {
                  if (selected) {
                    return;
                  }

                  setState(() {
                    selectedPeriod =
                        period;
                    selectedPointIndex =
                    null;
                  });

                  loadTrendData();
                },
                borderRadius:
                BorderRadius
                    .circular(12),
                child: Container(
                  padding:
                  const EdgeInsets
                      .symmetric(
                    vertical: 10,
                  ),
                  decoration:
                  BoxDecoration(
                    color: selected
                        ? primaryGreen
                        : Colors
                        .transparent,
                    borderRadius:
                    BorderRadius
                        .circular(
                      12,
                    ),
                  ),
                  alignment:
                  Alignment.center,
                  child: Text(
                    period,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : Colors
                          .black54,
                      fontSize: 11,
                      fontWeight:
                      FontWeight
                          .w600,
                    ),
                  ),
                ),
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  Widget buildTrendCard() {
    final current =
    getCurrentPrice();

    final change =
    getNetChange();

    final percentage =
    getPercentageChange();

    final isUp = change > 0;
    final isDown = change < 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        0,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color:
          const Color(0xFFE3E9E6),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
            CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      getSelectedFoodName(),
                      maxLines: 2,
                      overflow:
                      TextOverflow
                          .ellipsis,
                      style:
                      const TextStyle(
                        fontSize: 12,
                        fontWeight:
                        FontWeight
                            .w600,
                        color:
                        textColor,
                      ),
                    ),

                    const SizedBox(
                        height: 6),

                    Text(
                      'RM ${current.toStringAsFixed(2)}',
                      style:
                      const TextStyle(
                        color:
                        textColor,
                        fontSize: 26,
                        fontWeight:
                        FontWeight
                            .bold,
                      ),
                    ),

                    const SizedBox(
                        height: 2),

                    Text(
                      getSelectedFoodUnit(),
                      style:
                      const TextStyle(
                        color: Colors
                            .black45,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment:
                CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration:
                    BoxDecoration(
                      color: isUp
                          ? const Color(
                        0xFFFFEEEE,
                      )
                          : isDown
                          ? lightGreen
                          : backgroundColor,
                      borderRadius:
                      BorderRadius
                          .circular(
                        12,
                      ),
                    ),
                    child: Text(
                      '${isUp ? '↗' : isDown ? '↘' : '→'} '
                          '${percentage > 0 ? '+' : ''}'
                          '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: isUp
                            ? Colors.red
                            : isDown
                            ? primaryGreen
                            : Colors
                            .grey,
                        fontSize: 12,
                        fontWeight:
                        FontWeight
                            .bold,
                      ),
                    ),
                  ),

                  const SizedBox(
                      height: 5),

                  Text(
                    '${change > 0 ? '+' : change < 0 ? '-' : ''}'
                        'RM ${change.abs().toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isUp
                          ? Colors.red
                          : isDown
                          ? primaryGreen
                          : Colors.grey,
                      fontSize: 9,
                      fontWeight:
                      FontWeight
                          .w600,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            '$selectedPeriod Price Trend',
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black45,
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            height: 200,
            width: double.infinity,
            child: trendData.isEmpty
                ? const Center(
              child: Text(
                'No trend data available',
                style: TextStyle(
                  color:
                  Colors.grey,
                ),
              ),
            )
                : TrendChart(
              data: trendData,
              selectedIndex:
              selectedPointIndex,
              onPointSelected:
                  (index) {
                setState(() {
                  selectedPointIndex =
                      index;
                });
              },
            ),
          ),

          if (selectedPointIndex != null &&
              selectedPointIndex! <
                  trendData.length)
            Container(
              width: double.infinity,
              margin:
              const EdgeInsets.only(
                top: 10,
              ),
              padding:
              const EdgeInsets.all(
                10,
              ),
              decoration: BoxDecoration(
                color: lightGreen,
                borderRadius:
                BorderRadius.circular(
                  12,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons
                        .touch_app_outlined,
                    color:
                    primaryGreen,
                    size: 17,
                  ),

                  const SizedBox(width: 7),

                  Expanded(
                    child: Text(
                      trendData[
                      selectedPointIndex!]
                      ['label']
                          .toString(),
                      style:
                      const TextStyle(
                        fontSize: 10,
                        fontWeight:
                        FontWeight
                            .w600,
                      ),
                    ),
                  ),

                  Text(
                    'RM ${(trendData[selectedPointIndex!]['price'] as double).toStringAsFixed(2)}',
                    style:
                    const TextStyle(
                      fontSize: 11,
                      color:
                      primaryGreen,
                      fontWeight:
                      FontWeight
                          .bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        0,
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'Price Summary',
            style: TextStyle(
              fontSize: 17,
              fontWeight:
              FontWeight.w700,
              color: textColor,
            ),
          ),

          const SizedBox(height: 10),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics:
            const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.8,
            children: [
              buildSummaryCard(
                getCurrentLabel(),
                'RM ${getCurrentPrice().toStringAsFixed(2)}',
                textColor,
              ),
              buildSummaryCard(
                getStartLabel(),
                'RM ${getStartPrice().toStringAsFixed(2)}',
                textColor,
              ),
              buildSummaryCard(
                'Period Low',
                'RM ${getLowPrice().toStringAsFixed(2)}',
                primaryGreen,
              ),
              buildSummaryCard(
                'Period High',
                'RM ${getHighPrice().toStringAsFixed(2)}',
                Colors.red,
              ),
              buildSummaryCard(
                'Average Price',
                'RM ${getAveragePrice().toStringAsFixed(2)}',
                textColor,
              ),
              buildSummaryCard(
                'Net Change',
                '${getNetChange() > 0 ? '+' : getNetChange() < 0 ? '-' : ''}'
                    'RM ${getNetChange().abs().toStringAsFixed(2)}',
                getNetChange() > 0
                    ? Colors.red
                    : getNetChange() < 0
                    ? primaryGreen
                    : Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildSummaryCard(
      String title,
      String value,
      Color valueColor,
      ) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color:
          const Color(0xFFE3E9E6),
        ),
      ),
      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 9,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 15,
              fontWeight:
              FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMonthlyItems() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        20,
      ),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color:
          const Color(0xFFE3E9E6),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.trending_up,
                color:
                primaryGreen,
                size: 18,
              ),
              SizedBox(width: 7),
              Text(
                'Monthly Food Price Changes',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          const Text(
            'Latest month compared with previous month',
            style: TextStyle(
              color: Colors.black45,
              fontSize: 9,
            ),
          ),

          const SizedBox(height: 13),

          if (isMonthlyLoading)
            const Padding(
              padding:
              EdgeInsets.symmetric(
                vertical: 20,
              ),
              child: Center(
                child:
                CircularProgressIndicator(
                  color:
                  primaryGreen,
                  strokeWidth: 2,
                ),
              ),
            ),

          if (!isMonthlyLoading &&
              monthlyItems.isEmpty)
            const Padding(
              padding:
              EdgeInsets.symmetric(
                vertical: 20,
              ),
              child: Center(
                child: Text(
                  'No monthly item data available',
                  style: TextStyle(
                    color:
                    Colors.grey,
                    fontSize: 10,
                  ),
                ),
              ),
            ),

          if (!isMonthlyLoading)
            ...monthlyItems.map(
                  (item) {
                final price =
                item['price']
                as double;

                final change =
                item['change']
                as double;

                final isUp =
                    change > 0;

                final isDown =
                    change < 0;

                return Padding(
                  padding:
                  const EdgeInsets
                      .only(
                    bottom: 11,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration:
                        BoxDecoration(
                          color:
                          lightGreen,
                          borderRadius:
                          BorderRadius
                              .circular(
                            11,
                          ),
                        ),
                        child:
                        const Icon(
                          Icons
                              .restaurant_menu,
                          color:
                          primaryGreen,
                          size: 18,
                        ),
                      ),

                      const SizedBox(
                          width: 10),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                          children: [
                            Text(
                              item['item']
                                  ?.toString() ??
                                  '',
                              maxLines: 1,
                              overflow:
                              TextOverflow
                                  .ellipsis,
                              style:
                              const TextStyle(
                                color:
                                textColor,
                                fontSize: 10,
                                fontWeight:
                                FontWeight
                                    .w600,
                              ),
                            ),

                            const SizedBox(
                                height: 2),

                            Text(
                              item['unit']
                                  ?.toString() ??
                                  '',
                              style:
                              const TextStyle(
                                color: Colors
                                    .black45,
                                fontSize: 8,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Text(
                        '${isUp ? '↗' : isDown ? '↘' : '→'} '
                            '${change > 0 ? '+' : ''}'
                            '${change.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: isUp
                              ? Colors.red
                              : isDown
                              ? primaryGreen
                              : Colors.grey,
                          fontSize: 9,
                          fontWeight:
                          FontWeight
                              .bold,
                        ),
                      ),

                      const SizedBox(
                          width: 10),

                      SizedBox(
                        width: 60,
                        child: Text(
                          'RM ${price.toStringAsFixed(2)}',
                          textAlign:
                          TextAlign.right,
                          style:
                          const TextStyle(
                            color:
                            textColor,
                            fontSize: 9,
                            fontWeight:
                            FontWeight
                                .w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
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
            buildHeader(),

            Expanded(
              child: isLoading
                  ? const Center(
                child:
                CircularProgressIndicator(
                  color:
                  primaryGreen,
                ),
              )
                  : foodItems.isEmpty
                  ? const Center(
                child: Text(
                  'No trend data available',
                ),
              )
                  : RefreshIndicator(
                color:
                primaryGreen,
                onRefresh: () async {
                  await loadTrendData();
                  await loadMonthlyItems();
                },
                child:
                SingleChildScrollView(
                  physics:
                  const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      buildFoodSelector(),
                      buildPeriodSelector(),
                      buildTrendCard(),
                      buildSummaryCards(),
                      buildMonthlyItems(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final int? selectedIndex;
  final ValueChanged<int> onPointSelected;

  const TrendChart({
    super.key,
    required this.data,
    required this.selectedIndex,
    required this.onPointSelected,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return LayoutBuilder(
      builder: (
          context,
          constraints,
          ) {
        return GestureDetector(
          onTapDown: (details) {
            if (data.isEmpty) {
              return;
            }

            const leftPadding = 42.0;
            const rightPadding = 12.0;

            final width =
                constraints.maxWidth -
                    leftPadding -
                    rightPadding;

            if (width <= 0) {
              return;
            }

            final relativeX =
                details.localPosition.dx -
                    leftPadding;

            final spacing =
            data.length <= 1
                ? width
                : width /
                (data.length - 1);

            int index =
            spacing == 0
                ? 0
                : (relativeX /
                spacing)
                .round();

            index = index.clamp(
              0,
              data.length - 1,
            );

            onPointSelected(
              index,
            );
          },
          child: CustomPaint(
            size: Size(
              constraints.maxWidth,
              200,
            ),
            painter:
            TrendChartPainter(
              data: data,
              selectedIndex:
              selectedIndex,
            ),
          ),
        );
      },
    );
  }
}

class TrendChartPainter
    extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final int? selectedIndex;

  TrendChartPainter({
    required this.data,
    required this.selectedIndex,
  });

  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {
    if (data.isEmpty) {
      return;
    }

    const left = 42.0;
    const right = 12.0;
    const top = 15.0;
    const bottom = 36.0;

    final chartWidth =
        size.width -
            left -
            right;

    final chartHeight =
        size.height -
            top -
            bottom;

    final prices =
    data
        .map<double>(
          (item) =>
      item['price']
      as double,
    )
        .toList();

    double minimum =
    prices.reduce(min);

    double maximum =
    prices.reduce(max);

    if (minimum == maximum) {
      minimum -= 0.10;
      maximum += 0.10;
    }

    final difference =
        maximum - minimum;

    minimum -=
        difference * 0.20;

    maximum +=
        difference * 0.20;

    final gridPaint = Paint()
      ..color =
      Colors.grey.withValues(
        alpha: 0.30,
      )
      ..strokeWidth = 0.7;

    const horizontalLines = 4;

    for (
    int i = 0;
    i <= horizontalLines;
    i++
    ) {
      final y =
          top +
              chartHeight *
                  i /
                  horizontalLines;

      drawDashedLine(
        canvas,
        Offset(
          left,
          y,
        ),
        Offset(
          left + chartWidth,
          y,
        ),
        gridPaint,
      );

      final price =
          maximum -
              (maximum - minimum) *
                  i /
                  horizontalLines;

      final priceText =
      TextPainter(
        text: TextSpan(
          text:
          price.toStringAsFixed(
            2,
          ),
          style:
          const TextStyle(
            color:
            Colors.grey,
            fontSize: 7,
          ),
        ),
        textDirection:
        TextDirection.ltr,
      )..layout();

      priceText.paint(
        canvas,
        Offset(
          left -
              priceText.width -
              5,
          y -
              priceText.height /
                  2,
        ),
      );
    }

    final List<Offset> points = [];

    for (
    int i = 0;
    i < data.length;
    i++
    ) {
      final price =
      data[i]['price']
      as double;

      final x =
      data.length == 1
          ? left +
          chartWidth / 2
          : left +
          chartWidth *
              i /
              (data.length -
                  1);

      final normalized =
          (price - minimum) /
              (maximum - minimum);

      final y =
          top +
              chartHeight *
                  (1 - normalized);

      points.add(
        Offset(
          x,
          y,
        ),
      );
    }

    final linePaint = Paint()
      ..color =
          _TrendPageState
              .primaryGreen
      ..strokeWidth = 2.5
      ..style =
          PaintingStyle.stroke;

    final path = Path();

    path.moveTo(
      points.first.dx,
      points.first.dy,
    );

    for (
    int i = 1;
    i < points.length;
    i++
    ) {
      path.lineTo(
        points[i].dx,
        points[i].dy,
      );
    }

    canvas.drawPath(
      path,
      linePaint,
    );

    for (
    int i = 0;
    i < points.length;
    i++
    ) {
      final selected =
          selectedIndex == i;

      canvas.drawCircle(
        points[i],
        selected ? 5 : 3.5,
        Paint()
          ..color = selected
              ? Colors.white
              : _TrendPageState
              .primaryGreen,
      );

      if (selected) {
        canvas.drawCircle(
          points[i],
          3.5,
          Paint()
            ..color =
                _TrendPageState
                    .primaryGreen,
        );
      }

      final label =
          data[i]['label']
              ?.toString() ??
              '';

      bool showLabel = true;

      if (data.length > 8) {
        showLabel =
            i == 0 ||
                i ==
                    data.length - 1 ||
                i % 2 == 0;
      }

      if (showLabel) {
        final labelText =
        TextPainter(
          text: TextSpan(
            text: label,
            style:
            const TextStyle(
              color:
              Colors.grey,
              fontSize: 7,
            ),
          ),
          textDirection:
          TextDirection.ltr,
        )..layout();

        labelText.paint(
          canvas,
          Offset(
            points[i].dx -
                labelText.width /
                    2,
            top +
                chartHeight +
                9,
          ),
        );
      }
    }

    if (selectedIndex != null &&
        selectedIndex! >= 0 &&
        selectedIndex! <
            data.length) {
      drawTooltip(
        canvas,
        size,
        points[
        selectedIndex!],
        data[selectedIndex!],
      );
    }
  }

  void drawTooltip(
      Canvas canvas,
      Size size,
      Offset point,
      Map<String, dynamic> item,
      ) {
    final price =
    item['price'] as double;

    final label =
        item['label']
            ?.toString() ??
            '';

    const boxWidth = 140.0;
    const boxHeight = 54.0;

    double left =
        point.dx -
            boxWidth / 2;

    if (left < 5) {
      left = 5;
    }

    if (left +
        boxWidth >
        size.width - 5) {
      left =
          size.width -
              boxWidth -
              5;
    }

    double top =
        point.dy -
            boxHeight -
            12;

    if (top < 5) {
      top =
          point.dy + 12;
    }

    final rectangle =
    RRect.fromRectAndRadius(
      Rect.fromLTWH(
        left,
        top,
        boxWidth,
        boxHeight,
      ),
      const Radius.circular(8),
    );

    canvas.drawRRect(
      rectangle,
      Paint()
        ..color = Colors.white,
    );

    canvas.drawRRect(
      rectangle,
      Paint()
        ..color =
            _TrendPageState
                .primaryGreen
        ..style =
            PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final labelText =
    TextPainter(
      text: TextSpan(
        text: label,
        style:
        const TextStyle(
          color:
          _TrendPageState
              .textColor,
          fontSize: 9,
          fontWeight:
          FontWeight.bold,
        ),
      ),
      textDirection:
      TextDirection.ltr,
    )..layout();

    labelText.paint(
      canvas,
      Offset(
        left + 10,
        top + 9,
      ),
    );

    final priceText =
    TextPainter(
      text: TextSpan(
        text:
        'RM ${price.toStringAsFixed(2)}',
        style:
        const TextStyle(
          color:
          _TrendPageState
              .primaryGreen,
          fontSize: 9,
          fontWeight:
          FontWeight.w600,
        ),
      ),
      textDirection:
      TextDirection.ltr,
    )..layout();

    priceText.paint(
      canvas,
      Offset(
        left + 10,
        top + 30,
      ),
    );
  }

  void drawDashedLine(
      Canvas canvas,
      Offset start,
      Offset end,
      Paint paint,
      ) {
    const dashWidth = 3.0;
    const dashSpace = 3.0;

    final difference =
        end - start;

    final distance =
        difference.distance;

    if (distance == 0) {
      return;
    }

    final direction =
        difference / distance;

    double drawn = 0;

    while (drawn < distance) {
      final from = start + direction * drawn;

      final nextDistance =
      min(
        drawn + dashWidth,
        distance,
      );

      final to = start + direction * nextDistance;
      canvas.drawLine(from, to, paint,);
      drawn += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(
      covariant TrendChartPainter oldDelegate,
      ) {
    return oldDelegate.data != data ||
        oldDelegate.selectedIndex !=
            selectedIndex;
  }
}