# Octal to decimal

This benchmark converts a sequence of octal digits to its nonnegative decimal value. The reviewed sources accept strings or numeric encodings; the shared contract uses a most-significant-first array so leading zeroes and malformed digits have the same representation in every target language.

## Contract

- The read-only signed 64-bit array contains one octal digit per value, most-significant digit first.
- Input length is from 1 through 21; each digit must be in `0..7`.
- The result is the corresponding nonnegative integer. Empty, overlength, or malformed input returns `-1`.
- Twenty-one octal digits fit exactly in signed 64-bit output; the largest input, 21 sevens, maps to `INT64_MAX`.
- Implementations fold left to right with `value = value * 8 + digit`, using portable integer arithmetic.

## Workload and verification

[`workload.json`](workload.json) covers ordinary values, leading zeroes, invalid digits, empty and overlength input, and `INT64_MAX`. [`verify_octal_to_decimal.py`](../../verify_octal_to_decimal.py) checks exhaustive digit arrays through length four, deterministic random arrays, boundaries, and malformed arrays against an independent Python integer fold.

## Reviewed TheAlgorithms sources

- [C `octal_to_decimal.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/conversions/octal_to_decimal.c) uses digit extraction and powers of eight; the local implementation avoids floating-point arithmetic.
- [Dart `octal_to_decimal.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/conversions/octal_to_decimal.dart) and [Java `OctalToDecimal.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/conversions/OctalToDecimal.java) use iterative positional conversion.
- [PHP `OctalToDecimal.php`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Conversions/OctalToDecimal.php), [Python `octal_to_decimal.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/octal_to_decimal.py), and [Rust `octal_to_decimal.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74a4c939ec5163648458a8c2b46fd4c/src/conversions/octal_to_decimal.rs) parse octal representations; Python and Rust validate their accepted digits.
