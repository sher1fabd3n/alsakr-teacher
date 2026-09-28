/// Validates Egyptian National ID numbers (14 digits).
class NationalIdValidator {
  NationalIdValidator._();

  static final _digitsOnly = RegExp(r'^\d{14}$');

  /// Returns `true` when [id] is a valid 14-digit Egyptian National ID.
  static bool isValid(String? id) {
    if (id == null) return false;
    final trimmed = id.trim();
    if (trimmed.isEmpty) return false;
    return _digitsOnly.hasMatch(trimmed);
  }

  /// Returns an Arabic validation message, or `null` when valid.
  static String? validationMessage(String? id) {
    if (id == null) return 'الرقم القومي مطلوب';
    final trimmed = id.trim();
    if (trimmed.isEmpty) return 'الرقم القومي مطلوب';
    if (trimmed != id && id.trim().isEmpty) {
      return 'الرقم القومي لا يمكن أن يكون مسافات فقط';
    }
    if (RegExp(r'[A-Za-z]').hasMatch(trimmed)) {
      return 'الرقم القومي لا يمكن أن يحتوي على حروف';
    }
    if (RegExp(r'[^0-9]').hasMatch(trimmed)) {
      return 'الرقم القومي لا يمكن أن يحتوي على رموز';
    }
    if (trimmed.length != 14) {
      return 'الرقم القومي يجب أن يكون 14 رقمًا بالضبط';
    }
    return null;
  }

  /// Normalizes a national ID by trimming whitespace.
  static String? normalize(String? id) {
    if (id == null) return null;
    final trimmed = id.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
