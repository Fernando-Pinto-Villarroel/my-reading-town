import 'dart:math';
import 'package:my_reading_town/app_constants.dart';

enum StoreItemType { resource, powerup, gems, pack, species }

enum ResourceType { coins, wood, metal }

enum PowerupType { book, sandwich, hammer, glasses }

class StoreResourceItem {
  final ResourceType resource;
  final int amount;
  final int gemCost;
  final String id;

  const StoreResourceItem({
    required this.resource,
    required this.amount,
    required this.gemCost,
    required this.id,
  });
}

class StorePowerupItem {
  final PowerupType powerup;
  final int quantity;
  final int gemCost;
  final String id;

  const StorePowerupItem({
    required this.powerup,
    required this.quantity,
    required this.gemCost,
    required this.id,
  });
}

class StoreGemsItem {
  final int gems;
  final double basePrice;
  final String productId;

  const StoreGemsItem({
    required this.gems,
    required this.basePrice,
    required this.productId,
  });
}

class StorePack {
  final String id;
  final String productId;
  final int coins;
  final int wood;
  final int metal;
  final int gems;
  final int bookPowerups;
  final int sandwichPowerups;
  final int hammerPowerups;
  final int glassesPowerups;
  final double basePrice;
  final int savingsPercent;
  final String colorHex;

  const StorePack({
    required this.id,
    required this.productId,
    required this.coins,
    required this.wood,
    required this.metal,
    required this.gems,
    required this.bookPowerups,
    required this.sandwichPowerups,
    required this.hammerPowerups,
    required this.glassesPowerups,
    required this.basePrice,
    required this.savingsPercent,
    required this.colorHex,
  });
}

class DiscountInfo {
  final double percent;
  final String labelKey;
  final DateTime endsAt;

  const DiscountInfo({
    required this.percent,
    required this.labelKey,
    required this.endsAt,
  });

  Duration get timeRemaining {
    final rem = endsAt.difference(DateTime.now());
    return rem.isNegative ? Duration.zero : rem;
  }
}

class StoreRules {
  static const List<StoreResourceItem> coinItems = [
    StoreResourceItem(id: 'coins_50', resource: ResourceType.coins, amount: 50, gemCost: 10),
    StoreResourceItem(id: 'coins_100', resource: ResourceType.coins, amount: 100, gemCost: 18),
    StoreResourceItem(id: 'coins_200', resource: ResourceType.coins, amount: 200, gemCost: 35),
    StoreResourceItem(id: 'coins_500', resource: ResourceType.coins, amount: 500, gemCost: 80),
  ];

  static const List<StoreResourceItem> woodItems = [
    StoreResourceItem(id: 'wood_50', resource: ResourceType.wood, amount: 50, gemCost: 8),
    StoreResourceItem(id: 'wood_100', resource: ResourceType.wood, amount: 100, gemCost: 15),
    StoreResourceItem(id: 'wood_200', resource: ResourceType.wood, amount: 200, gemCost: 28),
    StoreResourceItem(id: 'wood_500', resource: ResourceType.wood, amount: 500, gemCost: 65),
  ];

  static const List<StoreResourceItem> metalItems = [
    StoreResourceItem(id: 'metal_30', resource: ResourceType.metal, amount: 30, gemCost: 8),
    StoreResourceItem(id: 'metal_60', resource: ResourceType.metal, amount: 60, gemCost: 15),
    StoreResourceItem(id: 'metal_120', resource: ResourceType.metal, amount: 120, gemCost: 28),
    StoreResourceItem(id: 'metal_300', resource: ResourceType.metal, amount: 300, gemCost: 65),
  ];

  static const List<StorePowerupItem> bookItems = [
    StorePowerupItem(id: 'book_1', powerup: PowerupType.book, quantity: 1, gemCost: 5),
    StorePowerupItem(id: 'book_3', powerup: PowerupType.book, quantity: 3, gemCost: 12),
    StorePowerupItem(id: 'book_5', powerup: PowerupType.book, quantity: 5, gemCost: 18),
    StorePowerupItem(id: 'book_10', powerup: PowerupType.book, quantity: 10, gemCost: 30),
  ];

