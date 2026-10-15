# Buzz Number

## Contract

Return `1` if the signed 64-bit input is divisible by 7 or is nonnegative and its final decimal digit is 7. Return `0` otherwise. The nonnegative check preserves the pinned C++ source's signed remainder behavior: for negative values, only divisibility by 7 can make the predicate true. The scalar ABI is `int64_t buzz_number(int64_t n);`.

The source program reads an `int` and prints a sentence per input. This benchmark adapts its predicate to the shared signed 64-bit scalar ABI. The predicate uses only remainder and comparison operations, so the full signed 64-bit domain is safe.

## Workload

[`workload.json`](workload.json) includes zero, positive multiples of 7, positive values ending in 7, values satisfying both conditions, nearby non-Buzz values, negative multiples and nonmultiples, and signed 64-bit boundaries. It uses the shared scalar runner and `scalar_call` measurement model.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/buzz_number.c`](../../../c/b/buzz_number.c) |
| C3 | [`c3/b/buzz_number.c3`](../../../c3/b/buzz_number.c3) |
| C++ | [`cpp/b/buzz_number.cpp`](../../../cpp/b/buzz_number.cpp) |
| Elisa | [`elisa/b/buzz_number.elisa`](../../../elisa/b/buzz_number.elisa) |
| Nim | [`nim/b/buzz_number.nim`](../../../nim/b/buzz_number.nim) |
| Odin | [`odin/b/buzz_number.odin`](../../../odin/b/buzz_number.odin) |
| Rust | [`rust/b/buzz_number.rs`](../../../rust/b/buzz_number.rs) |
| V | [`v/b/buzz_number.v`](../../../v/b/buzz_number.v) |
| Zig | [`zig/b/buzz_number.zig`](../../../zig/b/buzz_number.zig) |

## Upstream source review

The benchmark maps candidate `buzz_number` to TheAlgorithms/C-Plus-Plus `others/buzz_number.cpp` at commit [`fdcc29b0ac2848e9d1a8d926e171cc5b39f97759`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/others/buzz_number.cpp). The candidate catalog also records the matching file from TheAlgorithms/C-Plus-Plus-1 at commit [`0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/others/buzz_number.cpp). Both implementations use `(n % 7 == 0) || (n % 10 == 7)` and print whether each input is a Buzz Number.
