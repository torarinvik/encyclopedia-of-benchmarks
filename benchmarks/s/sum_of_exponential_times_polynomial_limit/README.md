# Infinite exponential times polynomial sum

Compute

`sum(r^i * i^d, i = 0..infinity) mod 998244353`

for a residue `r` whose rational lift lies strictly between -1 and 1. The
bounded input uses `0 <= r < 998244353`, `r != 1`, and `0 <= d <= 256`. The
definition `0^0 = 1` makes the degree-zero case the geometric series
`1 / (1-r)`.

## Input and ABI

The exported C ABI symbol is
`sum_of_exponential_times_polynomial_limit(const int64_t *input, size_t length)`
using `i64_array_scalar`. Input is exactly `[r, d]`, where `r` is in
`0..998244352` except 1 and `d` is in `0..256`. The result is a scalar residue
in `0..998244352`; malformed frames or out-of-profile values return -1.

## Algorithm and complexity

For `d >= 1`, use the Eulerian polynomial identity

`sum(i^d r^i) = r A_d(r) / (1-r)^(d+1)`.

Build the Eulerian row with
`A(n,k) = (n-k)A(n-1,k-1) + (k+1)A(n-1,k)`, evaluate the row by Horner's
rule, and multiply by the modular inverse power of `1-r`. Degree zero is
handled directly as `1/(1-r)`, honoring `0^0=1`. The implementation takes
O(d^2) time and O(d) auxiliary storage for this bounded Eulerian-row profile.

The primary oracle uses the Eulerian row. The independent verifier uses
`i^d = sum_k S(d,k) k! binom(i,k)` and the geometric binomial-series identity;
it builds a Stirling row instead of an Eulerian row. This package evaluates an
infinite convergent limit and does not include the finite-`n` correction or
logarithmic-in-`n` recurrence of
[`sum_of_exponential_times_polynomial`](https://github.com/yosupo06/library-checker-problems/blob/master/other/sum_of_exponential_times_polynomial/task.md).

## Sources and ports

The operation and parameter domain follow Library Checker’s
[`sum_of_exponential_times_polynomial_limit`](https://github.com/yosupo06/library-checker-problems/blob/master/other/sum_of_exponential_times_polynomial_limit/task.md).
The task repository identifies its license as Apache-2.0. This package uses
the task taxonomy and mathematical operation only; its implementations and
oracles are clean-room. See [RIGHTS.md](RIGHTS.md).

| Language | Port |
|---|---|
| C | [`c/s/sum_of_exponential_times_polynomial_limit.c`](../../../c/s/sum_of_exponential_times_polynomial_limit.c) |
| C3 | [`c3/s/sum_of_exponential_times_polynomial_limit.c3`](../../../c3/s/sum_of_exponential_times_polynomial_limit.c3) |
| C++ | [`cpp/s/sum_of_exponential_times_polynomial_limit.cpp`](../../../cpp/s/sum_of_exponential_times_polynomial_limit.cpp) |
| Elisa | [`elisa/s/sum_of_exponential_times_polynomial_limit.elisa`](../../../elisa/s/sum_of_exponential_times_polynomial_limit.elisa) |
| Mojo | [`mojo/s/sum_of_exponential_times_polynomial_limit.mojo`](../../../mojo/s/sum_of_exponential_times_polynomial_limit.mojo) |
| Nim | [`nim/s/sum_of_exponential_times_polynomial_limit.nim`](../../../nim/s/sum_of_exponential_times_polynomial_limit.nim) |
| Odin | [`odin/s/sum_of_exponential_times_polynomial_limit.odin`](../../../odin/s/sum_of_exponential_times_polynomial_limit.odin) |
| Rust | [`rust/s/sum_of_exponential_times_polynomial_limit.rs`](../../../rust/s/sum_of_exponential_times_polynomial_limit.rs) |
| V | [`v/s/sum_of_exponential_times_polynomial_limit.v`](../../../v/s/sum_of_exponential_times_polynomial_limit.v) |
| Zig | [`zig/s/sum_of_exponential_times_polynomial_limit.zig`](../../../zig/s/sum_of_exponential_times_polynomial_limit.zig) |

The fixed workload is in [`workload.json`](workload.json). Primary and
independent oracle modules are
[`sum_of_exponential_times_polynomial_limit_oracle.py`](../../sum_of_exponential_times_polynomial_limit_oracle.py)
and
[`sum_of_exponential_times_polynomial_limit_verifier_oracle.py`](../../sum_of_exponential_times_polynomial_limit_verifier_oracle.py).
