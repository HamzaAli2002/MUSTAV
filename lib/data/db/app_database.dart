import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/addon.dart';
import '../../models/burger.dart';
import '../../models/cart_item.dart';
import '../../models/enums.dart';
import '../../models/order.dart';
import '../../models/store_location.dart';

/// Single source of truth for all local persistence. Every write (cart edits,
/// order placement, menu caching) goes through here so nothing is ever lost
/// on app kill (spec 3.2, 3.5).
class AppDatabase {
  AppDatabase._internal();
  static final AppDatabase instance = AppDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = join(dir, 'mustav.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE menu_items (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            imageUrl TEXT NOT NULL,
            priceRs INTEGER NOT NULL,
            prepTimeMinLow INTEGER NOT NULL,
            prepTimeMinHigh INTEGER NOT NULL,
            spiceLevel TEXT NOT NULL,
            bunType TEXT NOT NULL,
            pattyType TEXT NOT NULL,
            calories INTEGER NOT NULL,
            proteinG INTEGER NOT NULL,
            description TEXT NOT NULL,
            cachedAt INTEGER NOT NULL,
            resolvedPhotoUrl TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE locations (
            city TEXT PRIMARY KEY,
            address TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            imageUrl TEXT NOT NULL,
            tagline TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE cart_items (
            cartItemId TEXT PRIMARY KEY,
            burgerId TEXT NOT NULL,
            quantity INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE cart_item_addons (
            cartItemId TEXT NOT NULL,
            addOnId TEXT NOT NULL,
            PRIMARY KEY (cartItemId, addOnId)
          )
        ''');
        await db.execute('''
          CREATE TABLE orders (
            orderId TEXT PRIMARY KEY,
            city TEXT NOT NULL,
            status TEXT NOT NULL,
            placedAt INTEGER NOT NULL,
            deliveryFeeRs INTEGER NOT NULL DEFAULT 50
          )
        ''');
        await db.execute('''
          CREATE TABLE order_items (
            orderItemId TEXT PRIMARY KEY,
            orderId TEXT NOT NULL,
            burgerId TEXT NOT NULL,
            quantity INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE order_item_addons (
            orderItemId TEXT NOT NULL,
            addOnId TEXT NOT NULL,
            PRIMARY KEY (orderItemId, addOnId)
          )
        ''');
        await db.execute('''
          CREATE TABLE app_meta (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute(
                'ALTER TABLE orders ADD COLUMN deliveryFeeRs INTEGER NOT NULL DEFAULT 50');
          } catch (_) {}
          try {
            await db.execute(
                'ALTER TABLE menu_items ADD COLUMN resolvedPhotoUrl TEXT');
          } catch (_) {}
        }
      },
    );
  }

  // ---------------- Menu cache (spec 3.5) ----------------

