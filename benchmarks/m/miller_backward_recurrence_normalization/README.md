# Miller backward recurrence normalization

This package benchmarks the bounded Miller trial-and-normalize procedure for
a homogeneous three-term recurrence over `F_998244353`. It focuses on the
finite backward sweep and normalization. The finite-field profile does not
claim that its sequence converges to an analytic recessive solution.

## Contract

Input uses the `i64_array_bytes_output` ABI and is
`[N,(a_n,b_n,c_n) for n=1..N,lambda_0,...,lambda_N]`, with `1<=N<=8` and
all coefficients canonical residues in `[0,998244352]`. Every `c_n` must be
nonzero. Assign the terminal trial values `w_N=1` and `w_(N+1)=0`, then for
`n=N,...,1` apply

```text
w_(n-1) = (b_n*w_n - a_n*w_(n+1)) / c_n   mod 998244353
```

Compute the bounded normalizer `Z=sum_(i=0)^N lambda_i*w_i`. If `Z=0`, the
input is invalid. Otherwise scale each `w_i` by `Z^(-1)`, so the supplied
finite functional of the output is one. This finite sum is the benchmark's
bounded realization of DLMF's linear normalization property. The operation
does not iterate terminal depths or infer convergence.

Malformed input, a zero `c_n`, or zero normalizer returns `-1`. These checks
precede output validation. A null output or capacity below `8*(N+2)` returns
`-2` and leaves output untouched. Success emits `[N,w_0,...,w_N]` as
little-endian signed-i64 words and returns the byte count. All output residues
are canonical.

Valid input lengths range from 6 to 34 words; 35 is the maximum parseable
length for trailing-word rejection. Output ranges from 24 to 80 bytes. Native
ports use a fixed ten-entry trial vector plus scalar state, with a conservative
workspace cap of 192 bytes. Products of residues fit signed 64-bit arithmetic.

The primary reference performs the trial sweep backward and applies the
normalization. The independent reference solves the equivalent upper-
triangular boundary system by back-substitution before normalizing. Primary
time is `O(N log p)` modular operations and uses `O(N)` bounded workspace; the
independent reference takes `O(N^2 + N log p)` and uses an `O(N^2)` matrix.

## Provenance and rights

The algorithm follows NIST DLMF [§3.6(iii), Miller's algorithm](https://dlmf.nist.gov/3.6.iii)
and [normalization equation 3.6.5](https://dlmf.nist.gov/3.6#E5). DLMF
describes assigning trial terminal values, recursing backward, and scaling
the trial solution by a known normalization property. The finite field,
finite functional, validation rules, references, fixtures, and ports are
independently specified. No code, prose, examples, or tests were copied; see
[RIGHTS.md](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [miller_backward_recurrence_normalization.c](../../../c/m/miller_backward_recurrence_normalization.c) |
| C3 | [miller_backward_recurrence_normalization.c3](../../../c3/m/miller_backward_recurrence_normalization.c3) |
| C++ | [miller_backward_recurrence_normalization.cpp](../../../cpp/m/miller_backward_recurrence_normalization.cpp) |
| Elisa | [miller_backward_recurrence_normalization.elisa](../../../elisa/m/miller_backward_recurrence_normalization.elisa) |
| Mojo | [miller_backward_recurrence_normalization.mojo](../../../mojo/m/miller_backward_recurrence_normalization.mojo) |
| Nim | [miller_backward_recurrence_normalization.nim](../../../nim/m/miller_backward_recurrence_normalization.nim) |
| Odin | [miller_backward_recurrence_normalization.odin](../../../odin/m/miller_backward_recurrence_normalization.odin) |
| Rust | [miller_backward_recurrence_normalization.rs](../../../rust/m/miller_backward_recurrence_normalization.rs) |
| V | [miller_backward_recurrence_normalization.v](../../../v/miller_backward_recurrence_normalization.v) |
| Zig | [miller_backward_recurrence_normalization.zig](../../../zig/m/miller_backward_recurrence_normalization.zig) |

The package is registered in the shared byte-output runner and independent
verifier, the root algorithm catalog, and the expansion coverage ledger.
