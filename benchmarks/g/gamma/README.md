# Gamma function, recursive half-integer implementation

## Contract

This package benchmarks the `gamma_recursive` routine from the pinned Python source. The existing `float64_unary` ABI takes one binary64 input `num`. The bounded domain is the positive half-integers from `0.5` through `20.0`, inclusive. Return the recursive source result on that domain; return `-1e300` for values outside the domain or values that are not integers or half-integers.

The implementation preserves the source recurrence and order: `Gamma(0.5) = sqrt(pi)`, `Gamma(1) = 1`, and otherwise `Gamma(num) = (num - 1) * Gamma(num - 1)`. It therefore reaches the base case in steps of one, with at most 20 recursive calls. The bound keeps every result finite and avoids deep recursion. Input half-integers are exactly representable as binary64, and valid outputs are compared with relative and absolute tolerance `1e-12`.

The pinned file also includes `gamma_iterative`, which evaluates the defining integral with SciPy quadrature. This package covers the separate recursive method only. It is distinct from the built-in logarithmic gamma functions and from sigmoid/activation functions.

## Source

- [TheAlgorithms/Python `maths/gamma.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/gamma.py), pinned at `e1a2a8b016001309a73d5fec4818c35cca139795`.

## Workload and implementations

[`workload.json`](workload.json) includes the source examples, integer and half-integer values, the upper bound, and invalid-domain cases.

| Language | Implementation |
| --- | --- |
| C | [`c/g/gamma.c`](../../../c/g/gamma.c) |
| C3 | [`c3/g/gamma.c3`](../../../c3/g/gamma.c3) |
| C++ | [`cpp/g/gamma.cpp`](../../../cpp/g/gamma.cpp) |
| Elisa | [`elisa/g/gamma.elisa`](../../../elisa/g/gamma.elisa) |
| Nim | [`nim/g/gamma.nim`](../../../nim/g/gamma.nim) |
| Odin | [`odin/g/gamma.odin`](../../../odin/g/gamma.odin) |
| Rust | [`rust/g/gamma.rs`](../../../rust/g/gamma.rs) |
| V | [`v/g/gamma.v`](../../../v/g/gamma.v) |
| Zig | [`zig/g/gamma.zig`](../../../zig/g/gamma.zig) |

All implementations export `gamma_recursive` through the `float64_unary` ABI.
