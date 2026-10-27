# Sugiyama barycentric crossing reduction

This bounded profile implements the chapter's Step 2 Down-Up crossing
reduction on an already proper layered hierarchy. It performs a downward
barycentric sweep and an upward barycentric sweep, repeating until the layer
orders stop changing or the supplied sweep limit is reached.

Input is a signed-i64 array:

    [layer_count, max_sweeps,
     layer_0_size, layer_0_vertex_ids...,
     ...,
     layer_(L-1)_size, layer_(L-1)_vertex_ids...,
     edge_count, source_0, target_0, ...]

There are 2–8 nonempty layers, at most 32 distinct vertex IDs (each in
0–31), at most 128 distinct directed edges, and 0–16 sweeps. Every edge must
go from a vertex in layer i to a vertex in layer i+1. The hierarchy is supplied
already proper, so DAG reversal, layer assignment, long-edge dummy insertion,
and horizontal-coordinate placement are outside this profile.

For a target-layer vertex with neighbors in the fixed adjacent layer, the
barycenter is the arithmetic mean of their current positions. Vertices are
ordered by increasing barycenter; equal barycenters retain their current order.
An isolated vertex retains its current position as a deterministic refinement.
The procedure counts complete Down-Up sweeps, including the final unchanged
sweep. With a zero sweep limit, the initial order is returned.

Output is little-endian signed-i64:

    [sweeps_performed, adjacent_layer_crossing_count, final_layer_orders...]

The concatenated orders follow the layer sizes in the input. Input bounds are
299 words, output bounds are 272 bytes, and workspace is 4,096 bytes. Invalid
input returns -1. Null output or insufficient capacity returns -2 without
writes. The output count is 8*(vertex_count+2) bytes.

Source: Nikola S. Nikolov, Sugiyama Algorithm, Encyclopedia of Algorithms,
DOI 10.1007/978-1-4939-2864-4_649, OEBPS/AChap649.html, Down-Up Procedure.
The chapter identifies the barycentric ordering and the Down-Up stopping
rule. Fixed hierarchy input, stable ties, isolated-vertex handling, sweep
limit, and integer framing are bounded-profile refinements. No source-code
license is asserted; these are clean-room implementations.

Primary and independent verifier oracles:
benchmarks/sugiyama_barycentric_crossing_reduction_oracle.py and
benchmarks/sugiyama_barycentric_crossing_reduction_verifier_oracle.py.

| Language | Port |
|---|---|
| C | c/s/sugiyama_barycentric_crossing_reduction.c |
| C3 | c3/s/sugiyama_barycentric_crossing_reduction.c3 |
| C++ | cpp/s/sugiyama_barycentric_crossing_reduction.cpp |
| Elisa | elisa/s/sugiyama_barycentric_crossing_reduction.elisa |
| Nim | nim/s/sugiyama_barycentric_crossing_reduction.nim |
| Odin | odin/s/sugiyama_barycentric_crossing_reduction.odin |
| Rust | rust/s/sugiyama_barycentric_crossing_reduction.rs |
| V | v/s/sugiyama_barycentric_crossing_reduction.v |
| Zig | zig/s/sugiyama_barycentric_crossing_reduction.zig |
