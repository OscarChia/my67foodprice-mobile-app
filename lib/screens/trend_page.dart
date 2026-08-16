import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrendPage extends StatefulWidget {
  const TrendPage({super.key});

  @override
  State<TrendPage> createState() => _TrendPageState();
}

class _TrendPageState extends State<TrendPage> {
  final supabase = Supabase.instance.client;

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

  // =========================================================
  // INITIAL
  // =========================================================

  Future<void> loadInitialData() async {
    await loadFoodItemsWithPrices();
  }

  // =========================================================
  // FOOD ITEMS
  // Only food that has price records
  // =========================================================

  Future<void> loadFoodItemsWithPrices() async {
    try {
      setState(() {
        isLoading = true;
      });

      final priceData = await supabase
          .from('monthly_food_price_summary')
          .select('item_code');

      final itemCodeSet = priceData
          .map(
            (row) => row['item_code'],
      )
          .where(
            (code) => code != null,
      )
          .toSet();

      if (itemCodeSet.isEmpty) {
        if (!mounted) return;

        setState(() {
          foodItems = [];
          trendData = [];
          monthlyItems = [];
          selectedItemCode = null;
          isLoading = false;
        });

        return;
      }

      final itemCodes = itemCodeSet.toList();

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

        final batch = itemCodes.sublist(
          i,
          end,
        );

        final data = await supabase
            .from('food_items')
            .select(
          'item_code, item, unit',
        )
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

          return nameA.compareTo(nameB);
        },
      );

      if (!mounted) return;

      setState(() {
        foodItems = allFoodItems;

        if (foodItems.isNotEmpty) {
          selectedItemCode =
          foodItems.first['item_code'];
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
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showMessage(
        'Error loading food items: $e',
      );
    }
  }

  // =========================================================
  // TREND
  // =========================================================

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
        result = await loadDailyTrend();
      } else if (selectedPeriod ==
          'Weekly') {
        result = await loadWeeklyTrend();
      } else {
        result = await loadMonthlyTrend();
      }

      if (!mounted) return;

      setState(() {
        trendData = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showMessage(
        'Error loading trend: $e',
      );
    }
  }

  // =========================================================
  // DAILY
  // Latest 15 available dates
  // =========================================================

  Future<List<Map<String, dynamic>>>
  loadDailyTrend() async {
    final data = await supabase
        .from('daily_food_price_summary')
        .select(
      'date, avg_price',
    )
        .eq(
      'item_code',
      selectedItemCode!,
    )
        .order(
      'date',
      ascending: false,
    )
        .limit(15);

    final rows =
    List<Map<String, dynamic>>.from(
      data,
    ).reversed.toList();

    final List<Map<String, dynamic>>
    result = [];

    for (final row in rows) {
      final date = DateTime.tryParse(
        row['date'].toString(),
      );

      final price = double.tryParse(
        row['avg_price'].toString(),
      );

      if (date == null ||
          price == null) {
        continue;
      }

      result.add({
        'date': row['date'],
        'label':
        '${monthName(date.month)} ${date.day}',
        'price': price,
      });
    }

    return result;
  }

  // =========================================================
  // WEEKLY
  //
  // Example:
  // Jul 1–7
  // Jul 8–14
  // Jul 15–21
  // Jul 22–28
  // Jul 29–31
  // Aug 1–7
  // Aug 8–14
  // Aug 15
  // =========================================================

