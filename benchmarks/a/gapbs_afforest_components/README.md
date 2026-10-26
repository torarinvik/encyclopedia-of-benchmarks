# GAPBS Afforest connected components

This package is a bounded, clean-room profile of the Afforest connected-components kernel in GAPBS. It returns a minimum-vertex representative for each graph vertex. The local DFS and disjoint-set connected-components benchmarks count components; this profile retains Afforest's sampled neighbor hooking, pointer compression, frequent-sample selection, and remaining-edge pass.

## Contract

- Exported symbol: `gapbs_afforest_components` (`i64_array_bytes_output`).
- Input is `[n, m, sample_count, sample_vertex..., (u,v)...]`. Bounds are `1 <= n <= 16`, `0 <= m <= 64`, and `1 <= sample_count <= 64`.
- Samples must be vertex IDs in `[0,n)`. Each edge is one canonical pair `u < v`; duplicate edges and malformed lengths are rejected. The graph is undirected and simple. Adjacency entries are processed in ascending vertex-ID order.
- The fixed profile performs two sampled-neighbor rounds, compresses after each round, counts the supplied samples' resulting component labels, and resolves equal frequencies to the smallest label. The input explicitly supplies the samples instead of using GAPBS's random 1024-sample generator.
- The remaining-edge pass follows GAPBS's skip of the most-frequent sampled component only when static inspection of the bounded graph confirms that every omitted edge from that component is already internal. If that precondition is false, all remaining edges are processed. This makes the fixed profile exact for every valid input while retaining the source's sampling and linking path.
- Output is `n` little-endian signed 64-bit labels in vertex order. Each label is the minimum vertex ID in that connected component. Success returns `8*n` bytes. Malformed input returns `-1`; null output or insufficient capacity returns `-2` without writing output.
- Maximum input length is 195 integers; maximum output is 128 bytes.

This is a deterministic single-threaded workload profile. It omits GAPBS's random-number generator, OpenMP scheduling, atomics, logging, and timing. The independent oracle uses stack traversal rather than Afforest's hooking algorithm.

## Source and rights

Behavior reference: [`src/cc.cc::Link`, `Compress`, `SampleFrequentElement`, and `Afforest`](https://github.com/sbeamer/gapbs/blob/b5e3e19c2845f22fb338f4a4bc4b1ccee861d026/src/cc.cc), pinned to GAPBS commit `b5e3e19c2845f22fb338f4a4bc4b1ccee861d026`. The source header attributes copyright to the Hebrew University of Jerusalem (HUJI, A. Barak) and points to the repository's `LICENSE`, which is BSD-3-Clause. These implementations were independently written from the algorithm description; they do not copy upstream code or comments. The complete license notice is included in [`LICENSE.txt`](LICENSE.txt).

The fixed cases and expected byte outputs are in [`workload.json`](workload.json); the independent oracle is [`gapbs_afforest_components_oracle.py`](../../gapbs_afforest_components_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/gapbs_afforest_components.c`](../../../c/a/gapbs_afforest_components.c) |
| C3 | [`c3/a/gapbs_afforest_components.c3`](../../../c3/a/gapbs_afforest_components.c3) |
| C++ | [`cpp/a/gapbs_afforest_components.cpp`](../../../cpp/a/gapbs_afforest_components.cpp) |
| Elisa | [`elisa/a/gapbs_afforest_components.elisa`](../../../elisa/a/gapbs_afforest_components.elisa) |
| Nim | [`nim/a/gapbs_afforest_components.nim`](../../../nim/a/gapbs_afforest_components.nim) |
| Odin | [`odin/a/gapbs_afforest_components.odin`](../../../odin/a/gapbs_afforest_components.odin) |
| Rust | [`rust/a/gapbs_afforest_components.rs`](../../../rust/a/gapbs_afforest_components.rs) |
| V | [`v/a/gapbs_afforest_components.v`](../../../v/a/gapbs_afforest_components.v) |
| Zig | [`zig/a/gapbs_afforest_components.zig`](../../../zig/a/gapbs_afforest_components.zig) |
