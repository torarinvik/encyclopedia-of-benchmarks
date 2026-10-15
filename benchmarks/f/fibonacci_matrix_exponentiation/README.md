# Fibonacci matrix exponentiation

Compute the one-based Fibonacci value `F(n)` modulo a positive integer using binary exponentiation of the Fibonacci transition matrix.

## Contract

- Inputs are exact integer-valued binary64 numbers. The index `n` is in `1..=9,007,199,254,740,991`; the modulus is in `1..=4,294,967,295`.
- Return `F(n) mod modulus` as a binary64 value. Inputs outside those ranges, or fractional inputs, return `-1.0`.
- The index bound keeps every supported integer exactly representable in binary64. The modulus bound keeps modular products within unsigned 64-bit arithmetic, and every result remains exactly representable as binary64.
- The index is one-based, matching the pinned C++ `fibo(n, mod)` examples. The source does not define `n = 0` or `modulus = 0`; both are invalid here.

The recurrence uses the matrix `[[0, 1], [1, 1]]`. Raising it to the power `n - 1` and summing the first column yields `F(n)`. The implementation takes logarithmic time in the index.

## Relation to other Fibonacci benchmarks

The existing [`fibonacci_fast`](../fibonacci_fast/README.md) contract computes the exact value within the signed 64-bit range. This benchmark accepts a modulus and uses 2×2 matrix exponentiation, so it covers a different result domain and method.

## Workload and ABI

[`workload.json`](workload.json) covers the pinned examples, small moduli, invalid zero and fractional inputs, the largest supported modulus, and the largest exactly representable index. It uses the `float64_pair` ABI with a `1e-16` input-scaled tolerance.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/f/fibonacci_matrix_exponentiation.c`](../../../c/f/fibonacci_matrix_exponentiation.c) |
| C3 | [`c3/f/fibonacci_matrix_exponentiation.c3`](../../../c3/f/fibonacci_matrix_exponentiation.c3) |
| C++ | [`cpp/f/fibonacci_matrix_exponentiation.cpp`](../../../cpp/f/fibonacci_matrix_exponentiation.cpp) |
| Elisa | [`elisa/f/fibonacci_matrix_exponentiation.elisa`](../../../elisa/f/fibonacci_matrix_exponentiation.elisa) |
| Nim | [`nim/f/fibonacci_matrix_exponentiation.nim`](../../../nim/f/fibonacci_matrix_exponentiation.nim) |
| Odin | [`odin/f/fibonacci_matrix_exponentiation.odin`](../../../odin/f/fibonacci_matrix_exponentiation.odin) |
| Rust | [`rust/f/fibonacci_matrix_exponentiation.rs`](../../../rust/f/fibonacci_matrix_exponentiation.rs) |
| V | [`v/f/fibonacci_matrix_exponentiation.v`](../../../v/f/fibonacci_matrix_exponentiation.v) |
| Zig | [`zig/f/fibonacci_matrix_exponentiation.zig`](../../../zig/f/fibonacci_matrix_exponentiation.zig) |

## TheAlgorithms sources

- [C++ `fibonacci_matrix_exponentiation.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/fibonacci_matrix_exponentiation.cpp)
- [C++-1 `fibonacci_matrix_exponentiation.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/fibonacci_matrix_exponentiation.cpp)
