# Sequential LUT K-cut enumeration

This is a bounded DAG profile of the K-feasible-cut enumeration used in
sequential circuit technology mapping. A cut element is encoded as a pair
`(node, delay)` where `delay` is the number of flip-flops on the path to the
cut boundary. For a node `v`, the cut set starts with the trivial cut
`{(v,0)}`. For each incoming edge `u -> v` with delay `d`, the profile takes
one cut from `C(u)`, adds `d` to each element's delay, and unions the shifted
cuts across all incoming edges. Unions with more than `K` elements are
discarded. Sets are deduplicated after each node is processed in topological
order.

The input is signed i64 words:

```text
[node_count, K, edge_count, (source, target, edge_delay)...]
```

Nodes are numbered in topological order, so every edge must satisfy
`source < target`. The bounded profile accepts 1–3 nodes, `K` in `{1,2}`, at
most 3 edges, and edge delay 0 or 1. A maximum-delay value of 2 is sufficient
for these DAGs. This fixed topological-order profile avoids the chapter's
general iterative fixed-point process for cyclic sequential networks.

Each cut is encoded in a 9-bit integer mask. Bit `3*node + delay` represents
`(node,delay)`; masks are sorted numerically. Output is little-endian signed
i64 words:

```text
[node_count, cut_count_0, masks..., cut_count_1, masks..., ...]
```

Input length is at most 12 words, output at most 1112 bytes, and fixed
workspace is 4096 bytes. Invalid input returns `-1`; null output or
insufficient capacity returns `-2` without writing. The package implements
the chapter's K-cut recurrence for this bounded DAG projection; it does not
implement LUT covering/area optimization or claim the chapter's general
sequential mapping behavior.

Source: “Sequential Circuit Technology Mapping,” Encyclopedia of Algorithms,
DOI `10.1007/978-1-4939-2864-4_364`, `OEBPS/AChap364.html`, including the
K-feasible cut recurrence and its merge definition. No source-code license is
asserted; the ports are clean-room implementations based on the mathematical
procedure.

Primary and independent verifier oracles:
`benchmarks/sequential_lut_k_cut_enumeration_oracle.py` and
`benchmarks/sequential_lut_k_cut_enumeration_verifier_oracle.py`.

| Language | Port |
|---|---|
| C | `c/s/sequential_lut_k_cut_enumeration.c` |
| C3 | `c3/s/sequential_lut_k_cut_enumeration.c3` |
| C++ | `cpp/s/sequential_lut_k_cut_enumeration.cpp` |
| Elisa | `elisa/s/sequential_lut_k_cut_enumeration.elisa` |
| Nim | `nim/s/sequential_lut_k_cut_enumeration.nim` |
| Odin | `odin/s/sequential_lut_k_cut_enumeration.odin` |
| Rust | `rust/s/sequential_lut_k_cut_enumeration.rs` |
| V | `v/s/sequential_lut_k_cut_enumeration.v` |
| Zig | `zig/s/sequential_lut_k_cut_enumeration.zig` |