  static const List<StorePowerupItem> sandwichItems = [
    StorePowerupItem(id: 'sandwich_1', powerup: PowerupType.sandwich, quantity: 1, gemCost: 5),
    StorePowerupItem(id: 'sandwich_3', powerup: PowerupType.sandwich, quantity: 3, gemCost: 12),
    StorePowerupItem(id: 'sandwich_5', powerup: PowerupType.sandwich, quantity: 5, gemCost: 18),
    StorePowerupItem(id: 'sandwich_10', powerup: PowerupType.sandwich, quantity: 10, gemCost: 30),
  ];

  static const List<StorePowerupItem> hammerItems = [
    StorePowerupItem(id: 'hammer_1', powerup: PowerupType.hammer, quantity: 1, gemCost: 8),
    StorePowerupItem(id: 'hammer_3', powerup: PowerupType.hammer, quantity: 3, gemCost: 20),
    StorePowerupItem(id: 'hammer_5', powerup: PowerupType.hammer, quantity: 5, gemCost: 35),
    StorePowerupItem(id: 'hammer_10', powerup: PowerupType.hammer, quantity: 10, gemCost: 60),
  ];

  static const List<StorePowerupItem> glassesItems = [
    StorePowerupItem(id: 'glasses_1', powerup: PowerupType.glasses, quantity: 1, gemCost: 10),
    StorePowerupItem(id: 'glasses_3', powerup: PowerupType.glasses, quantity: 3, gemCost: 25),
    StorePowerupItem(id: 'glasses_5', powerup: PowerupType.glasses, quantity: 5, gemCost: 40),
    StorePowerupItem(id: 'glasses_10', powerup: PowerupType.glasses, quantity: 10, gemCost: 75),
  ];

  static const List<StoreGemsItem> gemsItems = [
    StoreGemsItem(gems: 50, basePrice: 0.99, productId: 'gems_50'),
    StoreGemsItem(gems: 100, basePrice: 1.99, productId: 'gems_100'),
    StoreGemsItem(gems: 200, basePrice: 3.99, productId: 'gems_200'),
    StoreGemsItem(gems: 500, basePrice: 8.99, productId: 'gems_500'),
    StoreGemsItem(gems: 1000, basePrice: 16.99, productId: 'gems_1000'),
    StoreGemsItem(gems: 2000, basePrice: 29.99, productId: 'gems_2000'),
  ];

  static const List<StorePack> packs = [
    StorePack(
      id: 'pack_starter',
      productId: 'pack_starter',
      coins: 50,
      wood: 30,
      metal: 10,
      gems: 0,
      bookPowerups: 0,
      sandwichPowerups: 1,
      hammerPowerups: 0,
      glassesPowerups: 0,
      basePrice: 1.49,
      savingsPercent: 20,
      colorHex: 'FFB3BA',
    ),
    StorePack(
      id: 'pack_builder',
      productId: 'pack_builder',
      coins: 100,
      wood: 100,
      metal: 50,
      gems: 0,
      bookPowerups: 0,
      sandwichPowerups: 0,
      hammerPowerups: 2,
      glassesPowerups: 0,
      basePrice: 2.99,
      savingsPercent: 25,
      colorHex: 'FFD700',
    ),
    StorePack(
      id: 'pack_reader',
      productId: 'pack_reader',
      coins: 200,
      wood: 0,
      metal: 0,
      gems: 50,
      bookPowerups: 3,
      sandwichPowerups: 0,
      hammerPowerups: 0,
      glassesPowerups: 3,
      basePrice: 4.99,
      savingsPercent: 30,
      colorHex: 'B5B3FF',
    ),
    StorePack(
      id: 'pack_town',
      productId: 'pack_town',
      coins: 500,
      wood: 200,
      metal: 100,
      gems: 100,
      bookPowerups: 0,
      sandwichPowerups: 5,
      hammerPowerups: 5,
      glassesPowerups: 0,
      basePrice: 9.99,
      savingsPercent: 35,
      colorHex: 'B3FFD9',
    ),
    StorePack(
      id: 'pack_mega',
      productId: 'pack_mega',
      coins: 1000,
      wood: 500,
      metal: 200,
      gems: 200,
      bookPowerups: 10,
      sandwichPowerups: 10,
      hammerPowerups: 10,
      glassesPowerups: 10,
      basePrice: 19.99,
      savingsPercent: 40,
      colorHex: 'FFCDD2',
    ),
  ];

