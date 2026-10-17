import 'package:timezone/timezone.dart' as tz;

abstract final class AppTime {
  static final location = tz.getLocation('America/Sao_Paulo');

  static tz.TZDateTime inSaoPaulo(DateTime instant) =>
      tz.TZDateTime.from(instant.toUtc(), location);

  static DateTime wallClockToUtc(DateTime value) => tz.TZDateTime(
    location,
    value.year,
    value.month,
    value.day,
    value.hour,
    value.minute,
    value.second,
    value.millisecond,
    value.microsecond,
  ).toUtc();
}
