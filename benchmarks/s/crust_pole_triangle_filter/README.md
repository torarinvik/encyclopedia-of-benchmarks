# Crust pole-adjacency triangle filter

This package implements the explicit filtering step in the chapter's Crust
algorithm. It accepts a supplied list of triangular facets from the augmented
Delaunay triangulation of samples and poles, then retains only facets whose
three vertices are all samples. Pole vertices are identified by a contiguous
ID range after the sample IDs. Reversed/duplicate sample-only facets are
canonicalized to sorted vertex triples and emitted once in lexicographic
order.

The input is signed i64 words:

```text
[sample_count, pole_count, facet_count, (vertex_a,vertex_b,vertex_c)...]
```

Sample IDs are `0..sample_count-1`; pole IDs are
`sample_count..sample_count+pole_count-1`. The profile accepts 3–8 samples,
1–4 supplied poles, at most 12 total vertices, and 0–16 supplied facets.
Input length is at most 51 words. Output is little-endian signed i64:

```text
[retained_facet_count, (sample_a,sample_b,sample_c)...]
```

The maximum output is 392 bytes; fixed workspace is 4096 bytes. Invalid input
returns `-1`; null output or insufficient capacity returns `-2` without
writing. This profile assumes the supplied facets already come from the
augmented Delaunay computation. Pole generation from Voronoi cells, Delaunay
construction, orienting a watertight surface, and repairing noisy or sparse
reconstructions are excluded.

Source: Nina Amenta, “Surface Reconstruction,” Encyclopedia of Algorithms,
DOI `10.1007/978-1-4939-2864-4_713`, `OEBPS/AChap713.html`, “Crust Algorithm.”
The chapter describes choosing farthest Voronoi-cell poles and filtering
augmented-Delaunay output triangles adjacent to a pole. It provides no
source-code license grant; these ports are clean-room implementations of the
filtering step.

Primary and independent verifier oracles:
`benchmarks/crust_pole_triangle_filter_oracle.py` and
`benchmarks/crust_pole_triangle_filter_verifier_oracle.py`.

| Language | Port |
|---|---|
| C | `c/c/crust_pole_triangle_filter.c` |
| C3 | `c3/c/crust_pole_triangle_filter.c3` |
| C++ | `cpp/c/crust_pole_triangle_filter.cpp` |
| Elisa | `elisa/c/crust_pole_triangle_filter.elisa` |
| Nim | `nim/c/crust_pole_triangle_filter.nim` |
| Odin | `odin/c/crust_pole_triangle_filter.odin` |
| Rust | `rust/c/crust_pole_triangle_filter.rs` |
| V | `v/c/crust_pole_triangle_filter.v` |
| Zig | `zig/c/crust_pole_triangle_filter.zig` |
