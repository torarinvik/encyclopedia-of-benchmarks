# Decimal to hexadecimal

Convert a nonnegative signed 64-bit integer to lowercase hexadecimal digits.

## Contract

- Inputs from `0` through `INT64_MAX` write the most-significant-first ASCII hexadecimal digits without a prefix; zero is represented as `0` and digits 10 through 15 use lowercase `a` through `f`.
- Negative inputs return `-1`. If the caller's output buffer is too small, return `-2` without writing.
- The result is the number of bytes written. The ports count digits by division, then fill the caller-owned buffer from right to left. They allocate no memory.

The pinned C++ console example uses uppercase digits, while the Python implementation includes a `0x` prefix and supports negatives. The local contract normalizes these formatting differences to lowercase, prefix-free output and uses the shared scalar-to-byte-buffer ABI.

## Inspected upstream sources

- [C++ — `others/decimal_to_hexadecimal.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/others/decimal_to_hexadecimal.cpp)
- [C++-1 — `others/decimal_to_hexadecimal.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/others/decimal_to_hexadecimal.cpp)
- [Dart — `conversions/Decimal_to_Hexadecimal.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/conversions/Decimal_to_Hexadecimal.dart)
- [Java — `src/main/java/com/thealgorithms/conversions/DecimalToHexadecimal.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/conversions/DecimalToHexadecimal.java)
- [Python — `conversions/decimal_to_hexadecimal.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/decimal_to_hexadecimal.py)
- [Rust — `src/conversions/decimal_to_hexadecimal.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/conversions/decimal_to_hexadecimal.rs)

## Workload and verification

`workload.json` covers digit boundaries, the pinned Python example, `INT64_MAX`, and negative inputs. [`verify_i64_scalar_bytes_output.py`](../../verify_i64_scalar_bytes_output.py) checks every input from 0 through 4,096, deterministic full-width inputs, signed boundaries, and insufficient-capacity behavior against Python's integer formatting.

Build and record with the `i64_scalar_bytes_output` ABI family. Source ports are in `d/` in all nine language directories.
