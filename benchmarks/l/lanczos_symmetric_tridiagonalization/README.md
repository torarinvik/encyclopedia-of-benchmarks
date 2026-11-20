# Lanczos symmetric tridiagonalization

This bounded profile records the coefficient trace produced by the classical
Lanczos three-term recurrence for a real symmetric matrix, following NIST DLMF
§3.2(vi), Eqs. 3.2.21–3.2.22.

## Contract

Input is `[n,k,A_row_major]`. The matrix has order `1<=n<=4`; the requested
trace length satisfies `1<=k<=n`. Every matrix entry must be an exact
integer-valued binary64 number in `[-4,4]`, and symmetry is checked exactly.
The initial vector is fixed to the normalized first coordinate vector
`e_1=(1,0,...,0)`, so the contract has no runtime random source. The exact
frame length is `2+n*n`: at most 18 values are valid and one extra value is
parseable for a trailing-frame rejection.

Starting from `v_0=0`, `v_1=e_1`, and `beta_1=0`, each step forms
`alpha_j=v_j^T A v_j`. For `j<k`, it computes

```text
u = A v_j - alpha_j v_j - beta_j v_(j-1)
beta_(j+1) = sqrt(u^T u)
v_(j+1) = u / beta_(j+1)
```

The result contains only the requested finite coefficient trace:
`[k,alpha_1,...,alpha_k,beta_2,...,beta_k]`. It does not return Lanczos
vectors, an eigenvalue estimate, or the full tridiagonal matrix. If a beta
needed to construct one of the requested vectors is at most `2^-40` or
nonfinite, or a required intermediate is nonfinite, the call returns `-3`
without writing. This threshold distinguishes exact Krylov breakdown from a
small floating residual. For the accepted integer domain, any exact nonzero
Lanczos beta is at least `1/256`: the Krylov columns are integer vectors, so
every nonzero prefix volume is at least one; that volume is the product of
the prefix betas, and each beta is at most `||A||_F <= 16`. At most two other
beta factors remain when `k<=4`, giving the `16^-2` lower bound. Thus the
threshold is far below every exact nonzero beta in this profile. The existing
diagonal breakdown fixture exercises the zero case; no accepted input can
produce a beta at the threshold boundary. The final requested diagonal
coefficient does not require computing `beta_(k+1)`.

Malformed input returns `-1`. A valid frame with null or short output returns
`-2` before any recurrence work; successful calls return `2*k` float64
elements. The maximum output buffer is 8 elements / 64 bytes. Primary scratch
is bounded by 256 bytes, including fixed vectors and coefficient storage.
Comparison uses absolute tolerance `1e-9` and relative tolerance `1e-12`.
Ports use ordinary binary64 operations in the stated order without fast-math
reassociation. Both references and all ports apply the same `2^-40` breakdown
threshold.

The primary reference implements the three-term recurrence directly. The
independent reference constructs successive Krylov powers, orthogonalizes
them with two-pass modified Gram–Schmidt, and reads the coefficients from the
projected matrix `Q^T A Q`. In exact arithmetic both constructions yield the
same trace; this profile remains a small finite numerical workload and does
not claim finite-precision orthogonality for large matrices.

## Duplicate decision and provenance

`qr_eigen_values` and the McCat symmetric eigensolver compute eigenvalue
results by QR-based methods; `power_iteration` estimates a dominant eigenvalue.
This package returns the Lanczos recurrence coefficients derived from one
specified start vector, a different operation and output. The mathematical
description follows [NIST DLMF §3.2(vi), Eqs. 3.2.21–3.2.22](https://dlmf.nist.gov/3.2.vi).
See [RIGHTS.md](RIGHTS.md) for provenance details. Implementations and
fixtures are clean-room.

## Language ports

| Language | Source |
|---|---|
| C | [`c/l/lanczos_symmetric_tridiagonalization.c`](../../../c/l/lanczos_symmetric_tridiagonalization.c) |
| C3 | [`c3/l/lanczos_symmetric_tridiagonalization.c3`](../../../c3/l/lanczos_symmetric_tridiagonalization.c3) |
| C++ | [`cpp/l/lanczos_symmetric_tridiagonalization.cpp`](../../../cpp/l/lanczos_symmetric_tridiagonalization.cpp) |
| Elisa | [`elisa/l/lanczos_symmetric_tridiagonalization.elisa`](../../../elisa/l/lanczos_symmetric_tridiagonalization.elisa) |
| Mojo | [`mojo/l/lanczos_symmetric_tridiagonalization.mojo`](../../../mojo/l/lanczos_symmetric_tridiagonalization.mojo) |
| Nim | [`nim/l/lanczos_symmetric_tridiagonalization.nim`](../../../nim/l/lanczos_symmetric_tridiagonalization.nim) |
| Odin | [`odin/l/lanczos_symmetric_tridiagonalization.odin`](../../../odin/l/lanczos_symmetric_tridiagonalization.odin) |
| Rust | [`rust/l/lanczos_symmetric_tridiagonalization.rs`](../../../rust/l/lanczos_symmetric_tridiagonalization.rs) |
| V | [`v/l/lanczos_symmetric_tridiagonalization.v`](../../../v/l/lanczos_symmetric_tridiagonalization.v) |
| Zig | [`zig/l/lanczos_symmetric_tridiagonalization.zig`](../../../zig/l/lanczos_symmetric_tridiagonalization.zig) |

See [workload.json](workload.json), both references, and the static
[inventory helper](check_inventory.py). No helper or program is run while
drafting.
