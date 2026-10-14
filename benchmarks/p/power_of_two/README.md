# Power of two

## Contract

Return `1` if the signed 64-bit input is a positive power of two, and `0` otherwise. In particular, zero and negative values return `0`. The portable bit test is `n > 0 && (n & (n - 1)) == 0`; the positive check also prevents signed underflow at `INT64_MIN`.

The exported C ABI entry point is `int64_t power_of_two(int64_t n);`. The `is_power_of_two` filename candidate names the same predicate and is cataloged as an alias of this benchmark.

## Source review

The C++ and Ruby sources use the bit-clearing test; Dart, JavaScript, Python, and Rust provide related forms. Their zero handling is inconsistent: some implementations return true for zero, although the named predicate and the other sources intend positive powers. The local contract follows the positive-integer definition and makes zero false. Signed 64-bit inputs let the benchmark test values beyond the original 32-bit examples.

## Workload and verification

[`workload.json`](workload.json) covers zero, positive powers, adjacent non-powers, negative values, and signed boundaries. [`verify_scalar.py`](../../verify_scalar.py) checks all values from -1,024 through 1,024, deterministic full-width values, and each workload case.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/power_of_two.c`](../../../c/p/power_of_two.c) |
| C3 | [`c3/p/power_of_two.c3`](../../../c3/p/power_of_two.c3) |
| C++ | [`cpp/p/power_of_two.cpp`](../../../cpp/p/power_of_two.cpp) |
| Elisa | [`elisa/p/power_of_two.elisa`](../../../elisa/p/power_of_two.elisa) |
| Nim | [`nim/p/power_of_two.nim`](../../../nim/p/power_of_two.nim) |
| Odin | [`odin/p/power_of_two.odin`](../../../odin/p/power_of_two.odin) |
| Rust | [`rust/p/power_of_two.rs`](../../../rust/p/power_of_two.rs) |
| V | [`v/p/power_of_two.v`](../../../v/p/power_of_two.v) |
| Zig | [`zig/p/power_of_two.zig`](../../../zig/p/power_of_two.zig) |

## TheAlgorithms references

- [C++ `power_of_two.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/power_of_two.cpp) and [the additional C++ repository copy](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/power_of_two.cpp)
- [Dart `power_of_two.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/maths/power_of_two.dart)
- [Ruby `bit_manipulation/power_of_two.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/bit_manipulation/power_of_two.rb) and [Ruby `maths/power_of_two.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/maths/power_of_two.rb)
- [JavaScript `IsPowerOfTwo.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Bit-Manipulation/IsPowerOfTwo.js), [Python `is_power_of_two.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/bit_manipulation/is_power_of_two.py), and [Rust `is_power_of_two.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/bit_manipulation/is_power_of_two.rs)
