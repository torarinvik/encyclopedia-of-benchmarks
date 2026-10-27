# Greedy-1 unsplittable-flow routing allocation

This package implements the source-defined Greedy-1 primal-dual routine for unsplittable flow from “Utilitarian Mechanism Design for Single-Minded Agents,” DOI [`10.1007/978-1-4939-2864-4_454`](https://doi.org/10.1007/978-1-4939-2864-4_454), Figure 2. It repeatedly routes each remaining commodity along a minimum current-price path, selects the commodity with maximum value-to-routed-price ratio, raises the prices on that path, and stops at the chapter's dual threshold.

## Bounded contract

- ABI: `i64_array_bytes_output`; input is `[vertex_count,edge_count,commodity_count, (u,v,capacity)[edge_count], (source,target,value)[commodity_count]]`.
- `2<=vertex_count<=8`, `1<=edge_count<=16`, and `1<=commodity_count<=8`. The graph is simple and undirected; edge records are strictly sorted by `(u,v)` with `u<v`. Each commodity's terminal pair must be connected. Edge capacities are integers in `[2,8]`; each commodity has distinct in-range terminals and value `[1,100]`.
- This profile fixes each demand to `d_i=1`, a source-valid subcase of the chapter's `d_i∈[0,1]`. Let `B=min_e b_e` and `m=edge_count`. Initialize `y_e=1/b_e`. Each iteration finds each remaining commodity's minimum-`sum y_e` path by Dijkstra; equal path distances prefer the lower immediate predecessor vertex. It selects the commodity maximizing `c_i/sum_{e in path} y_e`, with ties resolved by lower input index, then multiplies each path edge's price by `(e^(B-1)m)^(1/(b_e-1))`. Stop when `sum_e b_e y_e >= e^(B-1)m` or no commodities remain.
- Output is `[selected_count,(commodity_id,vertex_count,vertex_ids...)...]` in selection order. Maximum input is 75 words and output is 648 bytes. Exponential updates use IEEE-754 binary64; workload instances avoid near-tie comparisons.
- The route-selection and price-update loop is covered; the profile does not compute critical payments or claim to implement the full truthful mechanism. It is distinct from the chapter's Greedy-2 set-packing auction profile.

## Provenance and rights

Source: Piotr Krysta and Berthold Vöcking, “Utilitarian Mechanism Design for Single-Minded Agents,” *Encyclopedia of Algorithms*, DOI `10.1007/978-1-4939-2864-4_454`, Figure 2 and the UFP definitions. The chapter is copyrighted and carries no source-code license. This is a clean-room implementation of the stated mathematical loop and shortest-path subproblem; no code, figure, or prose is copied. See [`RIGHTS.md`](RIGHTS.md).

## Package files

- [`workload.json`](workload.json)
- [primary Dijkstra oracle](../../truthful_ufp_greedy1_oracle.py)
- [independent Bellman-Ford verifier](../../truthful_ufp_greedy1_verifier_oracle.py)

| Language | Port |
|---|---|
| C | [`c/g/truthful_ufp_greedy1.c`](../../../c/g/truthful_ufp_greedy1.c) |
| C3 | [`c3/g/truthful_ufp_greedy1.c3`](../../../c3/g/truthful_ufp_greedy1.c3) |
| C++ | [`cpp/g/truthful_ufp_greedy1.cpp`](../../../cpp/g/truthful_ufp_greedy1.cpp) |
| Elisa | [`elisa/g/truthful_ufp_greedy1.elisa`](../../../elisa/g/truthful_ufp_greedy1.elisa) |
| Nim | [`nim/g/truthful_ufp_greedy1.nim`](../../../nim/g/truthful_ufp_greedy1.nim) |
| Odin | [`odin/g/truthful_ufp_greedy1.odin`](../../../odin/g/truthful_ufp_greedy1.odin) |
| Rust | [`rust/g/truthful_ufp_greedy1.rs`](../../../rust/g/truthful_ufp_greedy1.rs) |
| V | [`v/g/truthful_ufp_greedy1.v`](../../../v/g/truthful_ufp_greedy1.v) |
| Zig | [`zig/g/truthful_ufp_greedy1.zig`](../../../zig/g/truthful_ufp_greedy1.zig) |