  Future<void> cacheMenu(List<Burger> burgers) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final batch = db.batch();
    for (final b in burgers) {
      batch.insert(
        'menu_items',
        {...b.toMap(), 'cachedAt': now},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Burger>> readCachedMenu() async {
    final db = await database;
    final rows = await db.query('menu_items', orderBy: 'name ASC');
    return rows.map(Burger.fromMap).toList();
  }

  Future<void> updateResolvedPhotoUrl(String burgerId, String photoUrl) async {
    final db = await database;
    await db.update('menu_items', {'resolvedPhotoUrl': photoUrl},
        where: 'id = ?', whereArgs: [burgerId]);
  }

  Future<DateTime?> menuCachedAt() async {
    final db = await database;
    final rows = await db.query('menu_items',
        columns: ['cachedAt'], orderBy: 'cachedAt DESC', limit: 1);
    if (rows.isEmpty) return null;
    return DateTime.fromMillisecondsSinceEpoch(rows.first['cachedAt'] as int);
  }

  // ---------------- Locations cache ----------------

  Future<void> cacheLocations(List<StoreLocation> stores) async {
    final db = await database;
    final batch = db.batch();
    for (final s in stores) {
      batch.insert('locations', s.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<StoreLocation>> readLocations() async {
    final db = await database;
    final rows = await db.query('locations');
    return rows.map(StoreLocation.fromMap).toList();
  }

  // ---------------- Cart (spec 3.2 — survives app kill) ----------------

  Future<void> upsertCartItem(CartItem item) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('cart_items', item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.delete('cart_item_addons',
          where: 'cartItemId = ?', whereArgs: [item.cartItemId]);
      for (final addOn in item.addOns) {
        await txn.insert('cart_item_addons',
            {'cartItemId': item.cartItemId, 'addOnId': addOn.id});
      }
    });
  }

  Future<void> removeCartItem(String cartItemId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('cart_items',
          where: 'cartItemId = ?', whereArgs: [cartItemId]);
      await txn.delete('cart_item_addons',
          where: 'cartItemId = ?', whereArgs: [cartItemId]);
    });
  }

  Future<void> clearCart() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('cart_items');
      await txn.delete('cart_item_addons');
    });
  }

  /// Reads the full cart back, resolving burgers/add-ons from the menu cache.
  Future<List<CartItem>> readCart(List<Burger> menuById) async {
    final db = await database;
    final rows = await db.query('cart_items');
    final result = <CartItem>[];
    for (final row in rows) {
      final burgerId = row['burgerId'] as String;
      final burger = menuById.where((b) => b.id == burgerId).firstOrNull;
      if (burger == null)
        continue; // burger no longer in menu cache — skip defensively
      final addOnRows = await db.query(
        'cart_item_addons',
        where: 'cartItemId = ?',
        whereArgs: [row['cartItemId']],
      );
      final addOns = addOnRows
          .map((r) => AddOnCatalog.byId(r['addOnId'] as String))
          .toList();
      result.add(CartItem.fromMap(row, burger: burger, addOns: addOns));
    }
    return result;
  }

  // ---------------- App meta (selected location, etc.) ----------------

  Future<void> setMeta(String key, String value) async {
    final db = await database;
    await db.insert('app_meta', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getMeta(String key) async {
    final db = await database;
    final rows = await db.query('app_meta', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String;
  }

  // ---------------- Orders ----------------

  Future<void> saveOrder(Order order) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('orders', {
        'orderId': order.orderId,
        'city': order.location.city.name,
        'status': order.status.name,
        'placedAt': order.placedAt.millisecondsSinceEpoch,
        'deliveryFeeRs': order.deliveryFeeRs,
      });
      for (final item in order.items) {
        final orderItemId = '${order.orderId}_${item.cartItemId}';
        await txn.insert('order_items', {
          'orderItemId': orderItemId,
          'orderId': order.orderId,
          'burgerId': item.burger.id,
          'quantity': item.quantity,
        });
        for (final addOn in item.addOns) {
          await txn.insert('order_item_addons',
              {'orderItemId': orderItemId, 'addOnId': addOn.id});
        }
      }
    });
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    final db = await database;
    await db.update('orders', {'status': status.name},
        where: 'orderId = ?', whereArgs: [orderId]);
  }

  Future<Order?> readLatestOrder(
      List<Burger> menuById, List<StoreLocation> stores) async {
    final db = await database;
    final orderRows =
        await db.query('orders', orderBy: 'placedAt DESC', limit: 1);
    if (orderRows.isEmpty) return null;
    final orderRow = orderRows.first;
    final orderId = orderRow['orderId'] as String;
    final itemRows = await db
        .query('order_items', where: 'orderId = ?', whereArgs: [orderId]);
    final items = <CartItem>[];
    for (final row in itemRows) {
      final burger = menuById.where((b) => b.id == row['burgerId']).firstOrNull;
      if (burger == null) continue;
      final addOnRows = await db.query(
        'order_item_addons',
        where: 'orderItemId = ?',
        whereArgs: [row['orderItemId']],
      );
      final addOns = addOnRows
          .map((r) => AddOnCatalog.byId(r['addOnId'] as String))
          .toList();
      items.add(CartItem(
        cartItemId: row['orderItemId'] as String,
        burger: burger,
        addOns: addOns,
        quantity: row['quantity'] as int,
      ));
    }
    final location = stores.firstWhere((s) => s.city.name == orderRow['city']);
    return Order(
      orderId: orderId,
      items: items,
      location: location,
      status: OrderStatus.fromDb(orderRow['status'] as String),
      placedAt:
          DateTime.fromMillisecondsSinceEpoch(orderRow['placedAt'] as int),
      deliveryFeeRs: (orderRow['deliveryFeeRs'] as int?) ?? kBaseDeliveryFeeRs,
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
