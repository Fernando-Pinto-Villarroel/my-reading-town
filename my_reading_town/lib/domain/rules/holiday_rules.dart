import 'package:my_reading_town/domain/entities/mission.dart';

class HolidayEvent {
  final String id;
  final MissionBranch branch;
  final int startMonth;
  final int startDay;
  final int endMonth;
  final int endDay;

  const HolidayEvent({
    required this.id,
    required this.branch,
    required this.startMonth,
    required this.startDay,
    required this.endMonth,
    required this.endDay,
  });

  bool isActive(DateTime now) {
    final start = DateTime(now.year, startMonth, startDay);
    final end = DateTime(now.year, endMonth, endDay, 23, 59, 59);
    return !now.isBefore(start) && !now.isAfter(end);
  }

  DateTime eventEnd(DateTime now) =>
      DateTime(now.year, endMonth, endDay, 23, 59, 59);

  int daysRemaining(DateTime now) {
    final end = DateTime(now.year, endMonth, endDay, 23, 59, 59);
    final diff = end.difference(DateTime(now.year, now.month, now.day));
    return diff.inDays.clamp(0, 9999);
  }
}

class HolidayRules {
  static const List<HolidayEvent> allEvents = [
    HolidayEvent(
      id: 'halloween',
      branch: MissionBranch.halloween,
      startMonth: 10,
      startDay: 1,
      endMonth: 10,
      endDay: 31,
    ),
    HolidayEvent(
      id: 'christmas',
      branch: MissionBranch.christmas,
      startMonth: 12,
      startDay: 1,
      endMonth: 12,
      endDay: 31,
    ),
    HolidayEvent(
      id: 'easter',
      branch: MissionBranch.easter,
      startMonth: 4,
      startDay: 1,
      endMonth: 4,
      endDay: 30,
    ),
  ];

  static bool isHolidayBranch(MissionBranch branch) =>
      allEvents.any((e) => e.branch == branch);

  static HolidayEvent? eventForBranch(MissionBranch branch) {
    try {
      return allEvents.firstWhere((e) => e.branch == branch);
    } catch (_) {
      return null;
    }
  }

  static List<HolidayEvent> activeEvents(DateTime now) =>
      allEvents.where((e) => e.isActive(now)).toList();

  static String eventMonthRangeKey(HolidayEvent event) => event.id;
}
