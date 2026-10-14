# Binary to hexadecimal

This benchmark converts a binary digit sequence to hexadecimal. Upstream versions differ in case, prefix, and signed-input behavior; the shared contract packs unsigned bits into a most-significant-first array and writes prefix-free lowercase ASCII hexadecimal digits to a caller-provided buffer.

## Contract

- The read-only signed 64-bit array contains one bit per value, most-significant bit first.
- Input length is from 1 through 63; every value must be `0` or `1`.
- Output is the nonnegative hexadecimal representation without a prefix or leading zeroes, using `0` for zero.
- Invalid input returns `-1`; insufficient output capacity returns `-2` without writing.
- The 63-bit limit keeps the intermediate value within signed 64-bit range. Conversion uses portable integer division and remainder.

## Workload and verification

[`workload.json`](workload.json) covers zero, alphabetic hexadecimal digits, leading zeroes, invalid digits, empty and overlength input, `INT64_MAX`, and the highest supported bit. [`verify_binary_base_conversions.py`](../../verify_binary_base_conversions.py) checks every bit sequence through length 12, deterministic random sequences, malformed inputs, and insufficient capacity against an independent integer-formatting oracle.

## Reviewed TheAlgorithms sources

- [C `binary_to_hexadecimal.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/conversions/binary_to_hexadecimal.c) reads decimal-encoded bit digits and formats the result in uppercase.
- [Dart `binary_to_hexadecimal.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/conversions/binary_to_hexadecimal.dart) accepts signed text and emits uppercase digits; [Java `BinaryToHexadecimal.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/conversions/BinaryToHexadecimal.java) validates and groups decimal-encoded bit digits.
- [Python `binary_to_hexadecimal.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/binary_to_hexadecimal.py) emits lowercase digits with a `0x` prefix and accepts signed text. The cataloged Rust path does not resolve at its pinned revision.
