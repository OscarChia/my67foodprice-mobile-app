import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabaseService {
  static Database? _database;

  Future<Database> getDatabase() async {
    if (_database != null) {
      return _database!;
    }

    final databasePath =
    await getDatabasesPath();

    final path = join(
      databasePath,
      'my67food.db',
    );

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          '''
          CREATE TABLE shopping_list (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            server_id INTEGER,
            user_id TEXT NOT NULL,
            item_code INTEGER NOT NULL,
            premise_code INTEGER NOT NULL,
            item TEXT NOT NULL DEFAULT '',
            category TEXT NOT NULL DEFAULT '',
            unit TEXT NOT NULL DEFAULT '',
            quantity INTEGER NOT NULL DEFAULT 1,
            is_bought INTEGER NOT NULL DEFAULT 0,
            price REAL NOT NULL DEFAULT 0,
            date TEXT NOT NULL DEFAULT '',
            premise TEXT NOT NULL DEFAULT '',
            state TEXT NOT NULL DEFAULT '',
            district TEXT NOT NULL DEFAULT '',
            sync_status INTEGER NOT NULL DEFAULT 0,
            is_deleted INTEGER NOT NULL DEFAULT 0,
            UNIQUE(user_id, item_code, premise_code)
          )
          ''',
        );
      },
    );

    return _database!;
  }

  Future<List<Map<String, dynamic>>> getShoppingList(
      String userId,
      ) async {
    final db = await getDatabase();

    final data = await db.query(
      'shopping_list',
      where: 'user_id = ? AND is_deleted = ?',
      whereArgs: [
        userId,
        0,
      ],
      orderBy: 'id DESC',
    );

    return List<Map<String, dynamic>>.from(
      data,
    );
  }

  Future<Map<String, dynamic>?> getShoppingItem({
    required String userId,
    required int itemCode,
    required dynamic premiseCode,
  }) async {
    final db = await getDatabase();

    final data = await db.query(
      'shopping_list',
      where:
      'user_id = ? AND item_code = ? AND premise_code = ?',
      whereArgs: [
        userId,
        itemCode,
        premiseCode,
      ],
      limit: 1,
    );

    if (data.isEmpty) {
      return null;
    }

    return Map<String, dynamic>.from(
      data.first,
    );
  }

  Future<int> addShoppingItem({
    required String userId,
    required int itemCode,
    required dynamic premiseCode,
    required String item,
    required String category,
    required String unit,
    required double price,
    required String date,
    required String premise,
    required String state,
    required String district,
  }) async {
    final db = await getDatabase();

    final existing = await getShoppingItem(
      userId: userId,
      itemCode: itemCode,
      premiseCode: premiseCode,
    );

    if (existing != null) {
      final localId = int.tryParse(
        existing['id'].toString(),
      );

      if (localId == null) {
        return 0;
      }

      await db.update(
        'shopping_list',
        {
          'item': item,
          'category': category,
          'unit': unit,
          'price': price,
          'date': date,
          'premise': premise,
          'state': state,
          'district': district,
          'is_bought': 0,
          'is_deleted': 0,
          'sync_status': 1,
        },
        where: 'id = ?',
        whereArgs: [
          localId,
        ],
      );

      return localId;
    }

    return db.insert(
      'shopping_list',
      {
        'user_id': userId,
        'item_code': itemCode,
        'premise_code': premiseCode,
        'item': item,
        'category': category,
        'unit': unit,
        'quantity': 1,
        'is_bought': 0,
        'price': price,
        'date': date,
        'premise': premise,
        'state': state,
        'district': district,
        'sync_status': 1,
        'is_deleted': 0,
      },
    );
  }

  Future<void> updateShoppingListQuantity(
      int localId,
      int quantity,
      ) async {
    if (quantity < 1) {
      return;
    }

    final db = await getDatabase();

    await db.update(
      'shopping_list',
      {
        'quantity': quantity,
        'sync_status': 1,
      },
      where: 'id = ?',
      whereArgs: [
        localId,
      ],
    );
  }

  Future<void> updateShoppingListBought(
      int localId,
      bool isBought,
      ) async {
    final db = await getDatabase();

    await db.update(
      'shopping_list',
      {
        'is_bought': isBought ? 1 : 0,
        'sync_status': 1,
      },
      where: 'id = ?',
      whereArgs: [
        localId,
      ],
    );
  }

  Future<void> removeShoppingListItem(
      int localId,
      ) async {
    final db = await getDatabase();

    await db.update(
      'shopping_list',
      {
        'is_deleted': 1,
        'sync_status': 1,
      },
      where: 'id = ?',
      whereArgs: [
        localId,
      ],
    );
  }

  Future<void> removeShoppingListByFood({
    required String userId,
    required int itemCode,
    required dynamic premiseCode,
  }) async {
    final db = await getDatabase();

    await db.update(
      'shopping_list',
      {
        'is_deleted': 1,
        'sync_status': 1,
      },
      where:
      'user_id = ? AND item_code = ? AND premise_code = ?',
      whereArgs: [
        userId,
        itemCode,
        premiseCode,
      ],
    );
  }

  Future<void> removeShoppingListByItemCode({
    required String userId,
    required int itemCode,
  }) async {
    final db = await getDatabase();

    await db.update(
      'shopping_list',
      {
        'is_deleted': 1,
        'sync_status': 1,
      },
      where:
      'user_id = ? AND item_code = ?',
      whereArgs: [
        userId,
        itemCode,
      ],
    );
  }

  Future<void> clearBoughtShoppingItems(
      String userId,
      ) async {
    final db = await getDatabase();

    await db.update(
      'shopping_list',
      {
        'is_deleted': 1,
        'sync_status': 1,
      },
      where:
      'user_id = ? AND is_bought = ? AND is_deleted = ?',
      whereArgs: [
        userId,
        1,
        0,
      ],
    );
  }

  Future<void> clearShoppingList(
      String userId,
      ) async {
    final db = await getDatabase();

    await db.update(
      'shopping_list',
      {
        'is_deleted': 1,
        'sync_status': 1,
      },
      where:
      'user_id = ? AND is_deleted = ?',
      whereArgs: [
        userId,
        0,
      ],
    );
  }

  Future<List<Map<String, dynamic>>>
  getPendingShoppingItems(
      String userId,
      ) async {
    final db = await getDatabase();

    final data = await db.query(
      'shopping_list',
      where:
      'user_id = ? AND sync_status = ?',
      whereArgs: [
        userId,
        1,
      ],
      orderBy: 'id ASC',
    );

    return List<Map<String, dynamic>>.from(
      data,
    );
  }

  Future<void> markShoppingItemSynced({
    required int localId,
    required int? serverId,
  }) async {
    final db = await getDatabase();

    await db.update(
      'shopping_list',
      {
        'server_id': serverId,
        'sync_status': 0,
      },
      where: 'id = ?',
      whereArgs: [
        localId,
      ],
    );
  }

  Future<void> permanentlyDeleteShoppingItem(
      int localId,
      ) async {
    final db = await getDatabase();

    await db.delete(
      'shopping_list',
      where: 'id = ?',
      whereArgs: [
        localId,
      ],
    );
  }

  Future<void> saveServerShoppingItem({
    required String userId,
    required int serverId,
    required int itemCode,
    required dynamic premiseCode,
    required String item,
    required String category,
    required String unit,
    required int quantity,
    required bool isBought,
    required double price,
    required String date,
    required String premise,
    required String state,
    required String district,
  }) async {
    final db = await getDatabase();

    final existing = await getShoppingItem(
      userId: userId,
      itemCode: itemCode,
      premiseCode: premiseCode,
    );

    if (existing != null) {
      if (existing['sync_status'] == 1) {
        return;
      }

      await db.update(
        'shopping_list',
        {
          'server_id': serverId,
          'item': item,
          'category': category,
          'unit': unit,
          'quantity': quantity,
          'is_bought': isBought ? 1 : 0,
          'price': price,
          'date': date,
          'premise': premise,
          'state': state,
          'district': district,
          'sync_status': 0,
          'is_deleted': 0,
        },
        where: 'id = ?',
        whereArgs: [
          existing['id'],
        ],
      );

      return;
    }

    await db.insert(
      'shopping_list',
      {
        'server_id': serverId,
        'user_id': userId,
        'item_code': itemCode,
        'premise_code': premiseCode,
        'item': item,
        'category': category,
        'unit': unit,
        'quantity': quantity,
        'is_bought': isBought ? 1 : 0,
        'price': price,
        'date': date,
        'premise': premise,
        'state': state,
        'district': district,
        'sync_status': 0,
        'is_deleted': 0,
      },
    );
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}