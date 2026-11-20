# Fourier–Motzkin feasibility

This benchmark decides whether a bounded system of real linear inequalities
`a[0]*x[0] + ... + a[d-1]*x[d-1] <= b` has a solution. It uses
Fourier–Motzkin elimination, which removes one variable by combining each
upper-bound inequality with each lower-bound inequality. The profile uses
ascending variable order and exact integer arithmetic throughout.

## Input and result

The exported symbol is `fourier_motzkin_feasibility` and the ABI is
`i64_array_scalar`. Input is `[d,m,(a[0],...,a[d-1],b)*m]`, with 1–3 real
variables, 1–6 inequalities, coefficients in `[-3,3]`, bounds in `[-6,6]`,
and exact length `2 + m*(d+1)`. The maximum valid frame has 26 words; the
maximum parseable frame has 27 words.

The result is `1` if the system is feasible over the reals, `0` if it is
infeasible, and `-1` for a null input, malformed frame, or out-of-range value.
Inequalities are non-strict and every variable ranges over all real numbers.

## Elimination and bounds

For a variable with positive coefficient `p` in one row and negative
coefficient `q` in another, the pair is replaced by the inequality formed as
`(-q)*positive_row + p*negative_row`. Rows with zero coefficient are carried
forward. If one sign is absent, rows containing that variable impose no
restriction on the projection and are dropped. After all variables are
eliminated, feasibility is equivalent to every remaining constant inequality
`0 <= b` being true.

The fixed profile holds at most 100 rows after eliminating three variables:
from six rows the successive worst-case counts are 9, 20, and 100. With the
input coefficient bounds and three elimination stages, intermediate integers
remain below 2^31; ports use signed 64-bit intermediates. The bounded worst
case is `O(m^(2^d))` generated rows and `O(m^(2^d))` space, with `d<=3`.

The primary oracle follows ascending-order Fourier–Motzkin elimination. The
independent verifier enumerates exact rational vertices in a bounding box.
It uses a determinant bound to show that every feasible frame has a witness
inside that box.

## Source and language ports

The algorithm description was consulted in the OI Wiki
[Fourier–Motzkin elimination article](https://oi-wiki.org/math/fourier-motzkin-elimination/).
Only the mathematical method was used; no article prose or implementation
was copied. See [RIGHTS.md](RIGHTS.md).

| Language | Port |
|---|---|
| C | [`c/f/fourier_motzkin_feasibility.c`](../../../c/fourier_motzkin_feasibility.c) |
| C3 | [`c3/f/fourier_motzkin_feasibility.c3`](../../../c3/f/fourier_motzkin_feasibility.c3) |
| C++ | [`cpp/f/fourier_motzkin_feasibility.cpp`](../../../cpp/fourier_motzkin_feasibility.cpp) |
| Elisa | [`elisa/f/fourier_motzkin_feasibility.elisa`](../../../elisa/f/fourier_motzkin_feasibility.elisa) |
| Mojo | [`mojo/f/fourier_motzkin_feasibility.mojo`](../../../mojo/f/fourier_motzkin_feasibility.mojo) |
| Nim | [`nim/f/fourier_motzkin_feasibility.nim`](../../../nim/f/fourier_motzkin_feasibility.nim) |
| Odin | [`odin/f/fourier_motzkin_feasibility.odin`](../../../odin/f/fourier_motzkin_feasibility.odin) |
| Rust | [`rust/f/fourier_motzkin_feasibility.rs`](../../../rust/f/fourier_motzkin_feasibility.rs) |
| V | [`v/fourier_motzkin_feasibility.v`](../../../v/fourier_motzkin_feasibility.v) |
| Zig | [`zig/fourier_motzkin_feasibility.zig`](../../../zig/fourier_motzkin_feasibility.zig) |

The fixed workload and `i64_array_scalar` suite registration are included.
All source was reviewed statically; no programs or tests were run.
