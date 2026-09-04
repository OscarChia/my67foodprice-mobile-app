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
  final TextEditingController searchController = TextEditingController();

  String searchText = '';

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

  List<Map<String, dynamic>>
  getFilteredFoodItems() {
    if (searchText.trim().isEmpty) {
      return foodItems;
    }

    final keyword =
    searchText
        .toLowerCase()
        .trim();

    return foodItems.where(
          (food) {
        final itemName =
            food['item']
                ?.toString()
                .toLowerCase() ??
                '';

        final unit =
            food['unit']
                ?.toString()
                .toLowerCase() ??
                '';

        return itemName.contains(
          keyword,
        ) ||
            unit.contains(
              keyword,
            );
      },
    ).toList();
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
        16,
        20,
        18,
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
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
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
                size: 24,
              ),
              SizedBox(width: 9),
              Text(
                'Price Trends',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 5),
          Text(
            'Track and analyse food price changes over time',
            style: TextStyle(
              color: Color(0xFFDCEDE6),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFoodSelector() {
    final filteredItems =
    getFilteredFoodItems();

    int? dropdownValue;

    for (final item in filteredItems) {
      if (item['item_code'] ==
          selectedItemCode) {
        dropdownValue =
            selectedItemCode;
        break;
      }
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        10,
        16,
        0,
      ),
      padding: const EdgeInsets.all(
        14,
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
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Food Item',
            style: TextStyle(
              fontSize: 14,
              fontWeight:
              FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(
            height: 9,
          ),
          DropdownButtonFormField<int>(
            initialValue: dropdownValue,
            isExpanded: true,
            menuMaxHeight: 350,
            hint: Text(
              filteredItems.isEmpty
                  ? 'No food found'
                  : 'Select food item',
              style:
              const TextStyle(
                fontSize: 13,
                color:
                Colors.black45,
              ),
            ),
            decoration:
            InputDecoration(
              prefixIcon:
              const Icon(
                Icons.restaurant_menu,
                color: primaryGreen,
                size: 21,
              ),
              prefixIconConstraints:
              const BoxConstraints(
                minWidth: 46,
                minHeight: 46,
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
                    .circular(
                  13,
                ),
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
                    .circular(
                  13,
                ),
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
                    .circular(
                  13,
                ),
                borderSide:
                const BorderSide(
                  color:
                  primaryGreen,
                  width: 1.4,
                ),
              ),
            ),
            items:
            filteredItems.map(
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
                      fontSize: 13,
                      color:
                      textColor,
                      fontWeight:
                      FontWeight
                          .w500,
                    ),
                  ),
                );
              },
            ).toList(),
            onChanged:
            filteredItems.isEmpty
                ? null
                : (value) async {
              if (value ==
                  null) {
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
        10,
        16,
        0,
      ),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(14),
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
                    .circular(10),
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
                      10,
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
                      fontSize: 13,
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

  Widget buildFoodSearch() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        0,
      ),
      child: TextField(
        controller: searchController,
        style: const TextStyle(
          fontSize: 14,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
        onChanged: (value) {
          setState(() {
            searchText = value;
          });
        },
        decoration: InputDecoration(
          hintText:
          'Search food item',
          hintStyle: const TextStyle(
            fontSize: 13,
            color: Colors.black45,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: primaryGreen,
            size: 22,
          ),
          suffixIcon:
          searchText.isNotEmpty
              ? IconButton(
            onPressed: () {
              searchController.clear();

              setState(() {
                searchText = '';
              });
            },
            icon: const Icon(
              Icons.close,
              size: 20,
              color: Colors.black54,
            ),
          )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
          const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
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
          enabledBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(
              14,
            ),
            borderSide:
            const BorderSide(
              color:
              Color(0xFFE3E9E6),
            ),
          ),
          focusedBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(
              14,
            ),
            borderSide:
            const BorderSide(
              color: primaryGreen,
              width: 1.5,
            ),
          ),
        ),
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
        10,
        16,
        0,
      ),
      padding: const EdgeInsets.all(15),
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
                        fontSize: 14,
                        fontWeight:
                        FontWeight
                            .w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      'RM ${current.toStringAsFixed(2)}',
                      style:
                      const TextStyle(
                        color: textColor,
                        fontSize: 27,
                        fontWeight:
                        FontWeight
                            .bold,
                      ),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                      getSelectedFoodUnit(),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
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
                        11,
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
                        fontSize: 13,
                        fontWeight:
                        FontWeight
                            .bold,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    '${change > 0 ? '+' : change < 0 ? '-' : ''}'
                        'RM ${change.abs().toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isUp
                          ? Colors.red
                          : isDown
                          ? primaryGreen
                          : Colors.grey,
                      fontSize: 11,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$selectedPeriod Price Trend',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 210,
            width: double.infinity,
            child: trendData.isEmpty
                ? const Center(
              child: Text(
                'No trend data available',
                style:
                TextStyle(
                  color:
                  Colors.grey,
                  fontSize: 13,
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
          if (selectedPointIndex !=
              null &&
              selectedPointIndex! <
                  trendData.length)
            Container(
              width:
              double.infinity,
              margin:
              const EdgeInsets.only(
                top: 8,
              ),
              padding:
              const EdgeInsets.all(
                10,
              ),
              decoration:
              BoxDecoration(
                color: lightGreen,
                borderRadius:
                BorderRadius.circular(
                  11,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons
                        .touch_app_outlined,
                    color:
                    primaryGreen,
                    size: 18,
                  ),
                  const SizedBox(
                    width: 7,
                  ),
                  Expanded(
                    child: Text(
                      trendData[
                      selectedPointIndex!]
                      ['label']
                          .toString(),
                      style:
                      const TextStyle(
                        fontSize: 12,
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
                      fontSize: 13,
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
      padding:
      const EdgeInsets.fromLTRB(
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
              fontSize: 18,
              fontWeight:
              FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics:
            const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 9,
            mainAxisSpacing: 9,
            childAspectRatio: 2.35,
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
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(14),
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
            maxLines: 1,
            overflow:
            TextOverflow.ellipsis,
            style:
            const TextStyle(
              color: Colors.black54,
              fontSize: 11,
              fontWeight:
              FontWeight.w500,
            ),
          ),
          const SizedBox(
            height: 4,
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

  Widget buildMonthlyItems() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        20,
      ),
      padding: const EdgeInsets.all(14),
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
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.trending_up,
                color:
                primaryGreen,
                size: 20,
              ),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Monthly Food Price Changes',
                  style: TextStyle(
                    color:
                    textColor,
                    fontSize: 17,
                    fontWeight:
                    FontWeight
                        .w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 4,
          ),
          const Text(
            'Latest month compared with previous month',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(
            height: 10,
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
                  style:
                  TextStyle(
                    color:
                    Colors.grey,
                    fontSize: 12,
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

                return Container(
                  padding:
                  const EdgeInsets
                      .symmetric(
                    vertical: 9,
                  ),
                  decoration:
                  const BoxDecoration(
                    border: Border(
                      bottom:
                      BorderSide(
                        color: Color(
                          0xFFEEF1EF,
                        ),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
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
                        const Icon(
                          Icons
                              .restaurant_menu,
                          color:
                          primaryGreen,
                          size: 20,
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
                              item['item']?.toString() ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: textColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(
                              height: 3,
                            ),
                            Text(
                              item['unit']?.toString() ?? '',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        width: 6,
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
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      SizedBox(
                        width: 72,
                        child: Text(
                          'RM ${price.toStringAsFixed(2)}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: textColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
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
                        buildFoodSearch(),
                        buildFoodSelector(),
                        buildPeriodSelector(),
                        buildTrendCard(),
                        buildSummaryCards(),
                        buildMonthlyItems(),
                      ],
                    )
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
  Widget build(BuildContext context) {
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

            const leftPadding = 30.0;
            const rightPadding = 18.0;
            const pointInset = 10.0;

            final chartWidth =
                constraints.maxWidth -
                    leftPadding -
                    rightPadding;

            final usableWidth =
                chartWidth - pointInset * 2;

            final relativeX =
                details.localPosition.dx -
                    leftPadding -
                    pointInset;

            final spacing =
                usableWidth /
                    (data.length - 1);

            int index =
            spacing == 0
                ? 0
                : (relativeX / spacing)
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
              210,
            ),
            painter: TrendChartPainter(
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

    const left = 30.0;
    const right = 18.0;
    const top = 24.0;
    const bottom = 50.0;

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
        alpha: 0.22,
      )
      ..strokeWidth = 0.8;

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
          price
              .toStringAsFixed(
            2,
          ),
          style:
          const TextStyle(
            color:
            Color(
              0xFF555555,
            ),
            fontSize: 10,
            fontWeight:
            FontWeight
                .w500,
          ),
        ),
        textDirection:
        TextDirection.ltr,
      )..layout();

      priceText.paint(
        canvas,
        Offset(
          left - priceText.width - 7,
          y - priceText.height / 2,
        ),
      );
    }

    final List<Offset> points = [];

    const pointInset = 10.0;

    final usableWidth =
        chartWidth - pointInset * 2;

    for (
    int i = 0;
    i < data.length;
    i++
    ) {
      final price =
      data[i]['price'] as double;

      final x =
      data.length == 1
          ? left + chartWidth / 2
          : left +
          pointInset +
          usableWidth *
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

    final linePaint = Paint()
      ..color =
          _TrendPageState
              .primaryGreen
      ..strokeWidth = 2.8
      ..strokeCap =
          StrokeCap.round
      ..strokeJoin =
          StrokeJoin.round
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
        selected ? 6 : 4,
        Paint()
          ..color =
          selected
              ? Colors.white
              : _TrendPageState
              .primaryGreen,
      );

      if (selected) {
        canvas.drawCircle(
          points[i],
          4,
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

      if (data.length > 10) {
        showLabel =
            i == 0 ||
                i ==
                    data.length -
                        1 ||
                i % 3 == 0;
      } else if (
      data.length > 6) {
        showLabel =
            i == 0 ||
                i ==
                    data.length -
                        1 ||
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
              Color(
                0xFF555555,
              ),
              fontSize: 10,
              fontWeight:
              FontWeight
                  .w500,
            ),
          ),
          textDirection:
          TextDirection.ltr,
        )..layout();

        double labelX =
            points[i].dx -
                labelText.width / 2;

        final minimumX = left;

        final maximumX =
            size.width -
                right -
                labelText.width;

        if (labelX < minimumX) {
          labelX = minimumX;
        }

        if (labelX > maximumX) {
          labelX = maximumX;
        }

        labelText.paint(
          canvas,
          Offset(
            labelX,
            top +
                chartHeight +
                18,
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

    const boxWidth = 150.0;
    const boxHeight = 60.0;

    double left =
        point.dx -
            boxWidth / 2;

    if (left < 5) {
      left = 5;
    }

    if (left + boxWidth >
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
      const Radius.circular(
        8,
      ),
    );

    canvas.drawRRect(
      rectangle,
      Paint()
        ..color =
            Colors.white,
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
          fontSize: 11,
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
        left + 12,
        top + 10,
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
          fontSize: 12,
          fontWeight:
          FontWeight.w700,
        ),
      ),
      textDirection:
      TextDirection.ltr,
    )..layout();

    priceText.paint(
      canvas,
      Offset(
        left + 12,
        top + 34,
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
        oldDelegate
            .selectedIndex !=
            selectedIndex;
  }
}