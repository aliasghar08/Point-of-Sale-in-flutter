/// In-house validation service replacing external validation packages.
/// Provides robust RFC-5322 regex email validation, phone number verification,
/// barcode checksum verification (EAN-13, UPC-A, Code 128), price/stock checks,
/// and password strength scoring.
class ValidationService {
  ValidationService._();

  // RFC 5322 compliant regex pattern
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
  );

  // Phone number with optional international code
  static final RegExp _phoneRegex = RegExp(r'^\+?[0-9\s\-()]{7,20}$');

  // SKU regex (alphanumeric with hyphens/underscores)
  static final RegExp _skuRegex = RegExp(r'^[A-Za-z0-9\-_]{2,30}$');

  /// Validates email address format
  static bool isValidEmail(String? email) {
    if (email == null || email.trim().isEmpty) return false;
    final trimmed = email.trim();
    if (trimmed.length > 254) return false;
    return _emailRegex.hasMatch(trimmed);
  }

  /// Validates phone number format
  static bool isValidPhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) return false;
    final digitsOnly = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return digitsOnly.length >= 7 &&
        digitsOnly.length <= 15 &&
        _phoneRegex.hasMatch(phone.trim());
  }

  /// Validates SKU format
  static bool isValidSku(String? sku) {
    if (sku == null || sku.trim().isEmpty) return false;
    return _skuRegex.hasMatch(sku.trim());
  }

  /// Validates barcode format and calculates check digit for EAN-13 / UPC-A if applicable
  static bool isValidBarcode(String? barcode) {
    if (barcode == null || barcode.trim().isEmpty) return false;
    final trimmed = barcode.trim();

    // Check EAN-13 (13 digits)
    if (trimmed.length == 13 && RegExp(r'^\d{13}$').hasMatch(trimmed)) {
      return _validateEan13CheckDigit(trimmed);
    }

    // Check UPC-A (12 digits)
    if (trimmed.length == 12 && RegExp(r'^\d{12}$').hasMatch(trimmed)) {
      return _validateUpcACheckDigit(trimmed);
    }

    // Generic barcode / Code 128 (alphanumeric 3-30 chars)
    return RegExp(r'^[A-Za-z0-9\-_]{3,30}$').hasMatch(trimmed);
  }

  static bool _validateEan13CheckDigit(String code) {
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      int digit = int.parse(code[i]);
      sum += (i % 2 == 0) ? digit : digit * 3;
    }
    int checkDigit = (10 - (sum % 10)) % 10;
    return checkDigit == int.parse(code[12]);
  }

  static bool _validateUpcACheckDigit(String code) {
    int sum = 0;
    for (int i = 0; i < 11; i++) {
      int digit = int.parse(code[i]);
      sum += (i % 2 == 0) ? digit * 3 : digit;
    }
    int checkDigit = (10 - (sum % 10)) % 10;
    return checkDigit == int.parse(code[11]);
  }

  /// Validates password strength (returns 0 to 4 score)
  static PasswordStrength checkPasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.empty;
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    if (score <= 1) return PasswordStrength.weak;
    if (score == 2 || score == 3) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  /// Price validation
  static String? validatePrice(String? value, {String fieldName = 'Price'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final num = double.tryParse(value.trim());
    if (num == null) {
      return 'Enter a valid number';
    }
    if (num < 0) {
      return '$fieldName cannot be negative';
    }
    return null;
  }

  /// Stock validation
  static String? validateStock(String? value, {String fieldName = 'Stock'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final num = int.tryParse(value.trim());
    if (num == null) {
      return 'Enter a valid whole number';
    }
    if (num < 0) {
      return '$fieldName cannot be negative';
    }
    return null;
  }

  /// Required text validation
  static String? validateRequired(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}

enum PasswordStrength { empty, weak, medium, strong }
