import 'package:intl/intl.dart';
import 'app_time.dart';

abstract final class AppFormatters {
  static final _currency = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );
  static final _dateTime = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');

  static String currencyText(String decimal) {
    final normalized = decimal.contains(',')
        ? decimal.replaceAll('.', '').replaceAll(',', '.')
        : decimal;
    return _currency.format(num.tryParse(normalized) ?? 0);
  }

  static String dateTime(DateTime? value) => value == null
      ? 'Não informado'
      : _dateTime.format(AppTime.inSaoPaulo(value));
}
