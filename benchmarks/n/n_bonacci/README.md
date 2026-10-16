# N-bonacci final term

Return the final term of the pinned N-bonacci sequence for a given order and term count. The sequence starts with `order - 1` zeroes followed by `1`; each later term is the sum of the preceding `order` terms.

## Contract

- The `i64_array_scalar` ABI receives `[order, term_count]` as signed 64-bit integers.
- Require `1 <= order < term_count <= 64`.
- Return the term at zero-based index `term_count - 1`.
- Return `-1` for malformed or out-of-range inputs.

The pinned C++ implementations return an entire sequence and define several boundary cases that the Dart source does not handle. This benchmark uses the common valid domain where Dart's `N_bonacci` initializes both seed positions safely. It projects the generated sequence to its final term for the scalar ABI. The 64-term limit keeps every supported result within signed 64-bit range.

[`workload.json`](workload.json) includes the pinned Fibonacci, tribonacci, five-bonacci, and six-bonacci examples, the maximum term count, and invalid boundaries.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/n/n_bonacci.c`](../../../c/n/n_bonacci.c) |
| C3 | [`c3/n/n_bonacci.c3`](../../../c3/n/n_bonacci.c3) |
| C++ | [`cpp/n/n_bonacci.cpp`](../../../cpp/n/n_bonacci.cpp) |
| Elisa | [`elisa/n/n_bonacci.elisa`](../../../elisa/n/n_bonacci.elisa) |
| Nim | [`nim/n/n_bonacci.nim`](../../../nim/n/n_bonacci.nim) |
| Odin | [`odin/n/n_bonacci.odin`](../../../odin/n/n_bonacci.odin) |
| Rust | [`rust/n/n_bonacci.rs`](../../../rust/n/n_bonacci.rs) |
| V | [`v/n/n_bonacci.v`](../../../v/n/n_bonacci.v) |
| Zig | [`zig/n/n_bonacci.zig`](../../../zig/n/n_bonacci.zig) |

## Pinned source variants

- [C++ `math/n_bonacci.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/n_bonacci.cpp)
- [C++-1 `math/n_bonacci.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/n_bonacci.cpp)
- [Dart `other/N_bonacci.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/other/N_bonacci.dart)
