# GAPBS ordered triangle count

This package provides a bounded clean-room profile of GAPBS `OrderedCount`, which counts triangles in a simple undirected graph. The local `triangle` benchmark concerns geometric triangle centers, and `graph_enumeration` serializes graph adjacency; neither implements graph triangle counting.

## Contract

- The exported function is `gapbs_ordered_triangle_count`, with the `i64_array_scalar` ABI.
- Input is `[n, A[0,0], A[0,1], ..., A[n-1,n-1]]`, where `A` is an `n`-by-`n` row-major adjacency matrix and `1 <= n <= 16`.
- Each matrix value must be 0 or 1. The matrix must be symmetric and have a zero diagonal. These constraints describe a simple undirected graph without self-loops.
- Return the number of unordered 3-cliques (triangles). Return `-1` for a null pointer, malformed length, invalid node count, nonbinary entry, asymmetric matrix, or self-loop.
- The maximum valid result is `C(16,3) = 560`.

The profile follows the ID-order `u > v > w` traversal from `OrderedCount`: adjacency rows are scanned in ascending vertex order to build sorted neighbor lists, then a moving pointer intersects the neighbors of `u` and `v`, stopping at the order bounds. It deliberately fixes this ordered-counting path and omits the GAPBS hybrid wrapper's optional degree-relabel heuristic, so the bounded input does not depend on a separate reordering heuristic.

## Source and rights

Behavior reference: [`src/tc.cc::OrderedCount`](https://github.com/sbeamer/gapbs/blob/b5e3e19c2845f22fb338f4a4bc4b1ccee861d026/src/tc.cc), pinned to GAPBS commit `b5e3e19c2845f22fb338f4a4bc4b1ccee861d026`. The pinned repository's [`LICENSE`](https://github.com/sbeamer/gapbs/blob/b5e3e19c2845f22fb338f4a4bc4b1ccee861d026/LICENSE) is BSD-3-Clause. These ports were independently written from the algorithm description and do not copy upstream code or comments. The package includes the BSD notice for source attribution and rights tracking; see [`LICENSE.txt`](LICENSE.txt).

The independent oracle uses direct enumeration of vertex triples rather than the ordered neighbor-intersection traversal. Fixed inputs and expected results are in [`workload.json`](workload.json), and the oracle is [`gapbs_ordered_triangle_count_oracle.py`](../../gapbs_ordered_triangle_count_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/t/gapbs_ordered_triangle_count.c`](../../../c/t/gapbs_ordered_triangle_count.c) |
| C3 | [`c3/t/gapbs_ordered_triangle_count.c3`](../../../c3/t/gapbs_ordered_triangle_count.c3) |
| C++ | [`cpp/t/gapbs_ordered_triangle_count.cpp`](../../../cpp/t/gapbs_ordered_triangle_count.cpp) |
| Elisa | [`elisa/t/gapbs_ordered_triangle_count.elisa`](../../../elisa/t/gapbs_ordered_triangle_count.elisa) |
| Nim | [`nim/t/gapbs_ordered_triangle_count.nim`](../../../nim/t/gapbs_ordered_triangle_count.nim) |
| Odin | [`odin/t/gapbs_ordered_triangle_count.odin`](../../../odin/t/gapbs_ordered_triangle_count.odin) |
| Rust | [`rust/t/gapbs_ordered_triangle_count.rs`](../../../rust/t/gapbs_ordered_triangle_count.rs) |
| V | [`v/t/gapbs_ordered_triangle_count.v`](../../../v/t/gapbs_ordered_triangle_count.v) |
| Zig | [`zig/t/gapbs_ordered_triangle_count.zig`](../../../zig/t/gapbs_ordered_triangle_count.zig) |
