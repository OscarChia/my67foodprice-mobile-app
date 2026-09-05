import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_database_service.dart';

class DatabaseService {
  final SupabaseClient supabase = Supabase.instance.client;
  final LocalDatabaseService localDatabaseService =
  LocalDatabaseService();

  Future<AuthResponse> registerUser({
    required String name,
    required String gender,
    required String dateOfBirth,
    required String email,
    required String password,
  }) async {
    final response =
    await supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'gender': gender,
        'date_of_birth': dateOfBirth,
      },
    );

    return response;
  }

  Future<AuthResponse> loginUser({
    required String email,
    required String password,
  }) async {
    final response =
    await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    return response;
  }

  Future<void> logoutUser() async {
    await supabase.auth.signOut();
  }

  Future<void> resetPassword(
      String email,
      ) async {
    await supabase.auth.resetPasswordForEmail(
      email,
    );
  }

  User? getCurrentUser() {
    return supabase.auth.currentUser;
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final user = getCurrentUser();

    if (user == null) {
      return null;
    }

    final data = await supabase
        .from('profiles')
        .select(
      'name, gender, date_of_birth, price_alerts, alert_threshold, saved_item_alert',
    )
        .eq(
      'id',
      user.id,
    )
        .maybeSingle();

    return data;
  }

  Future<void> updateProfile({
    required String name,
  }) async {
    final user = getCurrentUser();

    if (user == null) {
      return;
    }

    await supabase
        .from('profiles')
        .update({
      'name': name,
    })
        .eq(
      'id',
      user.id,
    );

    await supabase.auth.updateUser(
      UserAttributes(
        data: {
          'name': name,
        },
      ),
    );
  }

  Future<void> updatePassword(
      String password,
      ) async {
    await supabase.auth.updateUser(
      UserAttributes(
        password: password,
      ),
    );
  }

  Future<void> updatePriceAlerts(
      bool value,
      ) async {
    final user = getCurrentUser();

    if (user == null) {
      return;
    }

    await supabase
        .from('profiles')
        .update({
      'price_alerts': value,
    })
        .eq(
      'id',
      user.id,
    );
  }

  Future<void> updateSavedItemAlert(
      bool value,
      ) async {
    final user = getCurrentUser();

    if (user == null) {
      return;
    }

    await supabase
        .from('profiles')
        .update({
      'saved_item_alert': value,
    })
        .eq(
      'id',
      user.id,
    );
  }

  Future<void> updateAlertThreshold(
      double value,
      ) async {
    final user = getCurrentUser();

    if (user == null) {
      return;
    }

    await supabase
        .from('profiles')
        .update({
      'alert_threshold': value,
    })
        .eq(
      'id',
      user.id,
    );
  }

  Future<void> submitAppRating({
    required int rating,
    required String feedback,
  }) async {
    final user = getCurrentUser();

    if (user == null) {
      return;
    }

    await supabase
        .from('app_ratings')
        .insert({
      'user_id': user.id,
      'rating': rating,
      'feedback': feedback,
    });
  }

  Future<List<Map<String, dynamic>>>
  getHomeFoodData() async {
    final latestDateData = await supabase
        .from('food_prices')
        .select('date')
        .order(
      'date',
      ascending: false,
    )
        .limit(1);

    if (latestDateData.isEmpty) {
      return [];
    }

    final latestDate =
    latestDateData.first['date'].toString();

    final priceData = await supabase
        .from('food_prices')
        .select(
      'item_code, price, date',
    )
        .eq(
      'date',
      latestDate,
    )
        .limit(60);

    if (priceData.isEmpty) {
      return [];
    }

    final Map<int, Map<String, dynamic>>
    priceMap = {};

    for (final price in priceData) {
      final itemCode = int.tryParse(
        price['item_code'].toString(),
      );

      if (itemCode == null) {
        continue;
      }

      if (!priceMap.containsKey(itemCode)) {
        priceMap[itemCode] =
        Map<String, dynamic>.from(
          price,
        );
      }

      if (priceMap.length >= 15) {
        break;
      }
    }

    if (priceMap.isEmpty) {
      return [];
    }

    final foodData = await supabase
        .from('food_items')
        .select(
      'item_code, item, item_category, unit',
    )
        .inFilter(
      'item_code',
      priceMap.keys.toList(),
    );

    final List<Map<String, dynamic>>
    combinedList = [];

    for (final food in foodData) {
      final itemCode = int.tryParse(
        food['item_code'].toString(),
      );

      if (itemCode == null) {
        continue;
      }

      final price = priceMap[itemCode];

      if (price == null) {
        continue;
      }

      combinedList.add({
        'item_code': itemCode,
        'item':
        food['item'] ?? 'Unknown Item',
        'category':
        food['item_category'] ?? '',
        'unit':
        food['unit'] ?? '',
        'price':
        price['price'],
        'date':
        price['date'],
      });

      if (combinedList.length >= 8) {
        break;
      }
    }

    return combinedList;
  }

  Future<Set<int>> getSavedItemCodes() async {
    final user = getCurrentUser();

    if (user == null) {
      return {};
    }

    try {
      final data = await supabase
          .from('saved_items')
          .select('item_code')
          .eq(
        'user_id',
        user.id,
      );

      return data
          .map<int?>(
            (row) => int.tryParse(
          row['item_code'].toString(),
        ),
      )
          .whereType<int>()
          .toSet();
    } catch (e) {
      return {};
    }
  }

  Future<bool> getDefaultSavedItemAlert() async {
    final user = getCurrentUser();

    if (user == null) {
      return true;
    }

    final data = await supabase
        .from('profiles')
        .select(
      'saved_item_alert',
    )
        .eq(
      'id',
      user.id,
    )
        .maybeSingle();

    if (data == null) {
      return true;
    }

    return data['saved_item_alert'] == true;
  }

  Future<void> addSavedItem(
      int itemCode,
      bool alertEnabled,
      ) async {
    final user = getCurrentUser();

    if (user == null) {
      return;
    }

    await supabase
        .from('saved_items')
        .insert({
      'user_id': user.id,
      'item_code': itemCode,
      'alert_enabled': alertEnabled,
    });
  }

  Future<void> removeSavedItemByCode(
      int itemCode,
      ) async {
    final user = getCurrentUser();

    if (user == null) {
      return;
    }

    await supabase
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
  }

  Future<List<String>> getStates() async {
    final data = await supabase
        .from('premises')
        .select('state');

    final stateList = data
        .map(
          (row) =>
      row['state']?.toString() ?? '',
    )
        .where(
          (state) => state.isNotEmpty,
    )
        .toSet()
        .toList();

    stateList.sort();

    return [
      'All States',
      ...stateList,
    ];
  }

  Future<List<Map<String, dynamic>>>
  getFoodItems() async {
    final List<Map<String, dynamic>>
    allFoodItems = [];

    const batchSize = 500;

    int from = 0;

    while (true) {
      final data = await supabase
          .from('food_items')
          .select(
        'item_code, item, unit, item_category',
      )
          .order(
        'item_code',
        ascending: true,
      )
          .range(
        from,
        from + batchSize - 1,
      );

      final rows =
      List<Map<String, dynamic>>.from(
        data,
      );

      allFoodItems.addAll(
        rows,
      );

      if (rows.length < batchSize) {
        break;
      }

      from += batchSize;
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

    return allFoodItems;
  }

  Future<List<Map<String, dynamic>>>
  getPremisesByState(
      String state,
      ) async {
    final data = await supabase
        .from('premises')
        .select(
      'premise_code, premise, state, district',
    )
        .eq(
      'state',
      state,
    );

    return List<Map<String, dynamic>>.from(
      data,
    );
  }

  Future<List<Map<String, dynamic>>>
  getPremisesByCodes(
      List<dynamic> premiseCodes,
      ) async {
    if (premiseCodes.isEmpty) {
      return [];
    }

    final data = await supabase
        .from('premises')
        .select(
      'premise_code, premise, state, district',
    )
        .inFilter(
      'premise_code',
      premiseCodes,
    );

    return List<Map<String, dynamic>>.from(
      data,
    );
  }

  Future<List<Map<String, dynamic>>>
  getFoodPrices({
    required List<dynamic> itemCodes,
    List<dynamic>? premiseCodes,
  }) async {
    if (itemCodes.isEmpty) {
      return [];
    }

    final List<Map<String, dynamic>>
    allPriceData = [];

    const itemBatchSize = 100;
    const premiseBatchSize = 100;

    if (premiseCodes != null &&
        premiseCodes.isNotEmpty) {
      for (
      int i = 0;
      i < itemCodes.length;
      i += itemBatchSize
      ) {
        final itemEnd =
        i + itemBatchSize < itemCodes.length
            ? i + itemBatchSize
            : itemCodes.length;

        final itemBatch =
        itemCodes.sublist(
          i,
          itemEnd,
        );

        for (
        int j = 0;
        j < premiseCodes.length;
        j += premiseBatchSize
        ) {
          final premiseEnd =
          j + premiseBatchSize <
              premiseCodes.length
              ? j + premiseBatchSize
              : premiseCodes.length;

          final premiseBatch =
          premiseCodes.sublist(
            j,
            premiseEnd,
          );

          final data = await supabase
              .from('food_prices')
              .select(
            'item_code, premise_code, date, price',
          )
              .inFilter(
            'item_code',
            itemBatch,
          )
              .inFilter(
            'premise_code',
            premiseBatch,
          )
              .order(
            'date',
            ascending: false,
          );

          allPriceData.addAll(
            List<Map<String, dynamic>>.from(
              data,
            ),
          );
        }
      }

      return allPriceData;
    }

    for (
    int i = 0;
    i < itemCodes.length;
    i += itemBatchSize
    ) {
      final end =
      i + itemBatchSize < itemCodes.length
          ? i + itemBatchSize
          : itemCodes.length;

      final batch =
      itemCodes.sublist(
        i,
        end,
      );

      final data = await supabase
          .from('food_prices')
          .select(
        'item_code, premise_code, date, price',
      )
          .inFilter(
        'item_code',
        batch,
      )
          .order(
        'date',
        ascending: false,
      );

      allPriceData.addAll(
        List<Map<String, dynamic>>.from(
          data,
        ),
      );
    }

    return allPriceData;
  }

  Future<List<Map<String, dynamic>>>
  getMapFoodItems() async {
    final priceData = await supabase
        .from('monthly_food_price_avg')
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
      return [];
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

      final data = await supabase
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

    return allFoodItems;
  }

  Future<List<Map<String, dynamic>>>
  getMapFoodPrices(
      int itemCode,
      ) async {
    final data = await supabase
        .from('food_prices')
        .select()
        .eq(
      'item_code',
      itemCode,
    )
        .order(
      'date',
      ascending: false,
    )
        .limit(5000);

    return List<Map<String, dynamic>>.from(
      data,
    );
  }

  Future<List<Map<String, dynamic>>>
  getMapPremisesByCodes(
      List<dynamic> premiseCodes,
      ) async {
    if (premiseCodes.isEmpty) {
      return [];
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

      final data = await supabase
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

    return premises;
  }

  Future<List<Map<String, dynamic>>>
  getTrendFoodItems() async {
    final priceData = await supabase
        .from('monthly_food_price_avg')
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
      return [];
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

        return nameA.compareTo(
          nameB,
        );
      },
    );

    return allFoodItems;
  }

  Future<List<Map<String, dynamic>>>
  getDailyTrend(
      int itemCode,
      ) async {
    final data = await supabase
        .from(
      'daily_food_price_avg',
    )
        .select(
      'date, avg_price',
    )
        .eq(
      'item_code',
      itemCode,
    )
        .order(
      'date',
      ascending: false,
    )
        .limit(15);

    return List<Map<String, dynamic>>.from(
      data,
    );
  }

  Future<List<Map<String, dynamic>>>
  getWeeklyTrend(
      int itemCode,
      ) async {
    final data = await supabase
        .from(
      'weekly_food_price_avg',
    )
        .select(
      'month, week_number, start_date, end_date, avg_price',
    )
        .eq(
      'item_code',
      itemCode,
    )
        .order(
      'month',
      ascending: true,
    )
        .order(
      'week_number',
      ascending: true,
    );

    return List<Map<String, dynamic>>.from(
      data,
    );
  }

  Future<List<Map<String, dynamic>>>
  getMonthlyTrend(
      int itemCode,
      ) async {
    final data = await supabase
        .from(
      'monthly_food_price_avg',
    )
        .select(
      'month, start_date, end_date, avg_price',
    )
        .eq(
      'item_code',
      itemCode,
    )
        .order(
      'month',
      ascending: true,
    );

    return List<Map<String, dynamic>>.from(
      data,
    );
  }

  Future<List<Map<String, dynamic>>>
  getLatestMonthData() async {
    final data = await supabase
        .from(
      'monthly_food_price_avg',
    )
        .select(
      'month',
    )
        .order(
      'month',
      ascending: false,
    )
        .limit(1);

    return List<Map<String, dynamic>>.from(
      data,
    );
  }

  Future<List<Map<String, dynamic>>>
  getMonthlyPrices(
      String month,
      ) async {
    final data = await supabase
        .from(
      'monthly_food_price_avg',
    )
        .select(
      'item_code, avg_price',
    )
        .eq(
      'month',
      month,
    );

    return List<Map<String, dynamic>>.from(
      data,
    );
  }

  Future<Map<String, dynamic>?>
  getSavedPageProfile() async {
    final user = getCurrentUser();

    if (user == null) {
      return null;
    }

    final data = await supabase
        .from('profiles')
        .select(
      'price_alerts, alert_threshold',
    )
        .eq(
      'id',
      user.id,
    )
        .maybeSingle();

    return data;
  }

  Future<List<Map<String, dynamic>>>
  getUserSavedItems() async {
    final user = getCurrentUser();

    if (user == null) {
      return [];
    }

    final data = await supabase
        .from('saved_items')
        .select(
      'id, item_code, alert_enabled, created_at',
    )
        .eq(
      'user_id',
      user.id,
    )
        .order(
      'created_at',
      ascending: false,
    );

    return List<Map<String, dynamic>>.from(
      data,
    );
  }

  Future<List<Map<String, dynamic>>>
  getSavedFoodItems(
      List<int> itemCodes,
      ) async {
    if (itemCodes.isEmpty) {
      return [];
    }

    final data = await supabase
        .from('food_items')
        .select(
      'item_code, item, item_category, unit',
    )
        .inFilter(
      'item_code',
      itemCodes,
    );

    return List<Map<String, dynamic>>.from(
      data,
    );
  }

  Future<List<Map<String, dynamic>>>
  getSavedPriceChanges(
      List<int> itemCodes,
      ) async {
    if (itemCodes.isEmpty) {
      return [];
    }

    final data = await supabase.rpc(
      'get_saved_price_changes',
      params: {
        'p_item_codes': itemCodes,
      },
    );

    return List<Map<String, dynamic>>.from(
      data,
    );
  }

  Future<void> removeSavedItemById(
      int savedId,
      ) async {
    await supabase
        .from('saved_items')
        .delete()
        .eq(
      'id',
      savedId,
    );
  }

  Future<void> updateSavedFoodAlert({
    required int savedId,
    required bool value,
  }) async {
    await supabase
        .from('saved_items')
        .update({
      'alert_enabled': value,
    })
        .eq(
      'id',
      savedId,
    );
  }

  Future<List<Map<String, dynamic>>>
  getShoppingList() async {
    final user = getCurrentUser();

    if (user == null) {
      return [];
    }

    final data =
    await localDatabaseService
        .getShoppingList(
      user.id,
    );

    return data.map(
          (row) {
        return {
          ...row,
          'is_bought':
          row['is_bought'] == 1,
        };
      },
    ).toList();
  }

  Future<void> addToShoppingList(
      int itemCode,
      dynamic premiseCode, {
        String item = '',
        String category = '',
        String unit = '',
        double price = 0,
        String date = '',
        String premise = '',
        String state = '',
        String district = '',
      }) async {
    final user = getCurrentUser();

    if (user == null) {
      throw Exception(
        'User is not logged in.',
      );
    }

    await localDatabaseService
        .addShoppingItem(
      userId: user.id,
      itemCode: itemCode,
      premiseCode: premiseCode,
      item: item,
      category: category,
      unit: unit,
      price: price,
      date: date,
      premise: premise,
      state: state,
      district: district,
    );

    try {
      await syncShoppingList();
    } catch (e) {
      return;
    }
  }

  Future<void> updateShoppingListQuantity(
      int shoppingId,
      int quantity,
      ) async {
    if (quantity < 1) {
      return;
    }

    await localDatabaseService
        .updateShoppingListQuantity(
      shoppingId,
      quantity,
    );

    try {
      await syncShoppingList();
    } catch (e) {
      return;
    }
  }

  Future<void> updateShoppingListBought(
      int shoppingId,
      bool isBought,
      ) async {
    await localDatabaseService
        .updateShoppingListBought(
      shoppingId,
      isBought,
    );

    try {
      await syncShoppingList();
    } catch (e) {
      return;
    }
  }

  Future<void> removeShoppingListItem(
      int shoppingId,
      ) async {
    await localDatabaseService
        .removeShoppingListItem(
      shoppingId,
    );

    try {
      await syncShoppingList();
    } catch (e) {
      return;
    }
  }

  Future<void> clearBoughtShoppingItems()
  async {
    final user = getCurrentUser();

    if (user == null) {
      return;
    }

    await localDatabaseService
        .clearBoughtShoppingItems(
      user.id,
    );

    try {
      await syncShoppingList();
    } catch (e) {
      return;
    }
  }

  Future<void> clearShoppingList() async {
    final user = getCurrentUser();

    if (user == null) {
      return;
    }

    await localDatabaseService
        .clearShoppingList(
      user.id,
    );

    try {
      await syncShoppingList();
    } catch (e) {
      return;
    }
  }

  Future<void> removeFromShoppingList(
      int itemCode,
      dynamic premiseCode,
      ) async {
    final user = getCurrentUser();

    if (user == null) {
      return;
    }

    await localDatabaseService
        .removeShoppingListByFood(
      userId: user.id,
      itemCode: itemCode,
      premiseCode: premiseCode,
    );

    try {
      await syncShoppingList();
    } catch (e) {
      return;
    }
  }

  Future<void>
  removeFromShoppingListByItemCode(
      int itemCode,
      ) async {
    final user = getCurrentUser();

    if (user == null) {
      return;
    }

    await localDatabaseService
        .removeShoppingListByItemCode(
      userId: user.id,
      itemCode: itemCode,
    );

    try {
      await syncShoppingList();
    } catch (e) {
      return;
    }
  }

  Future<void> syncShoppingList() async {
    final user = getCurrentUser();

    if (user == null) {
      return;
    }

    final pendingItems =
    await localDatabaseService
        .getPendingShoppingItems(
      user.id,
    );

    for (final localItem in pendingItems) {
      final localId = int.tryParse(
        localItem['id'].toString(),
      );

      final itemCode = int.tryParse(
        localItem['item_code'].toString(),
      );

      final premiseCode =
      localItem['premise_code'];

      if (localId == null ||
          itemCode == null ||
          premiseCode == null) {
        continue;
      }

      final isDeleted =
          localItem['is_deleted'] == 1;

      if (isDeleted) {
        await supabase
            .from('shopping_list')
            .delete()
            .eq(
          'user_id',
          user.id,
        )
            .eq(
          'item_code',
          itemCode,
        )
            .eq(
          'premise_code',
          premiseCode,
        );

        await localDatabaseService
            .permanentlyDeleteShoppingItem(
          localId,
        );

        continue;
      }

      final quantity = int.tryParse(
        localItem['quantity'].toString(),
      ) ??
          1;

      final isBought =
          localItem['is_bought'] == 1;

      final existing = await supabase
          .from('shopping_list')
          .select('id')
          .eq(
        'user_id',
        user.id,
      )
          .eq(
        'item_code',
        itemCode,
      )
          .eq(
        'premise_code',
        premiseCode,
      )
          .maybeSingle();

      if (existing == null) {
        final inserted = await supabase
            .from('shopping_list')
            .insert({
          'user_id': user.id,
          'item_code': itemCode,
          'premise_code': premiseCode,
          'quantity': quantity,
          'is_bought': isBought,
        })
            .select('id')
            .single();

        await localDatabaseService
            .markShoppingItemSynced(
          localId: localId,
          serverId: int.tryParse(
            inserted['id'].toString(),
          ),
        );
      } else {
        await supabase
            .from('shopping_list')
            .update({
          'quantity': quantity,
          'is_bought': isBought,
        })
            .eq(
          'id',
          existing['id'],
        );

        await localDatabaseService
            .markShoppingItemSynced(
          localId: localId,
          serverId: int.tryParse(
            existing['id'].toString(),
          ),
        );
      }
    }
  }

  Future<void>
  refreshShoppingListFromServer()
  async {
    final user = getCurrentUser();

    if (user == null) {
      return;
    }

    await syncShoppingList();

    final shoppingData = await supabase
        .from('shopping_list')
        .select(
      'id, item_code, premise_code, quantity, is_bought, created_at',
    )
        .eq(
      'user_id',
      user.id,
    )
        .order(
      'created_at',
      ascending: false,
    );

    if (shoppingData.isEmpty) {
      return;
    }

    final itemCodes = shoppingData
        .map<int?>(
          (row) => int.tryParse(
        row['item_code'].toString(),
      ),
    )
        .whereType<int>()
        .toSet()
        .toList();

    final premiseCodes = shoppingData
        .map(
          (row) => row['premise_code'],
    )
        .where(
          (code) => code != null,
    )
        .toSet()
        .toList();

    if (itemCodes.isEmpty ||
        premiseCodes.isEmpty) {
      return;
    }

    final results = await Future.wait([
      getShoppingListFoodItems(
        itemCodes,
      ),
      getShoppingListPriceData(
        itemCodes: itemCodes,
        premiseCodes: premiseCodes,
      ),
      getPremisesByCodes(
        premiseCodes,
      ),
    ]);

    final foodData = results[0];
    final priceData = results[1];
    final premiseData = results[2];

    final Map<int, Map<String, dynamic>>
    foodMap = {};

    for (final food in foodData) {
      final itemCode = int.tryParse(
        food['item_code'].toString(),
      );

      if (itemCode != null) {
        foodMap[itemCode] =
        Map<String, dynamic>.from(
          food,
        );
      }
    }

    final Map<String, Map<String, dynamic>>
    premiseMap = {};

    for (final premise in premiseData) {
      final premiseCode =
      premise['premise_code']
          ?.toString();

      if (premiseCode != null) {
        premiseMap[premiseCode] =
        Map<String, dynamic>.from(
          premise,
        );
      }
    }

    final Map<String, Map<String, dynamic>>
    latestPriceMap = {};

    for (final priceRow in priceData) {
      final itemCode = int.tryParse(
        priceRow['item_code'].toString(),
      );

      final premiseCode =
      priceRow['premise_code']
          ?.toString();

      if (itemCode == null ||
          premiseCode == null) {
        continue;
      }

      final key =
          '${itemCode}_$premiseCode';

      if (!latestPriceMap
          .containsKey(key)) {
        latestPriceMap[key] =
        Map<String, dynamic>.from(
          priceRow,
        );
      }
    }

    for (final shopping in shoppingData) {
      final serverId = int.tryParse(
        shopping['id'].toString(),
      );

      final itemCode = int.tryParse(
        shopping['item_code'].toString(),
      );

      final premiseCode =
      shopping['premise_code'];

      if (serverId == null ||
          itemCode == null ||
          premiseCode == null) {
        continue;
      }

      final food =
      foodMap[itemCode];

      if (food == null) {
        continue;
      }

      final premise =
      premiseMap[
      premiseCode.toString()];

      final priceRow =
      latestPriceMap[
      '${itemCode}_${premiseCode.toString()}'];

      final quantity = int.tryParse(
        shopping['quantity'].toString(),
      ) ??
          1;

      final price = double.tryParse(
        priceRow?['price']
            ?.toString() ??
            '',
      ) ??
          0;

      await localDatabaseService
          .saveServerShoppingItem(
        userId: user.id,
        serverId: serverId,
        itemCode: itemCode,
        premiseCode: premiseCode,
        item:
        food['item']?.toString() ??
            'Unknown Item',
        category:
        food['item_category']
            ?.toString() ??
            '',
        unit:
        food['unit']?.toString() ??
            '',
        quantity: quantity,
        isBought:
        shopping['is_bought'] == true,
        price: price,
        date:
        priceRow?['date']
            ?.toString() ??
            '',
        premise:
        premise?['premise']
            ?.toString() ??
            'Unknown Premise',
        state:
        premise?['state']
            ?.toString() ??
            '',
        district:
        premise?['district']
            ?.toString() ??
            '',
      );
    }
  }

  Future<List<Map<String, dynamic>>>
  getShoppingListPriceData({
    required List<int> itemCodes,
    required List<dynamic> premiseCodes,
  }) async {
    if (itemCodes.isEmpty ||
        premiseCodes.isEmpty) {
      return [];
    }

    final data = await supabase
        .from('food_prices')
        .select(
      'item_code, premise_code, price, date',
    )
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
    );

    return List<Map<String, dynamic>>.from(
      data,
    );
  }

  Future<List<Map<String, dynamic>>>
  getShoppingListFoodItems(
      List<int> itemCodes,
      ) async {
    if (itemCodes.isEmpty) {
      return [];
    }

    final data = await supabase
        .from('food_items')
        .select(
      'item_code, item, unit, item_category',
    )
        .inFilter(
      'item_code',
      itemCodes,
    );

    return List<Map<String, dynamic>>.from(
      data,
    );
  }

  Future<List<Map<String, dynamic>>>
  getShoppingListPrices(
      List<int> itemCodes,
      ) async {
    if (itemCodes.isEmpty) {
      return [];
    }

    final data = await supabase
        .from('daily_food_price_avg')
        .select(
      'item_code, date, avg_price',
    )
        .inFilter(
      'item_code',
      itemCodes,
    )
        .order(
      'date',
      ascending: false,
    );

    final Map<int, Map<String, dynamic>>
    latestPriceMap = {};

    for (final row in data) {
      final itemCode = int.tryParse(
        row['item_code'].toString(),
      );

      if (itemCode == null) {
        continue;
      }

      if (!latestPriceMap
          .containsKey(itemCode)) {
        latestPriceMap[itemCode] =
        Map<String, dynamic>.from(
          row,
        );
      }
    }

    return latestPriceMap.values.toList();
  }
}