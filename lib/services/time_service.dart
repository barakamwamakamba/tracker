class TimeService {
  static int timeTominutes({required int hour, required int minute}) {
    return (hour * 60) + minute;
  }

  static String minutesTotime(int? minutes) {
    if (minutes == null) {
      return '--:--';
    }

    final hour = minutes ~/ 60;
    final minute = minutes % 60;

    final hourString = hour.toString().padLeft(2, '0');
    final minuteString = minute.toString().padLeft(2, '0');

    return '$hourString:$minuteString';
  }
}
