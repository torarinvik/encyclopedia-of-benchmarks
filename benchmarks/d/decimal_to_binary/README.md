# Decimal to binary

## Contract

Convert a signed 64-bit input to its binary representation. Inputs from `0` through `INT64_MAX` write the most-significant-first ASCII digits without a prefix; zero is represented as `0`. Negative inputs return `-1`. If the caller's output buffer is too small, return `-2` without writing. The result is the number of output bytes, from 1 through 63.

The exported C ABI entry point is:

```c
int64_t decimal_to_binary(int64_t value, uint8_t *output, size_t output_capacity);
```

The local implementations find the digit count with division, then fill the caller-owned buffer from right to left using division and remainder. They allocate no memory and use no target-specific instructions. The inspected upstream sources differ on negative inputs and how zero is printed; the shared contract makes both cases explicit.

## Workload and verification

[`workload.json`](workload.json) includes zero, small values, source examples, a 31-bit value, the largest signed 64-bit value, and negative inputs. [`verify_i64_scalar_bytes_output.py`](../../verify_i64_scalar_bytes_output.py) checks every input from 0 through 4,096, deterministic full-width values, signed boundaries, invalid negatives, exact-capacity writes, and insufficient-capacity behavior against Python's integer formatting.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/d/decimal_to_binary.c`](../../../c/d/decimal_to_binary.c) |
| C3 | [`c3/d/decimal_to_binary.c3`](../../../c3/d/decimal_to_binary.c3) |
| C++ | [`cpp/d/decimal_to_binary.cpp`](../../../cpp/d/decimal_to_binary.cpp) |
| Elisa | [`elisa/d/decimal_to_binary.elisa`](../../../elisa/d/decimal_to_binary.elisa) |
| Nim | [`nim/d/decimal_to_binary.nim`](../../../nim/d/decimal_to_binary.nim) |
| Odin | [`odin/d/decimal_to_binary.odin`](../../../odin/d/decimal_to_binary.odin) |
| Rust | [`rust/d/decimal_to_binary.rs`](../../../rust/d/decimal_to_binary.rs) |
| V | [`v/d/decimal_to_binary.v`](../../../v/d/decimal_to_binary.v) |
| Zig | [`zig/d/decimal_to_binary.zig`](../../../zig/d/decimal_to_binary.zig) |

All nine implementations use the same scalar-to-byte-buffer ABI and portable integer operations.

## TheAlgorithms references

- [C `decimal_to_binary.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/conversions/decimal_to_binary.c)
- [C++ `decimal_to_binary.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/others/decimal_to_binary.cpp) and [additional C++ repository copy](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/others/decimal_to_binary.cpp)
- [Dart `Decimal_To_Binary.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/conversions/Decimal_To_Binary.dart)
- [Java `DecimalToBinary.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/conversions/DecimalToBinary.java)
- [JavaScript `DecimalToBinary.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Conversions/DecimalToBinary.js)
- [PHP `DecimalToBinary.php`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Conversions/DecimalToBinary.php)
- [Python `decimal_to_binary.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/decimal_to_binary.py)
- [Ruby `decimal_to_binary.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/maths/decimal_to_binary.rb)
- [Rust `decimal_to_binary.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/conversions/decimal_to_binary.rs)
- [Swift `decimal-to-binary.swift`](https://github.com/TheAlgorithms/Swift/blob/2c9eb8b85dee6db46cb33452c0b904eb7d7d179c/algorithms/conversion/decimal-to-binary.swift)
