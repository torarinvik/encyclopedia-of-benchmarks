# Power via logarithms

This benchmark follows the Go `UsingLog` implementation, which evaluates a power through logarithm and exponential functions and rounds the result to the nearest integer, with halfway cases away from zero.

## Contract

- The `float64_pair` ABI accepts `[base, exponent]` as two binary64 values.
- Both inputs must be integral binary64 values with `base` in `-4..=4` and `exponent` in `-8..=8`.
- A zero base is valid only for a positive exponent. The pair `(0, 0)` and zero to a negative exponent are outside the domain.
- The result preserves the source operation order: choose the sign from a negative base and odd integer exponent, compute `log(abs(base))`, multiply by the exponent, compute `exp`, apply the sign, then round.
- The pair `(2, -1)` and `(-2, -1)` is excluded because the source's exact `±0.5` result lies on a rounding boundary that can vary with platform math libraries. Other valid outputs are compared with the float64-pair tolerance.
- Invalid inputs return `-1e300`.

The small integral domain avoids float-to-integer conversion edge cases and keeps all valid results finite. For zero with a positive exponent, the source expression evaluates `log(0)` and then `exp(-infinity)`, producing signed zero according to the source's sign rule.

## Source and related algorithms

The pinned [Go `powvialogarithm.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/power/powvialogarithm.go) computes `Exp(exponent * Log(Abs(base)))`, applies a sign when `base < 0` and the exponent is odd, and calls `math.Round`. This log/exp method is distinct from [`powx_n`](../../p/powx_n/README.md), which uses repeated squaring, and [`power_using_recursion`](../power_using_recursion/README.md), which uses linear recursive multiplication.

## Workload

[`workload.json`](workload.json) covers positive and negative bases, odd and even exponents, positive and negative exponents, zero, rounding to signed zero, the domain edges, excluded half-way cases, and invalid inputs.

| Language | Source |
| --- | --- |
| C | [`c/p/powvialogarithm.c`](../../../c/p/powvialogarithm.c) |
| C3 | [`c3/p/powvialogarithm.c3`](../../../c3/p/powvialogarithm.c3) |
| C++ | [`cpp/p/powvialogarithm.cpp`](../../../cpp/p/powvialogarithm.cpp) |
| Elisa | [`elisa/p/powvialogarithm.elisa`](../../../elisa/p/powvialogarithm.elisa) |
| Nim | [`nim/p/powvialogarithm.nim`](../../../nim/p/powvialogarithm.nim) |
| Odin | [`odin/p/powvialogarithm.odin`](../../../odin/p/powvialogarithm.odin) |
| Rust | [`rust/p/powvialogarithm.rs`](../../../rust/p/powvialogarithm.rs) |
| V | [`v/p/powvialogarithm.v`](../../../v/p/powvialogarithm.v) |
| Zig | [`zig/p/powvialogarithm.zig`](../../../zig/p/powvialogarithm.zig) |
