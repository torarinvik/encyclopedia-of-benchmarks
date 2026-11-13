# Adaptive Gauss–Kronrod 15-point quadrature

This package benchmarks adaptive numerical integration with the embedded Gauss-7/Kronrod-15 pair. The Kronrod estimate supplies the interval result, while the difference from the embedded Gauss estimate supplies a local error indicator. The algorithm repeatedly bisects the interval with the largest indicator. This differs from the fixed low-order Gauss–Legendre package, adaptive Simpson's whole-versus-halves comparison, and Romberg's nested trapezoid/Richardson table.

## Contract

The `float64_slice_io` input contains exactly five finite, integer-valued binary64 values:

```text
[function_id, a_micro, b_micro, tolerance_exponent, interval_limit]
```

Endpoints are divided by 1,000,000, lie in `[-1,1]`, and must satisfy `a<=b`. The function IDs select `exp(4x)`, `sin(10x)`, `1/(1+9x^2)`, or `x^14`. The tolerance exponent is 6 through 8, and the interval limit is 1 through 16.

For each interval, the primary evaluates one center and seven symmetric Kronrod node pairs. The embedded Gauss estimate reuses the center and the alternating Kronrod nodes. It sums the Kronrod estimates and absolute local differences; while the summed difference exceeds `10^-exponent * max(1,abs(total))`, it splits the interval with greatest error. Ties go to the interval with smaller left endpoint. If the interval limit is reached before convergence, it returns `-3` and writes nothing. Equal endpoints return zero. With at most 16 active intervals, the implementation evaluates at most 31 interval pairs (465 integrand samples); repeated total/error summation and a linear maximum scan give O(L²) list work for L active intervals, and O(L) fixed interval storage.

Success writes one float64 and returns 1. A null input or malformed frame returns -1. A valid input with a null output or capacity below one returns -2 before numerical work. Numerical non-convergence at the interval cap returns -3. All error paths leave output untouched; input errors take precedence over output errors, and output errors take precedence over convergence work. The workload compares successful estimates with exact antiderivatives at absolute and relative tolerances of `2e-7`.

The primary ABI oracle uses a fixed interval array and scans for the largest local error. The independent oracle computes the integral from closed-form antiderivatives and determines the convergence status with a max-priority queue. The fixtures, including cap exhaustion and ABI precedence cases, are recorded in [`workload.json`](workload.json).

## Provenance and rights

The method description follows the Gauss–Kronrod rules and adaptive QAG discussion in the [GNU Scientific Library numerical-integration manual](https://www.gnu.org/software/gsl/doc/html/integration.html). The ports are clean-room implementations of the mathematical method; no GSL source code or documentation text is copied. See [`RIGHTS.md`](RIGHTS.md) for the source and reuse record.

## Language ports

| Language | Source |
|---|---|
| C | [`c/a/adaptive_gauss_kronrod_15_quadrature.c`](../../../c/a/adaptive_gauss_kronrod_15_quadrature.c) |
| C3 | [`c3/a/adaptive_gauss_kronrod_15_quadrature.c3`](../../../c3/a/adaptive_gauss_kronrod_15_quadrature.c3) |
| C++ | [`cpp/a/adaptive_gauss_kronrod_15_quadrature.cpp`](../../../cpp/a/adaptive_gauss_kronrod_15_quadrature.cpp) |
| Elisa | [`elisa/a/adaptive_gauss_kronrod_15_quadrature.elisa`](../../../elisa/a/adaptive_gauss_kronrod_15_quadrature.elisa) |
| Mojo | [`mojo/a/adaptive_gauss_kronrod_15_quadrature.mojo`](../../../mojo/a/adaptive_gauss_kronrod_15_quadrature.mojo) |
| Nim | [`nim/a/adaptive_gauss_kronrod_15_quadrature.nim`](../../../nim/a/adaptive_gauss_kronrod_15_quadrature.nim) |
| Odin | [`odin/a/adaptive_gauss_kronrod_15_quadrature.odin`](../../../odin/a/adaptive_gauss_kronrod_15_quadrature.odin) |
| Rust | [`rust/a/adaptive_gauss_kronrod_15_quadrature.rs`](../../../rust/a/adaptive_gauss_kronrod_15_quadrature.rs) |
| V | [`v/a/adaptive_gauss_kronrod_15_quadrature.v`](../../../v/a/adaptive_gauss_kronrod_15_quadrature.v) |
| Zig | [`zig/a/adaptive_gauss_kronrod_15_quadrature.zig`](../../../zig/a/adaptive_gauss_kronrod_15_quadrature.zig) |

The package inventory is checked by [`benchmarks/check_adaptive_gauss_kronrod_15_quadrature_package.py`](../../check_adaptive_gauss_kronrod_15_quadrature_package.py).
