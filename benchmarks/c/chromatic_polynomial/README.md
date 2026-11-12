# Chromatic polynomial by deletion–contraction

This package returns every integer coefficient of the chromatic polynomial
`P_G(x)` for a bounded simple undirected graph. It implements the recurrence
`P_G(x) = P_(G-e)(x) - P_(G/e)(x)` and the edgeless base case `x^n`. Edge
contraction merges the endpoints and coalesces any parallel edges created by
the merge. The output is stored in ascending degree order.

## Contract

Input is `[n, m, (u, v)*m]`, with `0<=n<=8` and `0<=m<=16`. The graph must be
simple: endpoints are in `[0,n)`, self-loops and duplicate undirected edges are
rejected. The empty graph with zero vertices is valid. Output contains the
`n+1` signed 64-bit coefficients `[c_0,...,c_n]` such that
`P_G(x) = sum(c_i*x^i)`, each encoded little-endian. Invalid input returns
`-1`; null output or capacity below `8*(n+1)` returns `-2`, without writing.
The maximum input is 34 words and the maximum output is 72 bytes.

Deletion–contraction has exponential worst-case time. The local edge bound of
16 caps the recursion tree; each recursive state stores an 8-vertex adjacency
bitset and a degree-at-most-8 coefficient vector. The primary oracle uses the
same recurrence on immutable adjacency tuples. An independent oracle computes
coefficients with the spanning-subgraph inclusion–exclusion formula.

## Provenance and rights

The recurrence and edgeless base case are documented in the chromatic
polynomial chapter of [Sagan, *Combinatorics: A Guided Tour*](https://users.math.msu.edu/users/bsagan/Books/Aoc/GSM210.pdf)
and summarized by [Wolfram MathWorld](https://mathworld.wolfram.com/ChromaticPolynomial.html).
The [NetworkX reference](https://networkx.org/documentation/networkx-3.0/reference/algorithms/generated/networkx.algorithms.polynomials.chromatic_polynomial.html)
also documents the recurrence and the independent edge-subset formula used by
the verifier. These sources supply mathematical definitions only. No source
code, prose, or fixture data is copied; all implementations and cases are
independently authored. See [`RIGHTS.md`](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [`c/c/chromatic_polynomial.c`](../../../c/c/chromatic_polynomial.c) |
| C3 | [`c3/c/chromatic_polynomial.c3`](../../../c3/c/chromatic_polynomial.c3) |
| C++ | [`cpp/c/chromatic_polynomial.cpp`](../../../cpp/c/chromatic_polynomial.cpp) |
| Elisa | [`elisa/c/chromatic_polynomial.elisa`](../../../elisa/c/chromatic_polynomial.elisa) |
| Mojo | [`mojo/c/chromatic_polynomial.mojo`](../../../mojo/c/chromatic_polynomial.mojo) |
| Nim | [`nim/c/chromatic_polynomial.nim`](../../../nim/c/chromatic_polynomial.nim) |
| Odin | [`odin/c/chromatic_polynomial.odin`](../../../odin/c/chromatic_polynomial.odin) |
| Rust | [`rust/c/chromatic_polynomial.rs`](../../../rust/c/chromatic_polynomial.rs) |
| V | [`v/c/chromatic_polynomial.v`](../../../v/c/chromatic_polynomial.v) |
| Zig | [`zig/c/chromatic_polynomial.zig`](../../../zig/c/chromatic_polynomial.zig) |

See [`workload.json`](workload.json), [`oracle.py`](oracle.py),
[`independent_oracle.py`](independent_oracle.py), and [`verify_workload.py`](verify_workload.py).