  static const double discountMinThreshold = 5.0;

  static const List<_DiscountEvent> _events = [
    _DiscountEvent(startMonth: 1,  startDay: 1,  endMonth: 1,  endDay: 3,  labelKey: 'discount_new_year',    maxPct: 25),
    _DiscountEvent(startMonth: 2,  startDay: 13, endMonth: 2,  endDay: 15, labelKey: 'discount_valentines',  maxPct: 20),
    _DiscountEvent(startMonth: 7,  startDay: 1,  endMonth: 7,  endDay: 7,  labelKey: 'discount_summer',      maxPct: 20),
    _DiscountEvent(startMonth: 10, startDay: 29, endMonth: 10, endDay: 31, labelKey: 'discount_halloween',   maxPct: 30),
    _DiscountEvent(startMonth: 11, startDay: 25, endMonth: 11, endDay: 30, labelKey: 'discount_black_friday',maxPct: 40),
    _DiscountEvent(startMonth: 12, startDay: 22, endMonth: 12, endDay: 26, labelKey: 'discount_christmas',   maxPct: 50),
  ];

  static Map<String, DiscountInfo> computeDiscounts() {
    final now = DateTime.now();
    _DiscountEvent? active;
    DateTime? endsAt;

    if (AppConstants.testMode) {
      active = _events.last;
      endsAt = now.add(const Duration(days: 1));
    } else {
      for (final event in _events) {
        final start = DateTime(now.year, event.startMonth, event.startDay);
        final end = DateTime(now.year, event.endMonth, event.endDay, 23, 59, 59);
        if (now.isAfter(start) && now.isBefore(end)) {
          active = event;
          endsAt = end;
          break;
        }
      }
      if (active == null) return {};
    }

    final rng = Random(active.startMonth * 100 + active.startDay);
    final result = <String, DiscountInfo>{};

    for (final item in gemsItems) {
      if (item.basePrice >= discountMinThreshold) {
        final pct = 5 + rng.nextInt(active.maxPct - 4);
        result[item.productId] = DiscountInfo(
          percent: pct.toDouble(),
          labelKey: active.labelKey,
          endsAt: endsAt!,
        );
      }
    }

    for (final pack in packs) {
      if (pack.basePrice >= discountMinThreshold) {
        final pct = 5 + rng.nextInt(active.maxPct - 4);
        result[pack.productId] = DiscountInfo(
          percent: pct.toDouble(),
          labelKey: active.labelKey,
          endsAt: endsAt!,
        );
      }
    }

    return result;
  }

  static double applyDiscount(double basePrice, double discountPercent) {
    return basePrice * (1.0 - discountPercent / 100.0);
  }

  static String inventoryTypeForPowerup(PowerupType powerup) {
    switch (powerup) {
      case PowerupType.book:
        return 'book_happiness';
      case PowerupType.sandwich:
        return 'sandwich_speed';
      case PowerupType.hammer:
        return 'hammer_constructor';
      case PowerupType.glasses:
        return 'glasses_reading';
    }
  }
}

class _DiscountEvent {
  final int startMonth;
  final int startDay;
  final int endMonth;
  final int endDay;
  final String labelKey;
  final int maxPct;

  const _DiscountEvent({
    required this.startMonth,
    required this.startDay,
    required this.endMonth,
    required this.endDay,
    required this.labelKey,
    required this.maxPct,
  });
}
