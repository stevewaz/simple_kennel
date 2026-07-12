import 'package:flutter/services.dart';

/// Formats a US phone number to (XXX) XXX-XXXX as the user types.
class USPhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits =
        newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited =
        digits.length > 10 ? digits.substring(0, 10) : digits;

    final buf = StringBuffer();
    for (int i = 0; i < limited.length; i++) {
      if (i == 0) buf.write('(');
      if (i == 3) buf.write(') ');
      if (i == 6) buf.write('-');
      buf.write(limited[i]);
    }

    final formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Auto-lowercases email input.
class LowercaseEmailFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(
      text: newValue.text.toLowerCase(),
      selection: newValue.selection,
    );
  }
}

/// Uppercases input and caps it at 2 characters, for US state abbreviations.
class StateAbbrFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.toUpperCase();
    final limited = text.length > 2 ? text.substring(0, 2) : text;
    return TextEditingValue(
      text: limited,
      selection: TextSelection.collapsed(offset: limited.length),
    );
  }
}

/// Normalises any phone string (digits only, with/without formatting)
/// to (XXX) XXX-XXXX.  Returns the original if fewer than 10 digits.
String formatUSPhone(String input) {
  final digits = input.replaceAll(RegExp(r'\D'), '');
  // If 11 digits and starts with 1, strip country code
  final core = (digits.length == 11 && digits.startsWith('1'))
      ? digits.substring(1)
      : digits;
  if (core.length != 10) return input;

  return '(${core.substring(0, 3)}) ${core.substring(3, 6)}-${core.substring(6)}';
}
