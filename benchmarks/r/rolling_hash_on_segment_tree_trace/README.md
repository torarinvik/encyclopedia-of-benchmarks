# Dynamic rolling-hash substring comparison

This profile combines a segment tree with polynomial rolling hashes to support point assignments and substring-fingerprint comparisons. It is distinct from static pattern search and whole-string hash workloads because updates alter the sequence between queries.

## Contract

- ABI: `i64_array_scalar`. Input is `[N,Q,symbols[N],(opcode,a,b,c,d)*Q]`, with exact framing. `N` and `Q` are each in `0..20`; initial and assigned symbols are in `0..25`.
- Opcode `0` assigns symbol `b` at index `a`; it requires `0<=a<N` and `c=d=0`.
- Opcode `1` compares half-open ranges `[a,b)` and `[c,d)`. Each range must lie within the sequence and have nondecreasing endpoints. Ranges of different lengths compare unequal; two empty ranges compare equal.
- Each leaf stores `(symbol,1)`, the identity is `(0,0)`, and concatenation is `(H_left * BASE^length_right + H_right) mod MODULUS`, with `BASE=911382323` and `MODULUS=1000000007`. The benchmark pins this deterministic fingerprint; equality is hash equality and therefore has the usual rolling-hash collision possibility.
- Updates return response `0`; comparisons return `1` for equal fingerprints and `0` otherwise. The scalar result is `sum(i * (opcode*2 + response + 1))` over one-based operation positions. Invalid input returns `-1`.
- Maximum valid input length is 122 words; maximum parseable length is 123. The fixed segment tree and power table fit in 4096 bytes.

The segment tree stores both hash and segment length, so it can concatenate query fragments in order. Point updates replace one leaf and recompute its ancestors; each valid update and range comparison takes `O(log N)` time after `O(N)` construction.

## Algorithm source

The method is independently specified from [NyaanNyaan Library's rolling hash on segment tree](https://github.com/NyaanNyaan/library/blob/master/string/rolling-hash-on-segment-tree.hpp), whose node stores a hash and length, supports point updates, and compares two half-open ranges after checking their lengths. This profile fixes a deterministic base and modulus for identical results across languages. No source code was copied.

[`workload.json`](workload.json) covers unchanged comparisons, point updates that create equality, overlapping and empty ranges, malformed operands, invalid symbols, and exact-frame rejection.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/r/rolling_hash_on_segment_tree_trace.c`](../../../c/r/rolling_hash_on_segment_tree_trace.c) |
| C3 | [`c3/r/rolling_hash_on_segment_tree_trace.c3`](../../../c3/r/rolling_hash_on_segment_tree_trace.c3) |
| C++ | [`cpp/r/rolling_hash_on_segment_tree_trace.cpp`](../../../cpp/r/rolling_hash_on_segment_tree_trace.cpp) |
| Elisa | [`elisa/r/rolling_hash_on_segment_tree_trace.elisa`](../../../elisa/r/rolling_hash_on_segment_tree_trace.elisa) |
| Mojo | [`mojo/r/rolling_hash_on_segment_tree_trace.mojo`](../../../mojo/r/rolling_hash_on_segment_tree_trace.mojo) |
| Nim | [`nim/r/rolling_hash_on_segment_tree_trace.nim`](../../../nim/r/rolling_hash_on_segment_tree_trace.nim) |
| Odin | [`odin/r/rolling_hash_on_segment_tree_trace.odin`](../../../odin/r/rolling_hash_on_segment_tree_trace.odin) |
| Rust | [`rust/r/rolling_hash_on_segment_tree_trace.rs`](../../../rust/r/rolling_hash_on_segment_tree_trace.rs) |
| V | [`v/r/rolling_hash_on_segment_tree_trace.v`](../../../v/r/rolling_hash_on_segment_tree_trace.v) |
| Zig | [`zig/r/rolling_hash_on_segment_tree_trace.zig`](../../../zig/r/rolling_hash_on_segment_tree_trace.zig) |
