# Prolangs-C all-roots cubic profile

This package captures the real-root path from the pinned `Prolangs-C/allroots` launcher. It uses a Cauchy coefficient bound, a Newton step whose polynomial and derivative are evaluated together with Horner's method, synthetic deflation, the quadratic formula, and the source's follow-up Newton refinements.

## Bounded contract

- The `i64_array_bytes_output` input is exactly four ascending-order integer coefficients: `[4, -4, -1, 1]`, representing `x^3 - x^2 - 4x + 4`.
- The profile is intentionally fixed to this cubic. Its roots `2`, `1`, and `-2` follow the pinned program's output order: the initial Newton root, then the deflated quadratic's plus and minus roots after the source's refinement calls.
- Newton starts with `lower = -sum(abs(coefficients))/abs(leading) - 1` and `upper = sum(abs(coefficients))/abs(leading)`. It uses a relative step tolerance of `5e-6` and a maximum counter of 40, matching the source constants and update rule.
- The source's demonstration polynomial is `[4.1, -3.9, -1, 1]`. The bounded profile uses a nearby exact-root cubic so every language can share a deterministic result without introducing floating-point root drift. The algorithms and source-order control flow are retained.
- Success returns 24 bytes: three little-endian IEEE-754 binary64 values. A malformed or nonmatching input returns `-1`; null output or capacity below 24 returns `-2` without writing.

## Provenance and licensing

Pinned source: [`Prolangs-C/allroots`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/allroots) at commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`, launcher `info.sh`, source files `all.c`, `horners.c`, and `newton.c`. The source attributes the simultaneous Horner evaluation to Algorithm 2.6 in Burden and Faires, *Numerical Analysis*.

No per-package license file or redistribution grant was present in the pinned launcher and source files inspected. These ports are independently written from the documented numerical method and observed call contract; they do not copy the original C source. The original benchmark's text diagnostics are normalized to the three numerical roots in source order.

## ABI and workload

Exported symbol: `prolangs_c_allroots`. Workload: [`workload.json`](workload.json). Independent Python oracle: [`../../prolangs_c_allroots_oracle.py`](../../prolangs_c_allroots_oracle.py).
