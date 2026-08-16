import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/main_navigation_page.dart';

class FoodComparisonPage extends StatefulWidget {
  final int itemCode;
  final String itemName;
  final String unit;

  const FoodComparisonPage({
    super.key,
    required this.itemCode,
    required this.itemName,
    required this.unit,
  });

  @override
  State<FoodComparisonPage> createState() =>
      _FoodComparisonPageState();
}

class _FoodComparisonPageState
    extends State<FoodComparisonPage> {
  bool isLoading = true;

  List<Map<String, dynamic>> comparisonList = [];
  List<Map<String, dynamic>> dailyTrendList = [];

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
  }

  Future<void> fetchComparisonData() async {
    try {
      // =========================================================
      // GET FOOD INFORMATION
      // =========================================================

      final foodData = await Supabase.instance.client
          .from('food_items')
          .select()
          .eq(
        'item_code',
        widget.itemCode,
      )
          .maybeSingle();

      if (foodData != null) {
        category =
            foodData['item_category']?.toString() ?? '';
      }

      // =========================================================
      // GET PRICE RECORDS
      // =========================================================

      final priceData = await Supabase.instance.client
          .from('food_prices')
          .select()
          .eq(
        'item_code',
        widget.itemCode,
      )
          .order(
        'date',
        ascending: true,
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

      // =========================================================
      // GET PREMISE CODES
      // =========================================================

      final premiseCodes = priceData
          .map(
            (price) => price['premise_code'],
      )
          .toSet()
          .toList();

      // =========================================================
      // GET PREMISE INFORMATION
      // =========================================================

      final premiseData = await Supabase.instance.client
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

      // =========================================================
      // COMBINE PRICE + STORE
      // =========================================================

      List<Map<String, dynamic>> combinedList = [];

      for (final price in priceData) {
        final premise = premiseList.firstWhere(
              (premise) =>
          premise['premise_code'] ==
              price['premise_code'],
          orElse: () => {
            'premise': 'Unknown Premise',
            'state': '',
            'district': '',
          },
        );

        combinedList.add({
          'date': price['date'],
          'price': price['price'],
          'premise_code': price['premise_code'],
          'premise': premise['premise'],
          'state': premise['state'],
          'district': premise['district'],
        });
      }

      // =========================================================
      // SORT STORE PRICE LOWEST → HIGHEST
      // =========================================================

      combinedList.sort(
            (a, b) {
          final priceA = double.parse(
            a['price'].toString(),
          );

          final priceB = double.parse(
            b['price'].toString(),
          );

          return priceA.compareTo(priceB);
        },
      );

      // =========================================================
      // LOWEST / HIGHEST / AVERAGE
      // =========================================================

      final priceValues = combinedList
          .map(
            (item) => double.parse(
          item['price'].toString(),
        ),
      )
          .toList();

      final lowest = priceValues.first;
      final highest = priceValues.last;

      double total = 0;

      for (final price in priceValues) {
        total = total + price;
      }

      final average =
          total / priceValues.length;

      // =========================================================
      // DAILY TREND
      // =========================================================

      Map<String, List<double>> datePrices = {};

      for (final item in combinedList) {
        final date =
        item['date'].toString();

        final price = double.parse(
          item['price'].toString(),
        );

        if (!datePrices.containsKey(date)) {
          datePrices[date] = [];
        }

        datePrices[date]!.add(price);
      }

      List<Map<String, dynamic>> trendList = [];

      datePrices.forEach(
            (date, prices) {
          double dayTotal = 0;

          for (final price in prices) {
            dayTotal = dayTotal + price;
          }

          final dayAverage =
              dayTotal / prices.length;

          trendList.add({
            'date': date,
            'average': dayAverage,
          });
        },
      );

      trendList.sort(
            (a, b) {
          return a['date']
              .toString()
              .compareTo(
            b['date'].toString(),
          );
        },
      );

      // =========================================================
      // LATEST DATE
      // =========================================================

      String latest = '';

      if (trendList.isNotEmpty) {
        latest =
            trendList.last['date'].toString();
      }

      // =========================================================
      // TOTAL UNIQUE STORES
      // =========================================================

      final storeCount = combinedList
          .map(
            (item) => item['premise_code'],
      )
          .toSet()
          .length;

      if (!mounted) {
        return;
      }

      setState(() {
        comparisonList = combinedList;
        dailyTrendList = trendList;

        lowestPrice = lowest;
        highestPrice = highest;
        averagePrice = average;

        latestDate = latest;
        totalStores = storeCount;

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  void goToMainPage(int index) {
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

  // ============================================================
  // PRICE SUMMARY BOX
  // ============================================================

  Widget priceSummary({
    required String title,
    required double price,
    required String description,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            'RM ${price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            description,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DAILY TREND
  // ============================================================

  Widget buildTrendSection() {
    if (dailyTrendList.isEmpty) {
      return const Text(
        'No trend data available',
      );
    }

    double maximum = 0;

    for (final trend in dailyTrendList) {
      final value =
      trend['average'] as double;

      if (value > maximum) {
        maximum = value;
      }
    }

    return Column(
      children: [
        for (final trend in dailyTrendList)
          Padding(
            padding:
            const EdgeInsets.symmetric(
              vertical: 5,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: Text(
                    trend['date'],
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ),

                Expanded(
                  child: LinearProgressIndicator(
                    value: maximum == 0
                        ? 0
                        : trend['average'] /
                        maximum,
                    minHeight: 8,
                    borderRadius:
                    BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(width: 10),

                SizedBox(
                  width: 65,
                  child: Text(
                    'RM ${trend['average'].toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7F1),

      appBar: AppBar(
        title: const Text(
          'Food Details',
        ),

        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context)
                  .showSnackBar(
                const SnackBar(
                  content: Text(
                    'Favourite function will be added later',
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.favorite_border,
            ),
          ),
        ],
      ),

      body: isLoading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : comparisonList.isEmpty
          ? const Center(
        child: Text(
          'No food price data found',
        ),
      )
          : SingleChildScrollView(
        padding:
        const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [
            // =================================================
            // FOOD HEADER
            // =================================================

            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color:
                Colors.green.shade700,
                borderRadius:
                BorderRadius.circular(
                  18,
                ),
              ),

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [
                  Container(
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),

                    decoration:
                    BoxDecoration(
                      color: Colors.white
                          .withOpacity(
                        0.20,
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
                        fontWeight:
                        FontWeight.bold,
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
                      fontSize: 25,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    widget.unit,
                    style:
                    const TextStyle(
                      color:
                      Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            // =================================================
            // MAIN PRICE CARD
            // =================================================

            Card(
              child: Padding(
                padding:
                const EdgeInsets.all(
                  18,
                ),

                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

                  children: [
                    const Text(
                      'Average Price (All Stores)',
                      style:
                      TextStyle(
                        color:
                        Colors.grey,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      'RM ${averagePrice.toStringAsFixed(2)}',
                      style:
                      const TextStyle(
                        fontSize: 32,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    Text(
                      'RM/${widget.unit}',
                      style:
                      const TextStyle(
                        color:
                        Colors.grey,
                      ),
                    ),

                    const Divider(
                      height: 30,
                    ),

                    Row(
                      children: [
                        priceSummary(
                          title:
                          'Cheapest',
                          price:
                          lowestPrice,
                          description:
                          comparisonList
                              .first[
                          'premise'],
                        ),

                        const SizedBox(
                          height: 70,
                          child:
                          VerticalDivider(),
                        ),

                        priceSummary(
                          title:
                          'Average',
                          price:
                          averagePrice,
                          description:
                          'All Stores',
                        ),

                        const SizedBox(
                          height: 70,
                          child:
                          VerticalDivider(),
                        ),

                        priceSummary(
                          title:
                          'Highest',
                          price:
                          highestPrice,
                          description:
                          comparisonList
                              .last[
                          'premise'],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            // =================================================
            // UPDATED + STORE COUNT
            // =================================================

            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 17,
                ),

                const SizedBox(
                  width: 5,
                ),

                Text(
                  'Updated $latestDate',
                ),

                const SizedBox(
                  width: 20,
                ),

                const Icon(
                  Icons.store,
                  size: 17,
                ),

                const SizedBox(
                  width: 5,
                ),

                Text(
                  '$totalStores Stores',
                ),
              ],
            ),

            const SizedBox(
              height: 18,
            ),

            // =================================================
            // PRICE TREND
            // =================================================

            Card(
              child: Padding(
                padding:
                const EdgeInsets.all(
                  16,
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
                              .show_chart,
                          color:
                          Colors.green,
                        ),

                        SizedBox(
                          width: 8,
                        ),

                        Text(
                          'Price Trend',
                          style:
                          TextStyle(
                            fontSize: 18,
                            fontWeight:
                            FontWeight
                                .bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    buildTrendSection(),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            // =================================================
            // PRICE BY STORE
            // =================================================

            const Text(
              'Price by Store',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            ListView.builder(
              shrinkWrap: true,

              physics:
              const NeverScrollableScrollPhysics(),

              itemCount:
              comparisonList.length >
                  10
                  ? 10
                  : comparisonList
                  .length,

              itemBuilder:
                  (context, index) {
                final store =
                comparisonList[index];

                return Card(
                  margin:
                  const EdgeInsets.only(
                    bottom: 8,
                  ),

                  child: ListTile(
                    leading:
                    CircleAvatar(
                      child: Text(
                        '${index + 1}',
                      ),
                    ),

                    title: Text(
                      store['premise'],
                      style:
                      const TextStyle(
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    subtitle: Text(
                      '${store['district']}, ${store['state']}\n'
                          '${store['date']}',
                    ),

                    trailing: Text(
                      'RM ${double.parse(store['price'].toString()).toStringAsFixed(2)}',
                      style:
                      const TextStyle(
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),

      // =========================================================
      // SAME BOTTOM NAVIGATION
      // =========================================================

      bottomNavigationBar:
      BottomNavigationBar(
        type: BottomNavigationBarType.fixed,

        currentIndex: 1,

        onTap: (index) {
          goToMainPage(index);
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(
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
              Icons.favorite,
            ),
            label: 'Saved',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.person,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}