# Degree-ordered simple four-cycle counting

This package counts distinct four-cycle edge sets in a simple undirected
graph. Chords do not invalidate a cycle, so a complete graph on four vertices
contains three four-cycles.

## Contract

The `i64_array_scalar` ABI accepts `[n,m,(u,v)*m]`, with zero-based vertex IDs,
`1<=n<=16`, and `0<=m<=64`. Each edge must use `u<v`; edge pairs must be
strictly lexicographically increasing, which pins duplicate and ordering
semantics. A valid frame has at most 130 words. Up to 131 words are parseable
so a single trailing word can be rejected. Malformed or null input returns
`-1`. The result is bounded above by 5,460, the number of four-cycle edge
sets in the complete graph on 16 vertices.

## Counting method

Order vertices by ascending `(degree, vertex_id)`. For each pivot `a`, visit
each lower-ranked neighbor `b`, then each lower-ranked neighbor `c` of `b`.
For each `c`, add the number of previously visited lower-ranked `b` vertices
that also neighbor `c`, then increment that count. Each pair of such `b`
vertices closes a four-cycle `a-b-c-d-a`. Every cycle has one unique
maximum-ranked pivot and one unique opposite vertex; the other two vertices
are counted as an unordered pair. Equal degrees are ordered by vertex ID.
The oriented two-path enumeration follows the OI Wiki four-cycle method and
takes `O(m sqrt(m))` work after degree ordering. These bounded ports use
fixed-size insertion sorting, so their full preprocessing is `O(n^2)`;
storage is `O(n+m)`.

The independent oracle enumerates each four-vertex set and its three
undirected cycle edge sets directly. It does not use the degree ordering or
two-path counts. The bounded workload includes `K4` (3), `K5` (15), `K8,8`
(784), chorded cycles, sparse graphs, and malformed frames.

This is distinct from [`counting_c4`](../counting_c4/README.md), which counts
edge-ID cycles per input edge in an undirected multigraph and emits an array.
The local input here is a canonical simple edge list and output is one scalar.

See [`RIGHTS.md`](RIGHTS.md) for rights and provenance. The static
[`verify_workload.py`](verify_workload.py) module checks fixture references,
metadata, and the ten source paths without calling a native implementation.

## Ports

| Language | Source |
|---|---|
| C | `c/c/undirected_four_cycle_count_degree_order.c` |
| C3 | `c3/c/undirected_four_cycle_count_degree_order.c3` |
| C++ | `cpp/c/undirected_four_cycle_count_degree_order.cpp` |
| Elisa | `elisa/c/undirected_four_cycle_count_degree_order.elisa` |
| Mojo | `mojo/c/undirected_four_cycle_count_degree_order.mojo` |
| Nim | `nim/c/undirected_four_cycle_count_degree_order.nim` |
| Odin | `odin/c/undirected_four_cycle_count_degree_order.odin` |
| Rust | `rust/c/undirected_four_cycle_count_degree_order.rs` |
| V | `v/c/undirected_four_cycle_count_degree_order.v` |
| Zig | `zig/c/undirected_four_cycle_count_degree_order.zig` |
