import 'package:intl/intl.dart';

// Inside your widget
String formatDate(String dateStr) {
  try {
    DateTime date = DateTime.parse(dateStr); // Parse the ISO string
    return DateFormat('dd MMM yyyy, hh:mm a').format(date); // Format
  } catch (e) {
    return dateStr; // fallback if parsing fails
  }
}
