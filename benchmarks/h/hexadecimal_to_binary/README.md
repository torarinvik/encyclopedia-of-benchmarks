# Hexadecimal to binary

This benchmark converts a hexadecimal digit sequence to binary. The reviewed sources accept textual digits and may preserve a sign or fixed-width leading zeroes. The shared contract uses a most-significant-first numeric digit array and writes the canonical binary value to a caller-provided buffer.

## Contract

- The read-only signed 64-bit array contains one hexadecimal digit per value, most-significant digit first; `A` through `F` are represented by 10 through 15.
- Input length is from 1 through 16, and the value must fit in nonnegative signed 64-bit range.
- Output is prefix-free binary text without leading zeroes, using `0` for zero.
- Invalid, empty, overlength, or overflowing input returns `-1`; insufficient output capacity returns `-2` without writing.
- The ports use portable integer arithmetic and reject a 16-digit input whose leading nibble exceeds 7.

## Workload and verification

[`workload.json`](workload.json) covers letter digits, leading zeroes, malformed input, signed-width boundaries, and overflow. [`verify_hexadecimal_base_conversions.py`](../../verify_hexadecimal_base_conversions.py) checks all digit arrays through length three, deterministic random inputs, maximum values, malformed digits, and insufficient capacity against Python integer formatting.

## Reviewed TheAlgorithms sources

- [Dart `hexadecimal_to_binary.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/conversions/hexadecimal_to_binary.dart) maps each hexadecimal character to its binary group and also accepts a leading minus sign.
- The cataloged [Rust source path](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74a4c939ec5163648458a8c2b46fd4c/src/conversions/hexadecimal_to_binary.rs) does not resolve at its pinned revision, so it was not used to infer the shared contract.
