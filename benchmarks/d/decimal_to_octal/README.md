# Decimal to octal

Convert a nonnegative signed 64-bit integer to its octal digit string.

## Contract

- Inputs from `0` through `INT64_MAX` write the most-significant-first ASCII octal digits without a prefix; zero is represented as `0`.
- Negative inputs return `-1`. If the caller's output buffer is too small, return `-2` without writing.
- The result is the number of bytes written. The ports count digits by division, then fill the caller-owned buffer from right to left. They allocate no memory.

The pinned Python source emits an `0o` prefix and computes place values with floating-point operations; the C example prints its output and does not handle zero correctly. The local workload standardizes representation and capacity handling so all nine languages share one scalar-to-byte-buffer ABI.

## Inspected upstream sources

- [C — `conversions/decimal_to_octal.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/conversions/decimal_to_octal.c)
- [Dart — `conversions/Decimal_to_Octal.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/conversions/Decimal_to_Octal.dart)
- [Java — `src/main/java/com/thealgorithms/conversions/DecimalToOctal.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/conversions/DecimalToOctal.java)
- [JavaScript — `Conversions/DecimalToOctal.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Conversions/DecimalToOctal.js)
- [Python — `conversions/decimal_to_octal.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/decimal_to_octal.py)
- [Rust — `src/conversions/decimal_to_octal.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/conversions/decimal_to_octal.rs)

## Workload and verification

`workload.json` covers zero, octal digit boundaries, familiar examples, `INT64_MAX`, and negative inputs. [`verify_i64_scalar_bytes_output.py`](../../verify_i64_scalar_bytes_output.py) checks every input from 0 through 4,096, deterministic full-width inputs, signed boundaries, and insufficient-capacity behavior against Python's integer formatting.

Build and record with the `i64_scalar_bytes_output` ABI family. Source ports are in `d/` in all nine language directories.
