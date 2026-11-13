# Adaptive Simpson quadrature

This package benchmarks recursive adaptive Simpson integration for three fixed smooth functions. It is distinct from the local Simpson-rule packages, which sample a predetermined uniform grid; here each interval is split only when the coarse and split estimates disagree beyond the local threshold.

## Contract

The `float64_slice_io` input contains exactly five finite, integer-valued binary64 values:

```text
[function_id, a_micro, b_micro, tolerance_exponent, max_depth]
```

The supported functions are `0: x^4`, `1: sin(x)`, and `2: 1/(1+x^2)`. Endpoints are divided by 1,000,000, lie in `[-2,2]`, and must be ordered `a<=b`. The exponent is 7 or 8 and sets epsilon to `10^-exponent`; maximum refinement depth is 8 through 12. Equal endpoints return zero.

For each interval, the primary method compares its Simpson estimate with the sum of the estimates on its two halves. It accepts when the difference is at most `15*epsilon` or the remaining depth is zero, applying the `difference/15` correction. Otherwise it recursively refines both halves with half the error budget. Midpoint samples are reused by child calls. The worst-case work is O(2^D) evaluations and recursion uses O(D) stack frames, with D at most 12. Success writes one float64 and returns 1. A null input or malformed frame returns -1; a valid input with a null output or capacity below one returns -2 without writes. Input errors take precedence over output errors.

The workload uses absolute and relative output tolerances of `1e-7`. The primary ABI oracle reproduces adaptive recursion; the independent verifier uses closed-form antiderivatives for the supported functions. Both are in [`benchmarks/adaptive_simpson_quadrature_oracle.py`](../../adaptive_simpson_quadrature_oracle.py) and [`benchmarks/adaptive_simpson_quadrature_verifier_oracle.py`](../../adaptive_simpson_quadrature_verifier_oracle.py). The bounded fixtures and ABI cases are recorded in [`workload.json`](workload.json).

## Provenance and rights

The algorithm profile is based on the high-level adaptive Simpson description in [OI Wiki — Numerical Integration](https://en.oi-wiki.org/math/integral/#245). OI Wiki states its default content terms are CC BY-SA 4.0 and SATA in its [licensing FAQ](https://www.timothywang.ca/OI-wiki/intro/faq/). The ports are clean-room implementations of the algorithm idea; no upstream source code or task prose was copied. See [`RIGHTS.md`](RIGHTS.md) for the provenance record.

## Language ports

| Language | Source |
|---|---|
| C | [`c/a/adaptive_simpson_quadrature.c`](../../../c/a/adaptive_simpson_quadrature.c) |
| C3 | [`c3/a/adaptive_simpson_quadrature.c3`](../../../c3/a/adaptive_simpson_quadrature.c3) |
| C++ | [`cpp/a/adaptive_simpson_quadrature.cpp`](../../../cpp/a/adaptive_simpson_quadrature.cpp) |
| Elisa | [`elisa/a/adaptive_simpson_quadrature.elisa`](../../../elisa/a/adaptive_simpson_quadrature.elisa) |
| Mojo | [`mojo/a/adaptive_simpson_quadrature.mojo`](../../../mojo/a/adaptive_simpson_quadrature.mojo) |
| Nim | [`nim/a/adaptive_simpson_quadrature.nim`](../../../nim/a/adaptive_simpson_quadrature.nim) |
| Odin | [`odin/a/adaptive_simpson_quadrature.odin`](../../../odin/a/adaptive_simpson_quadrature.odin) |
| Rust | [`rust/a/adaptive_simpson_quadrature.rs`](../../../rust/a/adaptive_simpson_quadrature.rs) |
| V | [`v/a/adaptive_simpson_quadrature.v`](../../../v/a/adaptive_simpson_quadrature.v) |
| Zig | [`zig/a/adaptive_simpson_quadrature.zig`](../../../zig/a/adaptive_simpson_quadrature.zig) |

The package inventory is checked by [`benchmarks/check_adaptive_simpson_quadrature_package.py`](../../check_adaptive_simpson_quadrature_package.py).
