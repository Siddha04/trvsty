/// Reusable input validators for forms.
class Validators {
  const Validators._();

  /// Indian mobile number: 10 digits beginning 6-9.
  static String? phone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Phone number is required.';
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v)) {
      return 'Enter a valid 10-digit Indian mobile number.';
    }
    return null;
  }

  /// 6-digit OTP.
  static String? otp(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'OTP is required.';
    if (!RegExp(r'^\d{6}$').hasMatch(v)) return 'Enter the 6-digit OTP.';
    return null;
  }

  /// PAN format: 5 letters, 4 digits, 1 letter (e.g. ABCDE1234F).
  static String? pan(String? value) {
    final v = value?.trim().toUpperCase() ?? '';
    if (v.isEmpty) return 'PAN is required.';
    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(v)) {
      return 'Enter a valid PAN (e.g. ABCDE1234F).';
    }
    return null;
  }

  /// 12-digit Aadhaar number (Verhoeff checksum not validated here; the
  /// secure QR signature is the authoritative check).
  static String? aadhaar(String? value) {
    final v = value?.replaceAll(RegExp(r'\s'), '') ?? '';
    if (v.isEmpty) return 'Aadhaar number is required.';
    if (!RegExp(r'^\d{12}$').hasMatch(v)) {
      return 'Enter a valid 12-digit Aadhaar number.';
    }
    return null;
  }

  static String? required(String? value, [String field = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$field is required.';
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required.';
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(v)) {
      return 'Enter a valid email address.';
    }
    return null;
  }
}
