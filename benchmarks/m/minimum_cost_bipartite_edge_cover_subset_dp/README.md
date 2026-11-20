# Minimum-cost bipartite edge cover by subset DP

This package minimizes the total cost of a set of edges that touches every vertex in a complete weighted bipartite graph. A vertex may be incident to multiple selected edges; this makes the profile different from one-to-one assignment.

## Bounded contract

The `i64_array_scalar` input is `[left_count, right_count, costs row-major]`. Both side sizes are in `1..8`; each cost is an integer in `0..1000`. The frame contains exactly `2 + left_count*right_count` signed 64-bit words, with a 66-word valid maximum and a 67-word parseable maximum. Malformed or null input returns `-1`.

For each left vertex in input order, the primary DP chooses a nonempty subset of right vertices to connect to it. Its state is the set of right vertices covered by processed left vertices. The least cost of the full right mask is the result. Costs are nonnegative, and every left side is required to choose at least one edge. Runtime is `O(left_count * 4^right_count)` and the fixed workspace is 8,192 bytes. The result is in `0..8000`: a complete bipartite graph always has an edge cover using at most `max(left_count,right_count)` edges.

The independent reference starts with each vertex's cheapest incident edge, then computes the maximum-weight matching under transformed pair savings `min_left + min_right - edge_cost`. The edge-cover cost is the sum of all cheapest incident costs minus the selected matching savings. The matching's one-to-one constraint differs from the cover itself; it is used only as an independent exact reduction.

## Provenance

The LeetCode title was used as a discovery lead only. The problem is specified here as a weighted edge cover, based on the formal definition in Hessler and Wästlund, “Edge Cover and Polymatroid Flow Problems,” *Electronic Journal of Probability* 15 (2010), [article](https://www.maths.tcd.ie/EMIS/journals/EJP-ECP/article/view/846.html). The independent reference follows the minimum-weight matching reduction in Ferdous, Pothen, and Halappanavar, “Streaming Matching and Edge Cover in Practice,” SEA 2024, [DOI 10.4230/LIPIcs.SEA.2024.12](https://doi.org/10.4230/LIPIcs.SEA.2024.12). See [`RIGHTS.md`](RIGHTS.md), [`workload.json`](workload.json), both references, [`INVENTORY.json`](INVENTORY.json), and [`check_inventory.py`](check_inventory.py). No task text, examples, tests, submissions, or source code were reused.

## Language ports

| Language | Source |
|---|---|
| C | [`c/m/minimum_cost_bipartite_edge_cover_subset_dp.c`](../../../c/m/minimum_cost_bipartite_edge_cover_subset_dp.c) |
| C3 | [`c3/m/minimum_cost_bipartite_edge_cover_subset_dp.c3`](../../../c3/m/minimum_cost_bipartite_edge_cover_subset_dp.c3) |
| C++ | [`cpp/m/minimum_cost_bipartite_edge_cover_subset_dp.cpp`](../../../cpp/m/minimum_cost_bipartite_edge_cover_subset_dp.cpp) |
| Elisa | [`elisa/m/minimum_cost_bipartite_edge_cover_subset_dp.elisa`](../../../elisa/m/minimum_cost_bipartite_edge_cover_subset_dp.elisa) |
| Mojo | [`mojo/m/minimum_cost_bipartite_edge_cover_subset_dp.mojo`](../../../mojo/m/minimum_cost_bipartite_edge_cover_subset_dp.mojo) |
| Nim | [`nim/m/minimum_cost_bipartite_edge_cover_subset_dp.nim`](../../../nim/m/minimum_cost_bipartite_edge_cover_subset_dp.nim) |
| Odin | [`odin/m/minimum_cost_bipartite_edge_cover_subset_dp.odin`](../../../odin/m/minimum_cost_bipartite_edge_cover_subset_dp.odin) |
| Rust | [`rust/m/minimum_cost_bipartite_edge_cover_subset_dp.rs`](../../../rust/m/minimum_cost_bipartite_edge_cover_subset_dp.rs) |
| V | [`v/m/minimum_cost_bipartite_edge_cover_subset_dp.v`](../../../v/m/minimum_cost_bipartite_edge_cover_subset_dp.v) |
| Zig | [`zig/m/minimum_cost_bipartite_edge_cover_subset_dp.zig`](../../../zig/m/minimum_cost_bipartite_edge_cover_subset_dp.zig) |

The package-local [`check_inventory.py`](check_inventory.py) statically reviews source paths, metadata, and workload framing; it is not run as part of benchmark measurement.
