/// Client-side validation. The backend validates every one of these again -
/// this exists only to give the user immediate feedback.
class Validators {
  const Validators._();

  static final RegExp _emailPattern =
      RegExp(r'^[\w.\-+]+@([\w\-]+\.)+[A-Za-z]{2,}$');
  static final RegExp _phonePattern = RegExp(r'^\+?[0-9\s-]{7,20}$');

  static String? requiredField(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  static String? email(String? value, {bool required = false}) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) {
      return required ? 'Email is required' : null;
    }
    if (!_emailPattern.hasMatch(text)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    final String text = value ?? '';
    if (text.isEmpty) {
      return 'Password is required';
    }
    if (text.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  static String? phone(String? value, {bool required = true}) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) {
      return required ? 'Phone is required' : null;
    }
    if (!_phonePattern.hasMatch(text)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  static String? numeric(String? value, String label) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    if (double.tryParse(text) == null) {
      return '$label must be a number';
    }
    return null;
  }

  static String? integer(String? value, String label) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    if (int.tryParse(text) == null) {
      return '$label must be a whole number';
    }
    return null;
  }

  static String? budgetRange(String? min, String? max) {
    final double? minValue = double.tryParse(min?.trim() ?? '');
    final double? maxValue = double.tryParse(max?.trim() ?? '');
    if (minValue != null && maxValue != null && maxValue < minValue) {
      return 'Maximum budget must be greater than minimum budget';
    }
    return null;
  }
}
