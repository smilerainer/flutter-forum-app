class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final regex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    if (!regex.hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? displayName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Display name cannot be empty.';
    final trimmed = value.trim();
    if (trimmed.length < 2) return 'Display name must be at least 2 characters.';
    if (trimmed.length > 50) return 'Display name must be 50 characters or fewer.';
    return null;
  }
}
