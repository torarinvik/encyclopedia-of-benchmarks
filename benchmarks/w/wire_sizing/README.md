# Wire Sizing

This package implements a bounded, clean-room profile of the wire-sizing quadratic program in Encyclopedia of Algorithms chapter DOI [`10.1007/978-1-4939-2864-4_483`](https://doi.org/10.1007/978-1-4939-2864-4_483). It minimizes the chapter's Elmore-delay objective for a serial wire whose segment widths are supplied in descending order.

## Contract

- ABI: `i64_array_bytes_output`; input is `[n,L,RD,CL,r0,h0,...,h(n-1),c0,...,c(n-1)]`.
- There are 1–6 width choices, total wire length `L` is 1–1000, and `RD`, `CL`, and `r0` are each 1–1000. Widths `h_i` are integers from 1–32 and strictly descending. Their supplied unit capacitances `c_i=c(h_i)` are integers from 1–1000 and strictly descending in the same order. The profile therefore preserves the chapter's `h_1 > ... > h_n` and increasing `c(h)` assumptions while making the technology table explicit.
- The decision variables are nonnegative real segment lengths `l_i` with `sum(l_i)=L`. The objective is `D = 1/2 l^T Phi l + rho^T l + RD*CL`, with `Phi[i,j] = r0*c[max(i,j)]/h[min(i,j)]` and `rho[i] = RD*c[i] + CL*r0/h[i]`.
- To bound and determinize the workload, each port enumerates the nonempty supports of positive segment lengths, solves the associated equality-constrained KKT system, checks nonnegativity and the inactive-variable optimality inequalities, and selects the feasible solution with minimum objective. This is an exhaustive bounded solver for the chapter's convex QP; it is not the chapter's iterative active-set schedule or its O(n^2) implementation.
- Output is little-endian signed 64-bit words `[delay_micro, length0_micro, ...]`. Each nonnegative value is rounded to the nearest micro-unit, with half values rounded upward. The maximum output is 56 bytes. Invalid input returns `-1`; null or short output returns `-2` without writes.

The primary oracle solves the KKT faces with exact rational Gauss-Jordan elimination. The independent verifier oracle uses Cramer's rule with permutation determinants. The byte outputs are consequently checked against exact rational solutions rather than a floating-point reference. Port calculations use binary64 arithmetic; the bounded integer domain and micro-unit result projection are included to keep the suite profile reproducible. A width may receive zero length, which is the chapter's nonnegativity-boundary case.

## Source and rights

The source is Chris Chu's “Wire Sizing” chapter, which summarizes Chu and Wong's 1999 convex-quadratic-programming formulation. The benchmark derives only the displayed objective, coefficients, and constraints; no chapter prose or upstream implementation is copied. See [`RIGHTS.md`](RIGHTS.md) for attribution and redistribution scope.

## Package files

- [`workload.json`](workload.json)
- [`primary oracle`](../../wire_sizing_oracle.py)
- [`independent verifier oracle`](../../wire_sizing_verifier_oracle.py)

| Language | Port |
|---|---|
| C | [`c/w/wire_sizing.c`](../../../c/w/wire_sizing.c) |
| C3 | [`c3/w/wire_sizing.c3`](../../../c3/w/wire_sizing.c3) |
| C++ | [`cpp/w/wire_sizing.cpp`](../../../cpp/w/wire_sizing.cpp) |
| Elisa | [`elisa/w/wire_sizing.elisa`](../../../elisa/w/wire_sizing.elisa) |
| Nim | [`nim/w/wire_sizing.nim`](../../../nim/w/wire_sizing.nim) |
| Odin | [`odin/w/wire_sizing.odin`](../../../odin/w/wire_sizing.odin) |
| Rust | [`rust/w/wire_sizing.rs`](../../../rust/w/wire_sizing.rs) |
| V | [`v/w/wire_sizing.v`](../../../v/w/wire_sizing.v) |
| Zig | [`zig/w/wire_sizing.zig`](../../../zig/w/wire_sizing.zig) |
