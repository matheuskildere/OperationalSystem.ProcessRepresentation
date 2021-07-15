import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

class Formatter {
  static String moneySettings(String value, {String leadingSymbol = 'R\$'}) {
    return toCurrencyString(value,
        leadingSymbol: leadingSymbol,
        useSymbolPadding: true,
        thousandSeparator: ThousandSeparator.Period);
  }

  static String phoneWithOutFormatter(String phone) {
    return phone
        .replaceAll('(', '')
        .replaceAll(')', '')
        .replaceAll('-', '')
        .trim();
  }

  static String cpfWithOutFormatter(String cpf) {
    return cpf
        .replaceAll('.', '')
        .replaceAll('-', '')
        .trim();
  }
}
