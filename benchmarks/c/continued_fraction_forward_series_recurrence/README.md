# Continued-fraction forward-series recurrence

This benchmark evaluates the bounded forward-series recurrence from NIST DLMF
§3.10(iii), Eq. 3.10.15, over the prime field `F_998244353`. It is distinct
from [`continued_fraction_convergents`](../continued_fraction_convergents/README.md):
that package advances numerator/denominator continuants for general simple-CF
coefficients, while this package advances `rho`, term, and partial-sum state
for the special fraction whose partial sums are its convergents.

## Contract

The `i64_array_bytes_output` input is `[N,a0,...,a_(N-1)]`, where `2<=N<=9`
and each coefficient is a canonical residue in `[0,998244352]`. Define
`rho0=0`, `t0=a0`, and, for `k=1..N-1`,

```text
numerator_k   = a_k * (1 + rho_(k-1)) mod p
denominator_k = 1 - numerator_k mod p
rho_k         = numerator_k / denominator_k mod p
t_k           = rho_k * t_(k-1) mod p
S_(k+1)       = S_k + t_k mod p, with S_1=t_0
```

The operation is invalid if any `denominator_k` is zero. The implementation
preflights every recurrence divisor before checking output capacity, so an
invalid divisor returns `-1` even when the output pointer is null or short.
Other malformed input also returns `-1`. A null output or capacity below
`8*(N+1)` returns `-2` without writing. Success emits little-endian signed-i64
words `[N,S1,...,SN]` and returns the byte count. All output words are
canonical field representatives.

Valid input lengths are 3 through 10 words; 11 words is the maximum parseable
frame for trailing-word rejection. Output ranges from 24 to 80 bytes. Native
ports use zero scratch beyond scalar recurrence state and the caller's output
buffer. Products of canonical residues are below `p^2`, which fits signed
64-bit arithmetic.

The primary reference performs the rho/term recurrence twice: first to reject
any zero divisor before output validation, then to emit results. Each field
inverse uses square-and-multiply exponentiation by `p-2`, so the native time
bound is `O(N log p)` modular operations (`O(N)` for the fixed modulus here)
and `O(1)` scratch. The independent reference evaluates each prefix as a
backward continued fraction using homogeneous numerator/denominator pairs,
avoiding intermediate division. Its time bound is `O(N^2 + N log p)` and it
uses `O(1)` scratch apart from its returned prefix list.

## Provenance and rights

The algorithm is based on [NIST DLMF §3.10(iii), Eq. 3.10.15](https://dlmf.nist.gov/3.10#E15),
which gives the forward rho/term recurrence and states that its partial sums
are the convergents of the associated special continued fraction. The local
`continued_fraction_convergents` package covers a different generalized
continuant method. This package's finite-field domain, error order, references,
fixtures, and ports are independently specified and written. No code, prose,
examples, or tests were copied; see [RIGHTS.md](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [continued_fraction_forward_series_recurrence.c](../../../c/c/continued_fraction_forward_series_recurrence.c) |
| C3 | [continued_fraction_forward_series_recurrence.c3](../../../c3/c/continued_fraction_forward_series_recurrence.c3) |
| C++ | [continued_fraction_forward_series_recurrence.cpp](../../../cpp/c/continued_fraction_forward_series_recurrence.cpp) |
| Elisa | [continued_fraction_forward_series_recurrence.elisa](../../../elisa/c/continued_fraction_forward_series_recurrence.elisa) |
| Mojo | [continued_fraction_forward_series_recurrence.mojo](../../../mojo/c/continued_fraction_forward_series_recurrence.mojo) |
| Nim | [continued_fraction_forward_series_recurrence.nim](../../../nim/c/continued_fraction_forward_series_recurrence.nim) |
| Odin | [continued_fraction_forward_series_recurrence.odin](../../../odin/c/continued_fraction_forward_series_recurrence.odin) |
| Rust | [continued_fraction_forward_series_recurrence.rs](../../../rust/c/continued_fraction_forward_series_recurrence.rs) |
| V | [continued_fraction_forward_series_recurrence.v](../../../v/c/continued_fraction_forward_series_recurrence.v) |
| Zig | [continued_fraction_forward_series_recurrence.zig](../../../zig/c/continued_fraction_forward_series_recurrence.zig) |

The shared byte-output runner and verifier register this package separately.
