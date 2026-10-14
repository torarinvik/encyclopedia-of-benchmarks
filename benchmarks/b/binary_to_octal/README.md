# Binary to octal

This benchmark converts a binary digit sequence to its octal representation. The reviewed sources accept strings or decimal-encoded bit digits; this shared contract packs the bits into a most-significant-first array and writes prefix-free ASCII octal digits to a caller-provided buffer.

## Contract

- The read-only signed 64-bit array contains one bit per value, most-significant bit first.
- Input length is from 1 through 63; every value must be `0` or `1`.
- Output is the nonnegative octal representation without a prefix or leading zeroes, using `0` for zero.
- Invalid input returns `-1`; insufficient output capacity returns `-2` without writing.
- The 63-bit limit keeps the intermediate value within signed 64-bit range. Conversion uses portable integer division and remainder.

## Workload and verification

[`workload.json`](workload.json) covers zero, leading zeroes, grouping boundaries, invalid digits, empty and overlength input, `INT64_MAX`, and the highest supported bit. [`verify_binary_base_conversions.py`](../../verify_binary_base_conversions.py) checks every bit sequence through length 12, deterministic random sequences, malformed inputs, and insufficient capacity against an independent integer-formatting oracle.

## Reviewed TheAlgorithms sources

- [C `binary_to_octal.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/conversions/binary_to_octal.c) groups decimal-encoded bit digits in threes; the console example does not validate the full input.
- [Dart `binary_to_octal.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/conversions/binary_to_octal.dart) accepts a signed, trimmed string, while [Java `BinaryToOctal.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/conversions/BinaryToOctal.java) validates decimal-encoded bit digits.
- [Python `binary_to_octal.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/binary_to_octal.py) validates and groups a binary string. The cataloged Rust path does not resolve at its pinned revision.
