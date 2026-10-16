# Binary to decimal

This benchmark converts an unsigned binary digit sequence to its base-10 integer value. The reviewed sources accept either a string or a number whose decimal digits encode the bits. The local contract uses an array of bits in most-significant-first order, which makes leading zeroes explicit and gives every target language the same input representation.

## Contract

- The read-only signed 64-bit array contains one binary digit per value, most-significant bit first.
- Input length is from 1 through 63; every element must be `0` or `1`.
- The result is the corresponding nonnegative integer. Invalid input returns `-1`.
- The maximum length ensures the result fits in signed 64-bit arithmetic.
- Implementations fold from left to right with `value = value * 2 + bit`; no allocation or architecture-specific operation is used.

## Workload and verification

[`workload.json`](workload.json) covers zero, leading zeroes, invalid digits, a 63-bit high bit, and the largest signed 64-bit result. [`verify_binary_to_decimal.py`](../../verify_binary_to_decimal.py) also checks every bit sequence through length 12, deterministic random sequences, and malformed arrays against an independent Python fold.

## Reviewed TheAlgorithms sources

- Go [`binarytodecimal.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/conversion/binarytodecimal.go) validates the binary digits and folds them into an unsigned value; this benchmark uses the shared maximum width of 32 bits.
- [C `binary_to_decimal.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/conversions/binary_to_decimal.c) — numeric binary digits with invalid-digit rejection.
- [Rust `binary_to_decimal.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/conversions/binary_to_decimal.rs) — validated binary string with checked accumulation.
- [Dart `binary_to_decimal.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/conversions/binary_to_decimal.dart) and [Python `binary_to_decimal.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/binary_to_decimal.py) also accept a leading minus sign. The benchmark selects the unsigned conversion shared by the other reviewed inputs.