  Future<List<Map<String, dynamic>>>
  loadWeeklyTrend() async {
    final data = await supabase
        .from('weekly_food_price_summary')
        .select(
      'month, week_number, start_date, end_date, avg_price',
    )
        .eq(
      'item_code',
      selectedItemCode!,
    )
        .order(
      'month',
      ascending: true,
    )
        .order(
      'week_number',
      ascending: true,
    );

    final rows =
    List<Map<String, dynamic>>.from(
      data,
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
        'date': row['start_date'],
        'label': label,
        'price': price,
      });
    }

    // Latest 8 weekly periods
    if (result.length > 8) {
      return result.sublist(
        result.length - 8,
      );
    }

    return result;
  }

  // =========================================================
  // MONTHLY
  //
  // Jul 2026
  // Aug 2026
  // =========================================================

  Future<List<Map<String, dynamic>>>
  loadMonthlyTrend() async {
    final data = await supabase
        .from('monthly_food_price_summary')
        .select(
      'month, start_date, end_date, avg_price',
    )
        .eq(
      'item_code',
      selectedItemCode!,
    )
        .order(
      'month',
      ascending: true,
    );

    final rows =
    List<Map<String, dynamic>>.from(
      data,
    );

    final List<Map<String, dynamic>>
    result = [];

    for (final row in rows) {
      final date = DateTime.tryParse(
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
        'date': row['month'],
        'label':
        '${monthName(date.month)} ${date.year}',
        'price': price,
      });
    }

    return result;
  }

  // =========================================================
  // ALL ITEMS THIS MONTH
  //
  // Latest month vs previous month
  // Example:
  // August vs July
  // =========================================================

  Future<void> loadMonthlyItems() async {
    try {
      if (!mounted) return;

      setState(() {
        isMonthlyLoading = true;
      });

      // Find latest month
      final latestData = await supabase
          .from('monthly_food_price_summary')
          .select('month')
          .order(
        'month',
        ascending: false,
      )
          .limit(1);

      if (latestData.isEmpty) {
        if (!mounted) return;

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
        if (!mounted) return;

        setState(() {
          monthlyItems = [];
          isMonthlyLoading = false;
        });

        return;
      }

      final previousMonth = DateTime(
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

      // Current month
      final currentData = await supabase
        .from('monthly_food_price_summary')
          .select(
        'item_code, avg_price',
      )
          .eq(
        'month',
        latestMonthText,
      );

      // Previous month
      final previousData = await supabase
        .from('monthly_food_price_summary')
          .select(
        'item_code, avg_price',
      )
          .eq(
        'month',
        previousMonthText,
      );

      final currentRows =
      List<Map<String, dynamic>>.from(
        currentData,
      );

      final previousRows =
      List<Map<String, dynamic>>.from(
        previousData,
      );

      final Map<dynamic, double>
      currentPrices = {};

      final Map<dynamic, double>
      previousPrices = {};

      for (final row in currentRows) {
        final code = row['item_code'];

        final price =
        double.tryParse(
          row['avg_price'].toString(),
        );

        if (code != null &&
            price != null) {
          currentPrices[code] =
              price;
        }
      }

      for (final row in previousRows) {
        final code = row['item_code'];

        final price =
        double.tryParse(
          row['avg_price'].toString(),
        );

        if (code != null &&
            price != null) {
          previousPrices[code] =
              price;
        }
      }

      final List<Map<String, dynamic>>
      itemsToShow = [];

      // Selected item first
      if (selectedItemCode != null) {
        for (final item in foodItems) {
          if (item['item_code'] ==
              selectedItemCode &&
              currentPrices.containsKey(
                selectedItemCode,
              )) {
            itemsToShow.add(item);
            break;
          }
        }
      }

      // Another items until total 8
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

        if (!currentPrices.containsKey(
          code,
        )) {
          continue;
        }

        itemsToShow.add(item);
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
          'item_code': code,
          'item': item['item'],
          'unit': item['unit'],
          'price': current,
          'change': change,
        });
      }

      if (!mounted) return;

      setState(() {
        monthlyItems = result;
        isMonthlyLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isMonthlyLoading = false;
      });

      debugPrint(
        'Monthly items error: $e',
      );
    }
  }

  // =========================================================
  // HELPER
  // =========================================================

  String two(int value) {
    return value
        .toString()
        .padLeft(
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

  // =========================================================
  // CALCULATIONS
  // =========================================================

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

    return total /
        trendData.length;
  }

  double getNetChange() {
    return getCurrentPrice() -
        getStartPrice();
  }

  double getPercentageChange() {
    final start =
    getStartPrice();

    if (start == 0) {
      return 0;
    }

    return (getNetChange() /
        start) *
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

  // =========================================================
  // HEADER
  // =========================================================

  Widget buildHeader() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.fromLTRB(
        14,
        15,
        14,
        13,
      ),
      color: Colors.white,
      child: const Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.show_chart,
                color: Colors.teal,
                size: 22,
              ),
              SizedBox(width: 7),
              Text(
                'Price Trends',
                style: TextStyle(
                  color:
                  Color(0xFF202424),
                  fontSize: 20,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 3),
          Padding(
            padding:
            EdgeInsets.only(
              left: 29,
            ),
            child: Text(
              'Track how food prices change over time',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // FOOD SELECTOR
  // =========================================================

  Widget buildFoodSelector() {
    return Container(
      margin:
      const EdgeInsets.fromLTRB(
        14,
        14,
        14,
        0,
      ),
      padding:
      const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
      ),
      child:
      DropdownButtonFormField<int>(
        value: selectedItemCode,
        isExpanded: true,
        menuMaxHeight: 350,
        decoration: InputDecoration(
          labelText: 'Food Item',
          prefixIcon:
          const Icon(
            Icons.restaurant_menu,
            color: Colors.teal,
            size: 20,
          ),
          filled: true,
          fillColor:
          const Color(
            0xFFF4F7F6,
          ),
          contentPadding:
          const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 13,
          ),
          border:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(
              14,
            ),
            borderSide:
            BorderSide.none,
          ),
        ),
        items:
        foodItems.map(
              (item) {
            return DropdownMenuItem<int>(
              value:
              item['item_code'],
              child: Text(
                '${item['item'] ?? ''} '
                    '(${item['unit'] ?? ''})',
                maxLines: 1,
                overflow:
                TextOverflow.ellipsis,
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
            selectedItemCode = value;
            selectedPointIndex = null;
          });

          await loadTrendData();

          await loadMonthlyItems();
        },
      ),
    );
  }

  // =========================================================
  // PERIOD SELECTOR
  // =========================================================

  Widget buildPeriodSelector() {
    return Container(
      margin:
      const EdgeInsets.fromLTRB(
        14,
        12,
        14,
        0,
      ),
      padding:
      const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(14),
      ),
      child: Row(
        children:
        periods.map(
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
                BorderRadius.circular(
                  11,
                ),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(
                    vertical: 9,
                  ),
                  decoration:
                  BoxDecoration(
                    color: selected
                        ? Colors.teal
                        : Colors.transparent,
                    borderRadius:
                    BorderRadius.circular(
                      11,
                    ),
                  ),
                  alignment:
                  Alignment.center,
                  child: Text(
                    period,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : Colors.grey[700],
                      fontSize: 11,
                      fontWeight:
                      FontWeight.w600,
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

  // =========================================================
  // TREND CARD
  // =========================================================

  Widget buildTrendCard() {
    final current =
    getCurrentPrice();

    final change =
    getNetChange();

    final percentage =
    getPercentageChange();

    final isUp =
        change > 0;

    final isDown =
        change < 0;

    return Container(
      margin:
      const EdgeInsets.fromLTRB(
        14,
        12,
        14,
        0,
      ),
      padding:
      const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment:
            CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      getSelectedFoodName(),
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style:
                      const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      'RM ${current.toStringAsFixed(2)}',
                      style:
                      const TextStyle(
                        color:
                        Color(
                          0xFF202424,
                        ),
                        fontSize: 23,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                    Text(
                      getSelectedFoodUnit(),
                      style:
                      const TextStyle(
                        color: Colors.grey,
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
                  Text(
                    '${isUp ? '↗' : isDown ? '↘' : '→'} '
                        '${percentage > 0 ? '+' : ''}'
                        '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: isUp
                          ? Colors.redAccent
                          : isDown
                          ? Colors.teal
                          : Colors.grey,
                      fontSize: 15,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 3,
                  ),
                  Text(
                    '${change > 0 ? '+' : change < 0 ? '-' : ''}'
                        'RM ${change.abs().toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isUp
                          ? Colors.redAccent
                          : isDown
                          ? Colors.teal
                          : Colors.grey,
                      fontSize: 10,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(
            height: 12,
          ),
          SizedBox(
            height: 190,
            width: double.infinity,
            child: trendData.isEmpty
                ? const Center(
              child: Text(
                'No trend data available',
                style: TextStyle(
                  color: Colors.grey,
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
        ],
      ),
    );
  }

  // =========================================================
  // SUMMARY
  // =========================================================

  Widget buildSummaryCards() {
    return Padding(
      padding:
      const EdgeInsets.fromLTRB(
        14,
        12,
        14,
        0,
      ),
      child: GridView.count(
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
            const Color(
              0xFF202424,
            ),
          ),
          buildSummaryCard(
            getStartLabel(),
            'RM ${getStartPrice().toStringAsFixed(2)}',
            const Color(
              0xFF202424,
            ),
          ),
          buildSummaryCard(
            'Period Low',
            'RM ${getLowPrice().toStringAsFixed(2)}',
            Colors.teal,
          ),
          buildSummaryCard(
            'Period High',
            'RM ${getHighPrice().toStringAsFixed(2)}',
            Colors.redAccent,
          ),
          buildSummaryCard(
            'Avg (National)',
            'RM ${getAveragePrice().toStringAsFixed(2)}',
            Colors.blue,
          ),
          buildSummaryCard(
            'Net Change',
            '${getNetChange() > 0 ? '+' : getNetChange() < 0 ? '-' : ''}'
                'RM ${getNetChange().abs().toStringAsFixed(2)}',
            getNetChange() > 0
                ? Colors.redAccent
                : getNetChange() < 0
                ? Colors.teal
                : Colors.grey,
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
      padding:
      const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style:
            const TextStyle(
              color: Colors.grey,
              fontSize: 9,
            ),
          ),
          const SizedBox(
            height: 5,
          ),
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

  // =========================================================
  // ALL ITEMS THIS MONTH UI
  // =========================================================

  Widget buildMonthlyItems() {
    return Container(
      margin:
      const EdgeInsets.fromLTRB(
        14,
        12,
        14,
        20,
      ),
      padding:
      const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.trending_up,
                color: Colors.teal,
                size: 17,
              ),
              SizedBox(width: 6),
              Text(
                'All Items This Month',
                style: TextStyle(
                  color:
                  Color(
                    0xFF202424,
                  ),
                  fontSize: 13,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 3,
          ),
          const Text(
            'Compared with previous month',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 8,
            ),
          ),
          const SizedBox(
            height: 12,
          ),

          if (isMonthlyLoading)
            const Padding(
              padding:
              EdgeInsets.symmetric(
                vertical: 20,
              ),
              child: Center(
                child:
                CircularProgressIndicator(
                  color: Colors.teal,
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
                    color: Colors.grey,
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
                  const EdgeInsets.only(
                    bottom: 10,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration:
                        BoxDecoration(
                          color:
                          const Color(
                            0xFFE8F7F3,
                          ),
                          borderRadius:
                          BorderRadius.circular(
                            10,
                          ),
                        ),
                        child:
                        const Icon(
                          Icons.restaurant_menu,
                          color: Colors.teal,
                          size: 17,
                        ),
                      ),

                      const SizedBox(
                        width: 9,
                      ),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['item']
                                  ?.toString() ??
                                  '',
                              maxLines: 1,
                              overflow:
                              TextOverflow.ellipsis,
                              style:
                              const TextStyle(
                                color:
                                Color(
                                  0xFF202424,
                                ),
                                fontSize: 10,
                                fontWeight:
                                FontWeight.w600,
                              ),
                            ),
                            Text(
                              item['unit']
                                  ?.toString() ??
                                  '',
                              style:
                              const TextStyle(
                                color: Colors.grey,
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
                              ? Colors.redAccent
                              : isDown
                              ? Colors.teal
                              : Colors.grey,
                          fontSize: 9,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      SizedBox(
                        width: 58,
                        child: Text(
                          'RM ${price.toStringAsFixed(2)}',
                          textAlign:
                          TextAlign.right,
                          style:
                          const TextStyle(
                            color:
                            Color(
                              0xFF202424,
                            ),
                            fontSize: 9,
                            fontWeight:
                            FontWeight.w600,
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

  // =========================================================
  // MESSAGE
  // =========================================================

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

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      const Color(
        0xFFF6F8F8,
      ),
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
                  Colors.teal,
                ),
              )
                  : SingleChildScrollView(
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
          ],
        ),
      ),
    );
  }
}

// =============================================================
// TREND CHART
// =============================================================

class TrendChart extends StatelessWidget {
  final List<Map<String, dynamic>>
  data;

  final int? selectedIndex;

  final ValueChanged<int>
  onPointSelected;

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

            const leftPadding =
            42.0;

            const rightPadding =
            12.0;

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

            onPointSelected(index);
          },
          child: CustomPaint(
            size: Size(
              constraints.maxWidth,
              190,
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

// =============================================================
// CHART PAINTER
// =============================================================

class TrendChartPainter
    extends CustomPainter {
  final List<Map<String, dynamic>>
  data;

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
        Offset(left, y),
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
            color: Colors.grey,
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
              (data.length - 1);

      final normalized =
          (price - minimum) /
              (maximum - minimum);

      final y =
          top +
              chartHeight *
                  (1 - normalized);

      points.add(
        Offset(x, y),
      );
    }

    final linePaint =
    Paint()
      ..color =
          Colors.teal
      ..strokeWidth =
      2.5
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
          ..color =
          selected
              ? Colors.white
              : Colors.teal,
      );

      if (selected) {
        canvas.drawCircle(
          points[i],
          3.5,
          Paint()
            ..color =
                Colors.teal,
        );
      }

      final label =
          data[i]['label']
              ?.toString() ??
              '';

      bool showLabel = true;

      // Daily 15 points:
      // show 1,3,5,7... to prevent crowding
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
              color: Colors.grey,
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
                labelText.width / 2,
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
        points[selectedIndex!],
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
        ..color = Colors.teal
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
          Color(
            0xFF202424,
          ),
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
          color: Colors.teal,
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
      final from =
          start +
              direction * drawn;

      final nextDistance =
      min(
        drawn + dashWidth,
        distance,
      );

      final to =
          start +
              direction *
                  nextDistance;

      canvas.drawLine(
        from,
        to,
        paint,
      );

      drawn +=
          dashWidth +
              dashSpace;
    }
  }

  @override
  bool shouldRepaint(
      covariant TrendChartPainter
      oldDelegate,
      ) {
    return oldDelegate.data !=
        data ||
        oldDelegate.selectedIndex !=
            selectedIndex;
  }
}