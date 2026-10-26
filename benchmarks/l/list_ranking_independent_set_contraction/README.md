# List ranking by independent-set contraction

This bounded profile implements the chapter's serial independent-set
contraction recurrence for weighted list ranking. Each round colors the
current path with three colors by position, chooses the largest color class
among non-tail vertices (ties go to the lowest color), bridges every selected
vertex out, and adds its weight to its successor. Once one vertex remains,
the removed vertices' ranks are restored in reverse contraction order.

The input is `[n, head, weights_by_id..., successors_by_id...]`. `n` is in
`1..16`; each weight is in `1..10000`. Every successor is either `-1` for the
tail or a vertex ID in `0..n-1`. The links must form one path containing every
vertex, starting at `head`. A rank is the inclusive sum of vertex weights from
the head through that vertex. Output is one little-endian signed 64-bit rank
per vertex, in vertex-ID order. Invalid input returns `-1`; a null output or
capacity below `8*n` returns `-2` without writing.

The exported symbol is `list_ranking_independent_set_contraction`; the ABI is
`i64_array_bytes_output`. The [workload](workload.json) covers weighted and
reordered paths, singleton and maximum-size cases, malformed paths, and
output-capacity probes.

The deterministic profile uses the chapter's explicit serial option of
3-coloring the path and selecting a most-popular color class. Position modulo
three is a proper coloring; excluding the tail ensures every contracted
vertex has a successor to receive its weight. This fixes a concrete bounded
selection rule while retaining the chapter's contraction and restoration
recurrence. The chapter's I/O-complexity analysis, sorting passes, randomized
independent-set selection, parallel coin-tossing, and machine-model costs are
not part of this single-call profile.

Source: “List Ranking,” Riko Jacob, Ulrich Meyer, and Laura Toma, *Encyclopedia
of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_592`](https://doi.org/10.1007/978-1-4939-2864-4_592).
The ports are clean-room implementations and do not copy book prose or source
code. The [primary oracle](../../list_ranking_independent_set_contraction_oracle.py)
uses contraction; the [independent verifier](../../list_ranking_independent_set_contraction_verifier_oracle.py)
computes prefix sums by direct traversal.

| Language | Port |
|---|---|
| C | [`list_ranking_independent_set_contraction.c`](../../../c/l/list_ranking_independent_set_contraction.c) |
| C3 | [`list_ranking_independent_set_contraction.c3`](../../../c3/l/list_ranking_independent_set_contraction.c3) |
| C++ | [`list_ranking_independent_set_contraction.cpp`](../../../cpp/l/list_ranking_independent_set_contraction.cpp) |
| Elisa | [`list_ranking_independent_set_contraction.elisa`](../../../elisa/l/list_ranking_independent_set_contraction.elisa) |
| Nim | [`list_ranking_independent_set_contraction.nim`](../../../nim/l/list_ranking_independent_set_contraction.nim) |
| Odin | [`list_ranking_independent_set_contraction.odin`](../../../odin/l/list_ranking_independent_set_contraction.odin) |
| Rust | [`list_ranking_independent_set_contraction.rs`](../../../rust/l/list_ranking_independent_set_contraction.rs) |
| V | [`list_ranking_independent_set_contraction.v`](../../../v/l/list_ranking_independent_set_contraction.v) |
| Zig | [`list_ranking_independent_set_contraction.zig`](../../../zig/l/list_ranking_independent_set_contraction.zig) |
