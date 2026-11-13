# Romberg integration

This package benchmarks Romberg's sequence of nested composite trapezoid estimates followed by a triangular Richardson extrapolation. It is distinct from the local fixed-grid trapezoid, midpoint, Simpson, Weddle, and Gaussian-Legendre packages, and from adaptive Simpson, which refines intervals from a local Simpson error estimate rather than extrapolating a global trapezoid sequence.

## Contract

The `float64_slice_io` input contains four finite, integer-valued binary64 values:

```text
[function_id, a_micro, b_micro, levels]
```

The fixed callbacks are `0: exp(x)`, `1: x^5`, `2: 1/(1+x^2)`, and `3: cos(x)`. Endpoints are divided by 1,000,000, lie in `[-1,1]`, and must satisfy `a<=b`. Refinement levels range from 3 through 8. Equal endpoints return zero.

The primary starts with the one-panel trapezoid `R[0,0]`. Each row halves the prior trapezoid estimate and adds the newly sampled odd grid points at the halved spacing. It then computes `R[k,j]=R[k,j-1]+(R[k,j-1]-R[k-1,j-1])/(4^j-1)` and returns the diagonal entry at the requested level. Work is O(2^L + L²) with two fixed rows of at most nine values, for `L<=8`. Those rows use 144 bytes of local scratch plus scalar temporaries; the shared ABI's one-element, 8-byte workspace describes only the external output buffer. Success writes one float64 and returns 1. A null input or malformed frame returns -1; a valid input with a null output or capacity below one returns -2 without writes. Input errors take precedence over output errors.

The primary oracle uses the Romberg recurrence. The independent verifier evaluates closed-form antiderivatives for all four supported functions. The workload checks results with absolute tolerance `2e-5` and relative tolerance `1e-12`; fixture and ABI boundary cases are in [`workload.json`](workload.json). See [`romberg_integration_oracle.py`](../../romberg_integration_oracle.py) and [`romberg_integration_verifier_oracle.py`](../../romberg_integration_verifier_oracle.py).

## Provenance and rights

The algorithm profile follows the high-level description in the [GNU Scientific Library Romberg integration reference](https://www.gnu.org/software/gsl/doc/html/integration.html#romberg-integration). The implementation uses only the mathematical method description; no GSL source code, examples, tests, or prose were copied. The callbacks, fixed-level ABI, fixtures, and ports are clean-room benchmark choices. See [`RIGHTS.md`](RIGHTS.md) for the source record.

## Language ports

| Language | Source |
|---|---|
| C | [`c/r/romberg_integration.c`](../../../c/r/romberg_integration.c) |
| C3 | [`c3/r/romberg_integration.c3`](../../../c3/r/romberg_integration.c3) |
| C++ | [`cpp/r/romberg_integration.cpp`](../../../cpp/r/romberg_integration.cpp) |
| Elisa | [`elisa/r/romberg_integration.elisa`](../../../elisa/r/romberg_integration.elisa) |
| Mojo | [`mojo/r/romberg_integration.mojo`](../../../mojo/r/romberg_integration.mojo) |
| Nim | [`nim/r/romberg_integration.nim`](../../../nim/r/romberg_integration.nim) |
| Odin | [`odin/r/romberg_integration.odin`](../../../odin/r/romberg_integration.odin) |
| Rust | [`rust/r/romberg_integration.rs`](../../../rust/r/romberg_integration.rs) |
| V | [`v/r/romberg_integration.v`](../../../v/r/romberg_integration.v) |
| Zig | [`zig/r/romberg_integration.zig`](../../../zig/r/romberg_integration.zig) |

The source inventory is checked by [`check_romberg_integration_package.py`](../../check_romberg_integration_package.py).
