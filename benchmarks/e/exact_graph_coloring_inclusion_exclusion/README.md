# Exact graph coloring by inclusion–exclusion

This package implements the chromatic-number criterion from “Exact Graph Coloring Using Inclusion-Exclusion,” *Encyclopedia of Algorithms*, DOI [10.1007/978-1-4939-2864-4_134](https://doi.org/10.1007/978-1-4939-2864-4_134). For each excluded vertex subset `X`, let `s(X)` be the number of nonempty independent vertex subsets disjoint from `X`. For each `k=1..n`, evaluate `sum_X (-1)^|X| s(X)^k`; the first positive value identifies the chromatic number. The implementation computes independent-subset counts by a subset recurrence and then evaluates the alternating sums.

## Contract

Input is `[n,m,edge_pairs[2*m]]` for a simple undirected graph with `1<=n<=7` and `0<=m<=21`. Self-loops, duplicate undirected edges, out-of-range endpoints, and malformed lengths are rejected. Return the chromatic number as one little-endian signed 64-bit integer. The function returns 8 on success, `-1` for malformed input, and `-2` for a null or short output buffer. The n<=7 bound keeps the largest alternating-sum intermediate within signed 64-bit range.

The independent verifier uses exhaustive restricted-growth color assignments rather than the inclusion–exclusion formula. This package is distinct from local greedy/backtracking graph-coloring profiles because it measures the chapter’s independent-set subset counts and alternating-sum criterion.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/e/exact_graph_coloring_inclusion_exclusion.c`](../../../c/e/exact_graph_coloring_inclusion_exclusion.c) |
| C3 | [`c3/e/exact_graph_coloring_inclusion_exclusion.c3`](../../../c3/e/exact_graph_coloring_inclusion_exclusion.c3) |
| C++ | [`cpp/e/exact_graph_coloring_inclusion_exclusion.cpp`](../../../cpp/e/exact_graph_coloring_inclusion_exclusion.cpp) |
| Elisa | [`elisa/e/exact_graph_coloring_inclusion_exclusion.elisa`](../../../elisa/e/exact_graph_coloring_inclusion_exclusion.elisa) |
| Nim | [`nim/e/exact_graph_coloring_inclusion_exclusion.nim`](../../../nim/e/exact_graph_coloring_inclusion_exclusion.nim) |
| Odin | [`odin/e/exact_graph_coloring_inclusion_exclusion.odin`](../../../odin/e/exact_graph_coloring_inclusion_exclusion.odin) |
| Rust | [`rust/e/exact_graph_coloring_inclusion_exclusion.rs`](../../../rust/e/exact_graph_coloring_inclusion_exclusion.rs) |
| V | [`v/e/exact_graph_coloring_inclusion_exclusion.v`](../../../v/e/exact_graph_coloring_inclusion_exclusion.v) |
| Zig | [`zig/e/exact_graph_coloring_inclusion_exclusion.zig`](../../../zig/e/exact_graph_coloring_inclusion_exclusion.zig) |

Primary oracle: [`exact_graph_coloring_inclusion_exclusion_oracle.py`](../../exact_graph_coloring_inclusion_exclusion_oracle.py). Independent verifier: [`exact_graph_coloring_inclusion_exclusion_verifier_oracle.py`](../../exact_graph_coloring_inclusion_exclusion_verifier_oracle.py).

## Attribution and rights

The method is attributed to Andreas Björklund and Thore Husfeldt, “Exact Graph Coloring Using Inclusion-Exclusion,” *Encyclopedia of Algorithms* (2016), DOI 10.1007/978-1-4939-2864-4_134. The chapter is used only to identify the algorithm. No book prose, figures, or code are reproduced; all implementations are independently written. Attribution does not grant rights to redistribute the book.
