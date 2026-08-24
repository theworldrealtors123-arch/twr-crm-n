import 'package:intl/intl.dart';

class Formatters {
  const Formatters._();

  static final NumberFormat _compact = NumberFormat.compact(locale: 'en');
  static final DateFormat _dayMonth = DateFormat('dd MMM');
  static final DateFormat _dayMonthTime = DateFormat('dd MMM hh:mm a');
  static final DateFormat _fullDate = DateFormat('dd MMM yyyy');

  /// AED 1.5M / AED 850K / AED 0
  static String currency(double? value) {
    if (value == null) {
      return '-';
    }
    if (value >= 1000000) {
      final double millions = value / 1000000;
      final String text = millions % 1 == 0
          ? millions.toStringAsFixed(0)
          : millions.toStringAsFixed(1);
      return 'AED ${text}M';
    }
    if (value >= 1000) {
      return 'AED ${(value / 1000).toStringAsFixed(0)}K';
    }
    return 'AED ${_compact.format(value)}';
  }

  static String budgetRange(double? min, double? max) {
    if (min == null && max == null) {
      return 'Budget not set';
    }
    if (min != null && max != null) {
      if (min == max) {
        return currency(min);
      }
      return '${currency(min)} - ${currency(max)}';
    }
    return currency(min ?? max);
  }

  static String requirement({String? propertyType, int? bedrooms}) {
    final List<String> parts = <String>[];
    if (bedrooms != null && bedrooms > 0) {
      parts.add('$bedrooms Bedroom');
    }
    if (propertyType != null && propertyType.isNotEmpty) {
      parts.add(propertyType[0] + propertyType.substring(1).toLowerCase());
    }
    return parts.isEmpty ? 'Requirement not set' : parts.join(' ');
  }

  static String date(DateTime? value) =>
      value == null ? '-' : _fullDate.format(value);

  static String shortDate(DateTime? value) =>
      value == null ? '-' : _dayMonth.format(value);

  static String timestamp(DateTime? value) =>
      value == null ? '-' : _dayMonthTime.format(value);

  static String relative(DateTime? value) {
    if (value == null) {
      return '-';
    }
    final Duration diff = DateTime.now().difference(value);
    if (diff.inMinutes < 1) {
      return 'Just now';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }
    return _dayMonth.format(value);
  }

  static String greeting(DateTime now) {
    final int hour = now.hour;
    if (hour < 12) {
      return 'Good Morning';
    }
    if (hour < 17) {
      return 'Good Afternoon';
    }
    return 'Good Evening';
  }
}
