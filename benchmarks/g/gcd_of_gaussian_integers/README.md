# GCD of Gaussian integers

## Contract

Input is `[T, (a_1,b_1,a_2,b_2)...]`, where `1 <= T <= 8` and each signed
component is in `[-1,000,000, 1,000,000]`. Each four-value record represents
the Gaussian integers `a_1 + b_1 i` and `a_2 + b_2 i`. Return one greatest
common divisor per record, with each result encoded as two unsigned
32-bit little-endian coordinates `(real, imaginary)`. The ports choose the
unique associate with positive real part and nonnegative imaginary part; the
GCD of two zero values is `(0,0)`. A successful call returns `8*T` bytes.
Invalid input returns `-1`; null output or insufficient output capacity
returns `-2` without writing.

Gaussian division rounds both coordinates of the exact complex quotient to a
nearest integer (ties away from zero), then subtracts that quotient times the
divisor. This gives a remainder with smaller norm and supports the Euclidean
GCD loop. The fixed component bound keeps all products and norm calculations
within signed 64-bit arithmetic. The workspace stores at most eight input
records (`256` bytes); all inputs are copied and validated before output is
written.

The official Library Checker task allows `T <= 100,000` and components through
`10^9` in magnitude. This profile intentionally bounds the number and size of
records to keep arithmetic and cross-language workloads modest. The official
checker accepts any of the four unit associates; the canonical representative
here makes bytewise benchmark comparisons deterministic.

## Distinctness

The repository contains real-valued Gaussian distribution and elimination
benchmarks, but no Gaussian integer arithmetic or Euclidean GCD. The local
Pythagoras and Pythagorean-triple packages solve different problems.

Official task: [Library Checker — GCD of Gaussian Integers](https://github.com/yosupo06/library-checker-problems/blob/master/number_theory/gcd_of_gaussian_integers/task.md).

## Workload and ports

[`workload.json`](workload.json) covers zero inputs, a zero operand, shared
Gaussian factors, coprime real values, unit normalization, input bounds, and
output-capacity errors. The independent Python integer-arithmetic oracle is
[`benchmarks/gcd_of_gaussian_integers_oracle.py`](../../gcd_of_gaussian_integers_oracle.py).

| Language | Port |
|---|---|
| C | [`c/g/gcd_of_gaussian_integers.c`](../../../c/g/gcd_of_gaussian_integers.c) |
| C3 | [`c3/g/gcd_of_gaussian_integers.c3`](../../../c3/g/gcd_of_gaussian_integers.c3) |
| C++ | [`cpp/g/gcd_of_gaussian_integers.cpp`](../../../cpp/g/gcd_of_gaussian_integers.cpp) |
| Elisa | [`elisa/g/gcd_of_gaussian_integers.elisa`](../../../elisa/g/gcd_of_gaussian_integers.elisa) |
| Nim | [`nim/g/gcd_of_gaussian_integers.nim`](../../../nim/g/gcd_of_gaussian_integers.nim) |
| Odin | [`odin/g/gcd_of_gaussian_integers.odin`](../../../odin/g/gcd_of_gaussian_integers.odin) |
| Rust | [`rust/g/gcd_of_gaussian_integers.rs`](../../../rust/g/gcd_of_gaussian_integers.rs) |
| V | [`v/g/gcd_of_gaussian_integers.v`](../../../v/g/gcd_of_gaussian_integers.v) |
| Zig | [`zig/g/gcd_of_gaussian_integers.zig`](../../../zig/g/gcd_of_gaussian_integers.zig) |
| Mojo | [`mojo/g/gcd_of_gaussian_integers.mojo`](../../../mojo/g/gcd_of_gaussian_integers.mojo) |
