# Magic number

## Contract

The C++ sources define a positive integer as a magic number when repeatedly summing its decimal digits eventually yields `1`. Their implementation uses the equivalent shortcut `n % 9 == 1`.

The exported C ABI entry point is:

```c
int64_t magic_number(int64_t n);
```

Return `1` exactly when `n` is positive and `n % 9 == 1`; otherwise return `0`. This includes zero and negative signed inputs, which return `0`. The signed 64-bit input range is safe because the implementation only checks sign and remainder.

The two pinned C++ copies use an unsigned input and check the remainder. The pinned Dart copy checks the remainder without a positive-input guard. Dart's remainder for a negative dividend is nonnegative, so the Dart source returns true for negative values congruent to `1 mod 9` (for example, `-8`). The local contract follows the C++ documentation's positive-number definition and standardizes zero and negative inputs as non-magic; the `negative_dart_remainder_one` workload case makes this source divergence explicit.

## Workload

[`workload.json`](workload.json) covers zero, negative values, positive examples, values with each residue behavior, large signed inputs, and the signed maximum. It uses the shared scalar ABI family with one signed 64-bit input and result.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/m/magic_number.c`](../../../c/m/magic_number.c) |
| C3 | [`c3/m/magic_number.c3`](../../../c3/m/magic_number.c3) |
| C++ | [`cpp/m/magic_number.cpp`](../../../cpp/m/magic_number.cpp) |
| Elisa | [`elisa/m/magic_number.elisa`](../../../elisa/m/magic_number.elisa) |
| Nim | [`nim/m/magic_number.nim`](../../../nim/m/magic_number.nim) |
| Odin | [`odin/m/magic_number.odin`](../../../odin/m/magic_number.odin) |
| Rust | [`rust/m/magic_number.rs`](../../../rust/m/magic_number.rs) |
| V | [`v/m/magic_number.v`](../../../v/m/magic_number.v) |
| Zig | [`zig/m/magic_number.zig`](../../../zig/m/magic_number.zig) |

## Pinned sources

- [C++ `magic_number.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/magic_number.cpp)
- [C++ additional repository `magic_number.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/magic_number.cpp)
- [Dart `magic_number.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/other/magic_number.dart)
