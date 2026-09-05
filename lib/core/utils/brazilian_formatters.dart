import 'package:flutter/services.dart';

String onlyDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

bool isValidCpf(String value) {
  final cpf = onlyDigits(value);
  if (cpf.length != 11 || RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) {
    return false;
  }

  int checkDigit(String base) {
    var sum = 0;
    for (var index = 0; index < base.length; index++) {
      sum += int.parse(base[index]) * (base.length + 1 - index);
    }
    final remainder = sum % 11;
    return remainder < 2 ? 0 : 11 - remainder;
  }

  final first = checkDigit(cpf.substring(0, 9));
  final second = checkDigit(cpf.substring(0, 9) + first.toString());
  return cpf.endsWith('$first$second');
}

bool isValidBrazilianDate(String value) {
  final digits = onlyDigits(value);
  if (digits.length != 8) return false;

  final day = int.tryParse(digits.substring(0, 2));
  final month = int.tryParse(digits.substring(2, 4));
  final year = int.tryParse(digits.substring(4, 8));
  if (day == null || month == null || year == null) return false;

  final now = DateTime.now();
  if (year < 1900 || year > now.year || month < 1 || month > 12) {
    return false;
  }

  final date = DateTime(year, month, day);
  return date.day == day &&
      date.month == month &&
      date.year == year &&
      !date.isAfter(now);
}

String? birthDateToApi(String value) {
  if (!isValidBrazilianDate(value)) return null;
  final digits = onlyDigits(value);
  return '${digits.substring(4, 8)}-${digits.substring(2, 4)}-${digits.substring(0, 2)}';
}

String formatCpf(String value, {String? fallback}) {
  final digits = onlyDigits(value);
  if (digits.length != 11) return fallback ?? value;
  return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.'
      '${digits.substring(6, 9)}-${digits.substring(9)}';
}

String formatPhone(String value, {String? fallback}) {
  final digits = onlyDigits(value);
  if (digits.length == 10) {
    return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
  }
  if (digits.length == 11) {
    return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
  }
  return fallback ?? value;
}

abstract class _DigitsFormatter extends TextInputFormatter {
  const _DigitsFormatter(this.maxLength);

  final int maxLength;
  String formatDigits(String digits);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = onlyDigits(newValue.text);
    final digits = raw.length > maxLength ? raw.substring(0, maxLength) : raw;
    final formatted = formatDigits(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class CpfInputFormatter extends _DigitsFormatter {
  const CpfInputFormatter() : super(11);

  @override
  String formatDigits(String digits) {
    if (digits.length <= 3) return digits;
    if (digits.length <= 6) {
      return '${digits.substring(0, 3)}.${digits.substring(3)}';
    }
    if (digits.length <= 9) {
      return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6)}';
    }
    return formatCpf(digits);
  }
}

class PhoneInputFormatter extends _DigitsFormatter {
  const PhoneInputFormatter() : super(11);

  @override
  String formatDigits(String digits) {
    if (digits.isEmpty) return '';
    if (digits.length <= 2) return '($digits';
    if (digits.length <= 6) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2)}';
    }
    return formatPhone(digits);
  }
}

class BirthDateInputFormatter extends _DigitsFormatter {
  const BirthDateInputFormatter() : super(8);

  @override
  String formatDigits(String digits) {
    if (digits.length <= 2) return digits;
    if (digits.length <= 4) {
      return '${digits.substring(0, 2)}/${digits.substring(2)}';
    }
    return '${digits.substring(0, 2)}/${digits.substring(2, 4)}/${digits.substring(4)}';
  }
}

class ZipCodeInputFormatter extends _DigitsFormatter {
  const ZipCodeInputFormatter() : super(8);

  @override
  String formatDigits(String digits) {
    if (digits.length <= 5) return digits;
    return '${digits.substring(0, 5)}-${digits.substring(5)}';
  }
}
