# Octal to binary

This benchmark converts an octal digit sequence to its binary representation. The reviewed sources vary between converting each octal digit to a three-bit group and parsing through a decimal integer. The shared contract accepts a most-significant-first digit array and writes the canonical binary value to a caller-provided buffer.

## Contract

- The read-only signed 64-bit array contains one octal digit per value, most-significant digit first.
- Input length is from 1 through 21; each digit must be in `0..7`.
- Output is prefix-free binary text without leading zeroes, using `0` for zero.
- Invalid input returns `-1`; insufficient output capacity returns `-2` without writing.
- Twenty-one octal digits fit signed 64-bit output. The ports use portable integer arithmetic.

## Workload and verification

[`workload.json`](workload.json) covers zero, leading zeroes, grouping examples, malformed digits, empty and overlength input, and the maximum result. [`verify_octal_base_conversions.py`](../../verify_octal_base_conversions.py) checks exhaustive short digit arrays, deterministic random inputs, signed-width boundaries, and insufficient capacity against Python integer formatting.

## Reviewed TheAlgorithms sources

- [C `octal_to_binary.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/conversions/octal_to_binary.c) parses decimal-encoded digits and uses floating-point powers of eight.
- [Dart `octal_to_binary.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/conversions/octal_to_binary.dart) accepts trimmed signed text, while [Java `OctalToBinary.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/conversions/OctalToBinary.java) converts each octal digit to a binary group.
- [Python `octal_to_binary.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/octal_to_binary.py) emits three bits per digit, including leading zeroes. The local contract standardizes the numeric representation. The cataloged Rust path does not resolve at its pinned revision.
