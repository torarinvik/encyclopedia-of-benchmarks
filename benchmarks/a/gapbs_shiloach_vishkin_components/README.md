# GAPBS Shiloach–Vishkin connected components

This package is a bounded, clean-room profile of GAPBS `ShiloachVishkin`. It labels each vertex with the minimum vertex ID in its undirected connected component. It preserves the source's min-max hooking rule and parent compression. It is algorithmically distinct from the repository's separate GAPBS Afforest sampling profile and from local DFS and disjoint-set component counters.

## Contract

- Exported symbol: `gapbs_shiloach_vishkin_components` (`i64_array_bytes_output`).
- Input is `[node_count, edge_count, (u,v)...]`, with `1 <= node_count <= 16` and `0 <= edge_count <= 64`.
- Each edge is one canonical pair `u < v`, representing an undirected edge. Duplicate or reversed pairs are invalid. Vertices are scanned in ascending ID order, and each adjacency row is scanned by ascending neighbor ID.
- Initialize each component label to its vertex ID. For every edge, read its endpoint labels; if they differ, compute the larger and smaller labels and hook the larger label to the smaller only when the larger label is still a root. After a full edge sweep, compress each parent path by following grandparents. Repeat until a sweep performs no hooks.
- The pinned source performs parallel in-place updates. This bounded profile fixes the scan order and uses one worker so its execution is deterministic; the min-max hook and compression mechanics are preserved. A `node_count² + 1` round limit guards the bounded implementation.
- Output is one little-endian signed 64-bit minimum-root label per vertex. Success returns `8 * node_count` bytes. Malformed input returns `-1`; null output or insufficient capacity returns `-2` without writing.
- Maximum input length is 130 integers; maximum output is 128 bytes.

The independent oracle uses a stack traversal to find components, rather than the source's repeated hooking sweeps. Workload inputs and expected outputs are in [`workload.json`](workload.json); the oracle is [`gapbs_shiloach_vishkin_components_oracle.py`](../../gapbs_shiloach_vishkin_components_oracle.py).

## Source and rights

Behavior reference: [`src/cc_sv.cc::ShiloachVishkin`](https://github.com/sbeamer/gapbs/blob/b5e3e19c2845f22fb338f4a4bc4b1ccee861d026/src/cc_sv.cc), pinned to GAPBS commit `b5e3e19c2845f22fb338f4a4bc4b1ccee861d026`. The source header attributes copyright to the Regents of the University of California and points to `LICENSE.txt`; the repository license is BSD-3-Clause. These implementations were independently written from the algorithm description and do not copy upstream source or comments. The complete license notice is included in [`LICENSE.txt`](LICENSE.txt).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/gapbs_shiloach_vishkin_components.c`](../../../c/a/gapbs_shiloach_vishkin_components.c) |
| C3 | [`c3/a/gapbs_shiloach_vishkin_components.c3`](../../../c3/a/gapbs_shiloach_vishkin_components.c3) |
| C++ | [`cpp/a/gapbs_shiloach_vishkin_components.cpp`](../../../cpp/a/gapbs_shiloach_vishkin_components.cpp) |
| Elisa | [`elisa/a/gapbs_shiloach_vishkin_components.elisa`](../../../elisa/a/gapbs_shiloach_vishkin_components.elisa) |
| Nim | [`nim/a/gapbs_shiloach_vishkin_components.nim`](../../../nim/a/gapbs_shiloach_vishkin_components.nim) |
| Odin | [`odin/a/gapbs_shiloach_vishkin_components.odin`](../../../odin/a/gapbs_shiloach_vishkin_components.odin) |
| Rust | [`rust/a/gapbs_shiloach_vishkin_components.rs`](../../../rust/a/gapbs_shiloach_vishkin_components.rs) |
| V | [`v/a/gapbs_shiloach_vishkin_components.v`](../../../v/a/gapbs_shiloach_vishkin_components.v) |
| Zig | [`zig/a/gapbs_shiloach_vishkin_components.zig`](../../../zig/a/gapbs_shiloach_vishkin_components.zig) |
