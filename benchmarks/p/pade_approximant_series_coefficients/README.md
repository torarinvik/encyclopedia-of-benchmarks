# Padé approximant coefficients from a formal series

This package computes the normalized Padé approximant `[p/q]` at zero from a finite series prefix over the prime field `F_998244353`. The source definition is NIST DLMF §3.11(iv), Eqs. 3.11.20–3.11.23: a rational function `N(z)/D(z)` matches the supplied formal series through degree `p+q`. This is distinct from local [`thiele_rational_interpolation`](../../t/thiele_rational_interpolation/README.md), which fits ordered sample point/value pairs using reciprocal differences, and [`rational_approximation`](../../r/rational_approximation/README.md), which finds bounded Stern–Brocot neighbors for one rational target.

## Contract

Input is `[p,q,c0,...,c_(p+q)]`, where `1<=q<=p<=4` and every coefficient is a canonical residue in `[0,998244352]`. The formal series begins `f(z)=sum c_i z^i`. The benchmark fixes denominator constant `b0=1`, so the normalized denominator is `D(z)=1+b1*z+...+bq*z^q`.

For each `m=p+1,...,p+q`, matching coefficients in `N-fD` gives

```text
sum(j=1..q, c_(m-j)*b_j) = -c_m  (mod 998244353)
```

The primary builds this q-by-q system and solves it with modular Gauss–Jordan elimination. A singular system returns `-3`; this bounded profile accepts only Padé entries with a unique normalized denominator. After solving, the numerator is formed by convolution:

```text
a_m = sum(j=0..min(m,q), c_(m-j)*b_j),  m=0..p
```

The output words are `[p,q,a0,...,ap,b0,...,bq]`, all canonical residues. The independent reference evaluates the q-by-q determinants and Cramer's numerators by a permutation expansion; the small bound `q<=4` keeps that reference practical and structurally different from elimination.

The ABI is `i64_array_bytes_output`. Valid input length is `p+q+3`, at most 11 words; one additional parseable word is allowed to test trailing-frame rejection. The maximum successful output contains 12 signed-i64 words (96 bytes). Malformed input returns `-1`. A valid input with null output or capacity below the exact output size returns `-2` before solving. A sufficiently sized output buffer with a singular denominator system returns `-3`. All error cases leave output untouched. Native scratch is bounded to 256 bytes: a 9-residue coefficient array and a 4-by-5 augmented matrix, with scalar temporary state.

The primary and independent references both use modular arithmetic, but derive the denominator by different procedures. `workload.json` pins nonsingular, singular, maximum-output, framing, and ABI cases; the output is exact, with no floating tolerance.

## Provenance and rights

The mathematical contract follows NIST DLMF §3.11(iv), Eqs. 3.11.20–3.11.23. No DLMF source code, comments, examples, tests, or prose was copied. The fixed finite-field profile, coefficient frames, fixtures, and all implementations are clean-room benchmark choices. See [`RIGHTS.md`](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [`c/p/pade_approximant_series_coefficients.c`](../../../c/p/pade_approximant_series_coefficients.c) |
| C3 | [`c3/p/pade_approximant_series_coefficients.c3`](../../../c3/p/pade_approximant_series_coefficients.c3) |
| C++ | [`cpp/p/pade_approximant_series_coefficients.cpp`](../../../cpp/p/pade_approximant_series_coefficients.cpp) |
| Elisa | [`elisa/p/pade_approximant_series_coefficients.elisa`](../../../elisa/p/pade_approximant_series_coefficients.elisa) |
| Mojo | [`mojo/p/pade_approximant_series_coefficients.mojo`](../../../mojo/p/pade_approximant_series_coefficients.mojo) |
| Nim | [`nim/p/pade_approximant_series_coefficients.nim`](../../../nim/p/pade_approximant_series_coefficients.nim) |
| Odin | [`odin/p/pade_approximant_series_coefficients.odin`](../../../odin/p/pade_approximant_series_coefficients.odin) |
| Rust | [`rust/p/pade_approximant_series_coefficients.rs`](../../../rust/p/pade_approximant_series_coefficients.rs) |
| V | [`v/p/pade_approximant_series_coefficients.v`](../../../v/p/pade_approximant_series_coefficients.v) |
| Zig | [`zig/p/pade_approximant_series_coefficients.zig`](../../../zig/p/pade_approximant_series_coefficients.zig) |

Package-local workload and source inventories are [`verify_workload.py`](verify_workload.py) and [`check_inventory.py`](check_inventory.py). No validation helper is run as part of drafting.
