import 'package:intl/intl.dart';

String formatAmount(double amount, String currency) {
  final symbol = _currencySymbol(currency);
  final formatter = NumberFormat.currency(symbol: symbol, decimalDigits: 2);
  return formatter.format(amount);
}

String formatDate(DateTime date) {
  return DateFormat('MMM d, yyyy').format(date);
}

String formatDateTime(DateTime date) {
  return DateFormat('MMM d, h:mm a').format(date);
}

String _currencySymbol(String currency) {
  switch (currency.toUpperCase()) {
    case 'USD':
      return r'$';
    case 'EUR':
      return 'EUR ';
    case 'GBP':
      return 'GBP ';
    case 'QAR':
      return 'QAR ';
    case 'SAR':
      return 'SAR ';
    case 'AED':
      return 'AED ';
    case 'INR':
      return 'INR ';
    default:
      return '${currency.toUpperCase()} ';
  }
}