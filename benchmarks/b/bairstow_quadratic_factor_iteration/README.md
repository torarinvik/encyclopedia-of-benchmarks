# Bairstow quadratic-factor iteration

This package benchmarks the Bairstow update for a quadratic factor, using the
backward `q`/`r` arrays and parameter corrections specified by NIST DLMF.
The bounded profile evaluates those algebraic equations exactly over
`F_998244353` and records a fixed number of updates. It is a finite-field
iteration trace: it makes no claim of convergence to a real quadratic factor
or real roots.

## Contract

The `i64_array_bytes_output` input is
`[N,a_0,...,a_N,s_0,t_0,K]`, where `3<=N<=8`, all polynomial and initial
factor parameters are canonical field residues, the leading coefficient
`a_N` is nonzero, and `1<=K<=4`. The exact input length is `N+5`; maximum
valid and parseable frames are 13 and 14 words.

For each iteration, initialize `q_N=r_N=a_N` and `q_(N+1)=r_(N+1)=0`, then
for `j=N-1,...,0` compute

```text
q_j = a_j + s*q_(j+1) + t*q_(j+2)
r_j = q_j + s*r_(j+1) + t*r_(j+2)
ell = s*r_2 + t*r_3
D = r_2^2 - ell*r_3
delta_s = (r_3*q_0 - r_2*q_1)/D
delta_t = (ell*q_1 - r_2*q_0)/D
s <- s + delta_s
t <- t + delta_t
```

All arithmetic is modulo `998244353`. A zero `D` at any requested step
invalidates the whole call with `-1`; this check precedes output-capacity
handling. Malformed input also returns `-1`. A null output or capacity below
`8*(2*K+3)` returns `-2` without writes. Success emits
`[K+1,s_0,t_0,...,s_K,t_K]` as little-endian signed-i64 words and returns the
byte count, at most 88. Native ports use fixed coefficient, `q`/`r`, and trace
arrays plus scalar state under a 512-byte workspace cap. The accounting
includes 72 bytes of coefficients, 160 bytes for `q`/`r`, 80 bytes for trace
pairs, and a conservative allowance for scalar temporaries and alignment.
Products of field residues fit signed 64-bit arithmetic.

The primary uses the DLMF backward recurrences. The independent reference
computes their values as direct convolution sums using coefficients of
`1/(1-sx-tx^2)`, then applies the same pinned correction equations. The
reference's direct-sum structure provides an independent indexing and
arithmetic check. Native work is `O(KN + K log p)` field operations and
`O(N)` bounded storage; the reference takes `O(KN^2 + K log p)` operations.

## Provenance and distinction

The method is documented by NIST DLMF [§3.8(iv), Bairstow's method](https://dlmf.nist.gov/3.8.iv),
with the recurrence in [Eq. 3.8.10](https://dlmf.nist.gov/3.8.iv#E10) and
updates in [Eq. 3.8.11](https://dlmf.nist.gov/3.8.iv#E11). DLMF describes
real-coefficient polynomial zero finding; this benchmark specializes only its
algebraic iteration equations to a finite field and does not assert real-root
semantics or convergence. Local polynomial factorization, Laguerre iteration,
and Durand–Kerner use different methods and outputs. The profile, code,
fixtures, references, and prose are independently authored; see
[RIGHTS.md](RIGHTS.md).

## Workload and ports

`workload.json` pins exact output traces, a maximum-output case, its
one-byte-short capacity case, singular updates, and malformed frames.
`primary_oracle.py` and `independent_oracle.py` contain the references;
`verify_workload.py` and `check_inventory.py` expose static-only validation
APIs. The package is registered with the `i64_array_bytes_output` runner and
verifier, and appears in the repository catalog.

| Language | Source |
|---|---|
| C | [bairstow_quadratic_factor_iteration.c](../../../c/b/bairstow_quadratic_factor_iteration.c) |
| C3 | [bairstow_quadratic_factor_iteration.c3](../../../c3/b/bairstow_quadratic_factor_iteration.c3) |
| C++ | [bairstow_quadratic_factor_iteration.cpp](../../../cpp/b/bairstow_quadratic_factor_iteration.cpp) |
| Elisa | [bairstow_quadratic_factor_iteration.elisa](../../../elisa/b/bairstow_quadratic_factor_iteration.elisa) |
| Mojo | [bairstow_quadratic_factor_iteration.mojo](../../../mojo/b/bairstow_quadratic_factor_iteration.mojo) |
| Nim | [bairstow_quadratic_factor_iteration.nim](../../../nim/b/bairstow_quadratic_factor_iteration.nim) |
| Odin | [bairstow_quadratic_factor_iteration.odin](../../../odin/b/bairstow_quadratic_factor_iteration.odin) |
| Rust | [bairstow_quadratic_factor_iteration.rs](../../../rust/b/bairstow_quadratic_factor_iteration.rs) |
| V | [bairstow_quadratic_factor_iteration.v](../../../v/b/bairstow_quadratic_factor_iteration.v) |
| Zig | [bairstow_quadratic_factor_iteration.zig](../../../zig/b/bairstow_quadratic_factor_iteration.zig) |
