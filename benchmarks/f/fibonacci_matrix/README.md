# Fibonacci matrix

Compute the zero-based Fibonacci number by binary exponentiation of the exact 2×2 Fibonacci matrix.

## Contract

- Inputs from `0` through `92` return the exact result as a signed 64-bit integer. Inputs outside that range return `-1`.
- The matrix `[[1, 1], [1, 0]]` is raised to the power `n - 1`; its top-left entry is `F(n)`. The implementation returns `0` directly for `n = 0`.
- `F(92)` fits signed 64-bit output, while `F(93)` does not. Ports skip an unused final matrix square so the largest supported result is computed without overflowing an intermediate.

## Relation to other Fibonacci benchmarks

This package captures the exact matrix method in Nim's `fibonacci_numbers.nim`. The existing [`fibonacci`](../fibonacci/README.md) benchmark uses the linear recurrence, and [`fibonacci_fast`](../fibonacci_fast/README.md) uses fast doubling. [`fibonacci_matrix_exponentiation`](../fibonacci_matrix_exponentiation/README.md) accepts a modulus and measures a separate two-input operation.

## Workload

[`workload.json`](workload.json) covers the first terms, a representative value, the signed 64-bit boundary, and invalid indices. The scalar ABI is `int64_t fibonacci_matrix(int64_t index)`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/f/fibonacci_matrix.c`](../../../c/f/fibonacci_matrix.c) |
| C3 | [`c3/f/fibonacci_matrix.c3`](../../../c3/f/fibonacci_matrix.c3) |
| C++ | [`cpp/f/fibonacci_matrix.cpp`](../../../cpp/f/fibonacci_matrix.cpp) |
| Elisa | [`elisa/f/fibonacci_matrix.elisa`](../../../elisa/f/fibonacci_matrix.elisa) |
| Nim | [`nim/f/fibonacci_matrix.nim`](../../../nim/f/fibonacci_matrix.nim) |
| Odin | [`odin/f/fibonacci_matrix.odin`](../../../odin/f/fibonacci_matrix.odin) |
| Rust | [`rust/f/fibonacci_matrix.rs`](../../../rust/f/fibonacci_matrix.rs) |
| V | [`v/f/fibonacci_matrix.v`](../../../v/f/fibonacci_matrix.v) |
| Zig | [`zig/f/fibonacci_matrix.zig`](../../../zig/f/fibonacci_matrix.zig) |

## TheAlgorithms source

- Nim [`fibonacciMatrix` in `dynamic_programming/fibonacci_numbers.nim`](https://github.com/TheAlgorithms/Nim/blob/63eec16614b46c91078653e8d3c049fe99ad36b3/dynamic_programming/fibonacci_numbers.nim)
