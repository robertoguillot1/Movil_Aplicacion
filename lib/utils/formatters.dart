import 'package:intl/intl.dart';

String formatCurrency(double value) {
  final format = NumberFormat.currency(locale: 'es_CO', symbol: '\$');
  return format.format(value);
}

String formatDate(DateTime date) {
  final format = DateFormat('dd/MM/yyyy – hh:mm a');
  return format.format(date);
}
