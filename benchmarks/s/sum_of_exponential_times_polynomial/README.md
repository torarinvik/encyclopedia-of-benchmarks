# Finite exponential times polynomial sum

Compute

`sum(r^i * i^d, i = 0..n-1) mod 998244353`

with the convention `0^0 = 1`. The official task allows
`0 <= r < 998244353`, `0 <= d <= 10_000_000`, and
`0 <= n <= 10^18`. This benchmark uses the bounded profile `d <= 32` while
retaining the full range of `n`, including zero, and all valid values of `r`.

## Input and ABI

The exported C ABI symbol is `sum_of_exponential_times_polynomial(const int64_t *input, size_t length)` using `i64_array_scalar`. Input is exactly
`[r, d, n]`, where `r` is in `0..998244352`, `d` is in `0..32`, and `n` is in
`0..1000000000000000000`. The result is a scalar residue in
`0..998244352`; malformed frames or out-of-profile values return `-1`.

## Algorithm and complexity

For a block of length `L`, store every weighted moment
`M_k = sum(r^i * i^k, i=0..L-1)` for `0 <= k <= d`, along with `r^L`.
Shifting a block by `a` positions transforms its moments using

`sum_j r^j (a+j)^k = sum_{t=0}^k binom(k,t) a^(k-t) M_t`.

Concatenate blocks with this binomial shift and use binary decomposition of
`n` to build the requested prefix from a one-element block. This handles
`r=0`, `r=1`, and `n=0` directly, including `0^0=1`. The bounded profile takes
O(d² log n) time and O(d²) fixed binomial storage plus O(d) moment vectors.

The primary oracle uses the same block-composition identity. The independent
oracle uses formal infinite geometric moments and subtracts the shifted tail
when `r != 1`; for `r=1` it uses Stirling numbers and sums falling factorials.
This is a finite sum with an `n`-dependent tail, distinct from the separate
[`sum_of_exponential_times_polynomial_limit`](../sum_of_exponential_times_polynomial_limit/README.md)
package, which evaluates only a convergent infinite series and has no finite
length parameter.

## Source and ports

The operation and official constraints follow Library Checker’s
[`sum_of_exponential_times_polynomial`](https://github.com/yosupo06/library-checker-problems/tree/master/other/sum_of_exponential_times_polynomial).
The task repository identifies its license as Apache-2.0. This package uses
the task statement and mathematical identities only; implementations and
oracles are clean-room. See [RIGHTS.md](RIGHTS.md).

| Language | Port |
|---|---|
| C | [`c/s/sum_of_exponential_times_polynomial.c`](../../../c/s/sum_of_exponential_times_polynomial.c) |
| C3 | [`c3/s/sum_of_exponential_times_polynomial.c3`](../../../c3/s/sum_of_exponential_times_polynomial.c3) |
| C++ | [`cpp/s/sum_of_exponential_times_polynomial.cpp`](../../../cpp/s/sum_of_exponential_times_polynomial.cpp) |
| Elisa | [`elisa/s/sum_of_exponential_times_polynomial.elisa`](../../../elisa/s/sum_of_exponential_times_polynomial.elisa) |
| Mojo | [`mojo/s/sum_of_exponential_times_polynomial.mojo`](../../../mojo/s/sum_of_exponential_times_polynomial.mojo) |
| Nim | [`nim/s/sum_of_exponential_times_polynomial.nim`](../../../nim/s/sum_of_exponential_times_polynomial.nim) |
| Odin | [`odin/s/sum_of_exponential_times_polynomial.odin`](../../../odin/s/sum_of_exponential_times_polynomial.odin) |
| Rust | [`rust/s/sum_of_exponential_times_polynomial.rs`](../../../rust/s/sum_of_exponential_times_polynomial.rs) |
| V | [`v/s/sum_of_exponential_times_polynomial.v`](../../../v/s/sum_of_exponential_times_polynomial.v) |
| Zig | [`zig/s/sum_of_exponential_times_polynomial.zig`](../../../zig/s/sum_of_exponential_times_polynomial.zig) |

The fixed input/output corpus is in [`workload.json`](workload.json). The
primary and independent oracle modules are
[`sum_of_exponential_times_polynomial_oracle.py`](../../sum_of_exponential_times_polynomial_oracle.py)
and
[`sum_of_exponential_times_polynomial_verifier_oracle.py`](../../sum_of_exponential_times_polynomial_verifier_oracle.py).
The scalar runner and verifier register the workload, both oracles, randomized
and boundary profiles, null input, and malformed-frame cases. The package
checker and suite have not been run.
