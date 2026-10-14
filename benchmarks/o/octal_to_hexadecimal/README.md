# Octal to hexadecimal

This benchmark converts an octal digit sequence to hexadecimal. The reviewed sources use positional conversion or intermediate decimal values and vary in prefix and letter case. The shared contract accepts a most-significant-first octal digit array and writes canonical lowercase hexadecimal digits to a caller-provided buffer.

## Contract

- The read-only signed 64-bit array contains one octal digit per value, most-significant digit first.
- Input length is from 1 through 21; each digit must be in `0..7`.
- Output is prefix-free lowercase hexadecimal text without leading zeroes, using `0` for zero.
- Invalid input returns `-1`; insufficient output capacity returns `-2` without writing.
- Twenty-one octal digits fit signed 64-bit output. The ports use portable integer arithmetic.

## Workload and verification

[`workload.json`](workload.json) covers ordinary values, leading zeroes, malformed digits, empty and overlength input, and the maximum result. [`verify_octal_base_conversions.py`](../../verify_octal_base_conversions.py) checks exhaustive short digit arrays, deterministic random inputs, signed-width boundaries, and insufficient capacity against Python integer formatting.

## Reviewed TheAlgorithms sources

- [C `octal_to_hexadecimal.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/conversions/octal_to_hexadecimal.c) converts through decimal using floating-point powers and dynamically allocated uppercase output.
- [Dart `octal_to_hexadecimal.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/conversions/octal_to_hexadecimal.dart) accepts signed text and emits uppercase digits; [Java `OctalToHexadecimal.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/conversions/OctalToHexadecimal.java) accepts octal text and emits uppercase digits.
- [Python `octal_to_hexadecimal.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/octal_to_hexadecimal.py) accepts an optional `0o` prefix and emits uppercase digits with a `0x` prefix. The local contract removes those representation differences. The cataloged Rust path does not resolve at its pinned revision.
