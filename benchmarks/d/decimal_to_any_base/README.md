# Decimal to any base

This benchmark converts a nonnegative signed 64-bit integer to a radix from 2 through 36. It emits canonical uppercase digits without a sign or prefix. The `decimal_to_any` candidate is cataloged as an alias because its reviewed base-2-through-36 conversion has the same normalized behavior.

## Contract

- Input is `[value, base]`, with `0 <= value <= INT64_MAX` and `2 <= base <= 36`.
- Digits are `0` through `9`, then uppercase `A` through `Z`; zero is `0`.
- Invalid input returns `-1`; insufficient output capacity returns `-2`.
- Implementations use integer division and remainder only, with no CPU-specific instructions.

## Workload and verification

[`workload.json`](workload.json) covers bases 2, 8, 10, 16, and 36, zero, boundary values, and invalid arguments. [`verify_decimal_to_any_base.py`](../../verify_decimal_to_any_base.py) checks dense values across every supported base, signed 64-bit boundaries, invalid radices, buffer capacity, and the recorded workload against an independent repeated-division oracle.

## Reviewed TheAlgorithms sources

- [C `decimal_to_any_base.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/conversions/decimal_to_any_base.c) and [Java `DecimalToAnyBase.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/conversions/DecimalToAnyBase.java) use repeated division; their alphabet and sign policies differ.
- [Dart `Decimal_To_Any.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/conversions/Decimal_To_Any.dart) and [Python `decimal_to_any.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/decimal_to_any.py) also convert decimal values to bases 2 through 36 with implementation-specific validation.
- [JavaScript `IntToBase.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/IntToBase.js) and [PHP `BaseX.php`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Maths/BaseX.php) use repeated remainders. Their normalized nonnegative base-2-through-10 behavior aliases this benchmark; the JavaScript source adds sign handling and does not encode alphabetic digits above base 10.

