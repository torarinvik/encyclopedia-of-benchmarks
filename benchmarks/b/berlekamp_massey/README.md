# Berlekamp–Massey recurrence inference

Infer the shortest predictive linear recurrence for a finite sequence over
`F_998244353`. The recurrence coefficients use the convention
`a_i = sum(c[j] * a_(i-j-1))` for `i >= L`, where `L` is the recurrence order.
The result stores `L` followed by `c[0]` through `c[L-1]`.

## Contract

Input is `[K, a_0, ..., a_(2K-1)]`, where `1 <= K <= 8`, exactly `2K`
sequence terms are supplied, and every term is in `[0, 998244353)`. `K` is an
upper bound on the shortest recurrence order; sequences whose inferred order
exceeds it are invalid. A zero sequence has order zero. Output is `L+1`
signed 64-bit little-endian words: the order, then the predictive coefficients.
The maximum output is 72 bytes. Invalid input returns `-1`; null output or
insufficient capacity returns `-2` without writing.

## Algorithm and distinctness

The ports apply Berlekamp–Massey over the prime field. They scan terms in
order, compute the current prediction discrepancy, and update the candidate
recurrence using the saved candidate and discrepancy from the last order
increase. With at most `2K` terms and `K <= 8`, work is bounded by `O(K^2)`
field operations and `O(K)` storage.

The independent oracle solves the recurrence equations for increasing orders
by modular Gaussian elimination. This package returns the inferred recurrence
itself. `linear_recurrence_matrix` accepts a supplied transition matrix and
exponentiates it; `sparse_matrix_det` uses Berlekamp–Massey internally but
returns a determinant. Neither exposes recurrence inference as its output.

The algorithm definition and the `2K`-term order-bound property are described
by the [OI Wiki Berlekamp–Massey article](https://oiwiki.com/math/berlekamp-massey/).
The ports are clean-room implementations of that algorithm idea.

[`workload.json`](workload.json) covers zero, constant, geometric, Fibonacci,
second-order and third-order sequences, leading zero terms, the maximum order,
malformed input, and output-buffer behavior.

## Implementations

| Language | Port |
|---|---|
| C | [`c/b/berlekamp_massey.c`](../../../c/b/berlekamp_massey.c) |
| C3 | [`c3/b/berlekamp_massey.c3`](../../../c3/b/berlekamp_massey.c3) |
| C++ | [`cpp/b/berlekamp_massey.cpp`](../../../cpp/b/berlekamp_massey.cpp) |
| Elisa | [`elisa/b/berlekamp_massey.elisa`](../../../elisa/b/berlekamp_massey.elisa) |
| Mojo | [`mojo/b/berlekamp_massey.mojo`](../../../mojo/b/berlekamp_massey.mojo) |
| Nim | [`nim/b/berlekamp_massey.nim`](../../../nim/b/berlekamp_massey.nim) |
| Odin | [`odin/b/berlekamp_massey.odin`](../../../odin/b/berlekamp_massey.odin) |
| Rust | [`rust/b/berlekamp_massey.rs`](../../../rust/b/berlekamp_massey.rs) |
| V | [`v/b/berlekamp_massey.v`](../../../v/b/berlekamp_massey.v) |
| Zig | [`zig/b/berlekamp_massey.zig`](../../../zig/b/berlekamp_massey.zig) |
