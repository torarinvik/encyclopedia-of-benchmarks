# Euler alternating series transform

Apply a finite truncation of Euler's forward-difference transformation to a
bounded integer term prefix. The input terms are the `n` values
`a[0..n-1]` in the alternating series `a0 - a1 + a2 - ...`; the package
returns the transformed rational sum exactly.

## Contract

The `i64_array_bytes_output` input is `[n, a0, a1, ..., a(n-1)]`, with
`1 <= n <= 16`, exactly `n + 1` words, and each term in
`[-1,000,000, 1,000,000]`. The result is the first `n` terms of Euler's
transformed series:

`T_n = sum(k=0..n-1) (-1)^k * Δ^k(a0) / 2^(k+1)`.

Forward differences follow `Δ^k(a0) = sum(m=0..k) (-1)^m * C(k,m) * a(k-m)`.
The result is reduced and returned as a little-endian signed-i64
`(numerator, positive_denominator)` pair. A zero result is encoded as `(0,1)`.

Malformed input returns `-1`. A null output buffer or a capacity below 16
bytes returns `-2`. Errors write no bytes. Input validation precedes output
capacity checks and writes.

The largest binomial coefficient used is `C(15,7) = 6435`; coefficient-term
products are at most `6,435,000,000`. A kth forward difference has absolute
value at most `2^k * 1,000,000`, and each weighted term in the common-denominator
numerator is at most `2^15 * 1,000,000`. The full numerator is bounded by
`16 * 2^15 * 1,000,000 = 524,288,000,000`; the denominator is at most 65,536.
All native intermediates therefore fit signed 64-bit arithmetic. Native
ports use scalar locals and `O(1)` auxiliary workspace.

## Algorithm and distinction

The finite profile evaluates Euler's transformed partial sum using forward
differences of the supplied term sequence. It is not the direct alternating
partial sum `a0 - a1 + a2 - ...`, as implemented by the repository's
`alternating_harmonic_series`, and it does not apply Aitken's separate
three-value Δ² sequence transform. The transformation is a finite benchmark
profile; it does not claim that an arbitrary input prefix is convergent or
that the infinite Euler identity applies to every sequence.

The mathematical method follows NIST's [Digital Library of Mathematical
Functions, §3.9(ii), Eqs. 3.9.2–3.9.4](https://dlmf.nist.gov/3.9#E2). The
finite bound, integer input, exact rational output, and error conventions are
benchmark-specific. No source code, task text, prose, examples, or tests are
copied.

## Workload and references

[`workload.json`](workload.json) covers one- and multi-term prefixes, a
nonintegral result, a negative result, a constant prefix, maximum-size
alternating terms, malformed frames, term bounds, null pointers, and output
capacity. [`primary_oracle.py`](primary_oracle.py) applies an in-place forward
difference triangle. [`independent_oracle.py`](independent_oracle.py) evaluates
the binomial form with exact fractions. The package-local
`verify_workload.py` and `check_inventory.py` are static helpers and were not
run.

## Native ports

| Language | Source |
| --- | --- |
| C | [`c/euler_alternating_series_transform.c`](../../../c/e/euler_alternating_series_transform.c) |
| C3 | [`c3/euler_alternating_series_transform.c3`](../../../c3/e/euler_alternating_series_transform.c3) |
| C++ | [`cpp/euler_alternating_series_transform.cpp`](../../../cpp/e/euler_alternating_series_transform.cpp) |
| Elisa | [`elisa/euler_alternating_series_transform.elisa`](../../../elisa/e/euler_alternating_series_transform.elisa) |
| Mojo | [`mojo/euler_alternating_series_transform.mojo`](../../../mojo/e/euler_alternating_series_transform.mojo) |
| Nim | [`nim/euler_alternating_series_transform.nim`](../../../nim/e/euler_alternating_series_transform.nim) |
| Odin | [`odin/euler_alternating_series_transform.odin`](../../../odin/e/euler_alternating_series_transform.odin) |
| Rust | [`rust/euler_alternating_series_transform.rs`](../../../rust/e/euler_alternating_series_transform.rs) |
| V | [`v/euler_alternating_series_transform.v`](../../../v/e/euler_alternating_series_transform.v) |
| Zig | [`zig/euler_alternating_series_transform.zig`](../../../zig/e/euler_alternating_series_transform.zig) |

The byte-output runner/verifier and catalog register this profile. The
package and integration received static source review only; no programs,
tests, scripts, checkers, builds, compilers, profilers, or benchmarks were
run.
