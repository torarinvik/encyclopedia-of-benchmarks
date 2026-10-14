# Hexadecimal to decimal

This benchmark converts a hexadecimal digit sequence to its nonnegative decimal value. The reviewed sources accept strings or scalar textual values, sometimes including whitespace or a minus sign. The shared contract uses a most-significant-first numeric digit array, with `A` through `F` represented by 10 through 15, for consistent cross-language input and validation.

## Contract

- The read-only signed 64-bit array contains one hexadecimal digit per value, most-significant digit first.
- Input length is from 1 through 16; each digit must be in `0..15`.
- The corresponding value must fit signed 64-bit and be nonnegative. Empty, overlength, malformed, or overflowing input returns `-1`.
- Implementations fold left to right with `value = value * 16 + digit`, with a bound check that avoids signed overflow.

## Workload and verification

[`workload.json`](workload.json) covers numeric and alphabetic digits, leading zeroes, invalid digits, empty and overlength input, the signed maximum, and overflow. [`verify_hexadecimal_to_decimal.py`](../../verify_hexadecimal_to_decimal.py) checks all hexadecimal digit arrays through length three, deterministic random arrays, boundaries, and malformed inputs against Python's arbitrary-precision integer fold.

## Reviewed TheAlgorithms sources

- [Dart `hexadecimal_to_decimal.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/conversions/hexadecimal_to_decimal.dart) trims surrounding whitespace, accepts a leading minus sign, and converts digits using powers of 16.
- [Python `hexadecimal_to_decimal.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/hexadecimal_to_decimal.py) validates hexadecimal characters and folds them left to right; it also accepts surrounding whitespace and a leading minus sign.
- [PHP `HexadecimalToDecimal.php`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Conversions/HexadecimalToDecimal.php) validates hexadecimal text and accumulates positional values. The benchmark uses the shared unsigned, bounded contract.
