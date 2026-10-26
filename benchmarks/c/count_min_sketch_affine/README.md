# Bounded Count-Min sketch with affine row hashes

This package isolates the core Count-Min sketch update and point-query operations described in the “Count-Min Sketch” chapter of *Encyclopedia of Algorithms* (DOI [10.1007/978-1-4939-2864-4_579](https://doi.org/10.1007/978-1-4939-2864-4_579)). The chapter is used to identify the algorithm and its semantics; this package is an independent implementation and does not reproduce book text or code.

This profile supports widths 1–8 and depths 1–4, with deterministic caller-supplied affine row hashes. Width one remains a supported special case. For prime `P = 2,147,483,647`, row `j` maps key `x` to `((a[j] * x + b[j]) mod P) mod width`, where `a[j]` is in `[1,P-1]` and `b[j]` is in `[0,P-1]`. This fixes the hash family and seed as explicit input, avoiding process randomness while retaining the row-hash plus counter-sketch operation.

## Contract

The `i64_array_bytes_output` input is `[depth, width, operation_count, (a,b)*depth, (kind,key,weight)*operation_count]`. Depth is 1–4, width 1–8, and there are at most 16 operations. Kind `0` adds a positive weight to all row counters selected by the key hashes. Kind `1` emits the minimum selected counter as a point-frequency estimate and requires weight 0. Keys are 0–1,000,000 and update weights are 1–1,000,000. Every counter and output estimate is signed-i64 safe.

Output is one little-endian signed-i64 estimate per query in operation order. The return value is output bytes; malformed frames return `-1`; insufficient capacity or a null output pointer when output is nonempty returns `-2`. Input is fully validated before capacity is checked, and output is written only after validation and capacity checks. A valid stream with no queries succeeds with zero bytes and permits a null output pointer.

This deterministic bounded profile does not claim a probabilistic error guarantee: it exercises the Count-Min table updates and minimum-row point query for supplied affine hashes, without measuring hash-family quality, range queries, heavy hitters, quantiles, inner products, or conservative updates.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/count_min_sketch_affine.c`](../../../c/c/count_min_sketch_affine.c) |
| C3 | [`c3/c/count_min_sketch_affine.c3`](../../../c3/c/count_min_sketch_affine.c3) |
| C++ | [`cpp/c/count_min_sketch_affine.cpp`](../../../cpp/c/count_min_sketch_affine.cpp) |
| Elisa | [`elisa/c/count_min_sketch_affine.elisa`](../../../elisa/c/count_min_sketch_affine.elisa) |
| Nim | [`nim/c/count_min_sketch_affine.nim`](../../../nim/c/count_min_sketch_affine.nim) |
| Odin | [`odin/c/count_min_sketch_affine.odin`](../../../odin/c/count_min_sketch_affine.odin) |
| Rust | [`rust/c/count_min_sketch_affine.rs`](../../../rust/c/count_min_sketch_affine.rs) |
| V | [`v/c/count_min_sketch_affine.v`](../../../v/c/count_min_sketch_affine.v) |
| Zig | [`zig/c/count_min_sketch_affine.zig`](../../../zig/c/count_min_sketch_affine.zig) |

The primary oracle is [`count_min_sketch_affine_oracle.py`](../../count_min_sketch_affine_oracle.py); the independent table-oriented verifier model is [`count_min_sketch_affine_verifier_oracle.py`](../../count_min_sketch_affine_verifier_oracle.py).

## Rights and attribution

The chapter is copyrighted by Springer Science+Business Media. No chapter prose, figures, or source code are reproduced here. The implementation is independently written from the standard Count-Min sketch operation summarized above. The algorithm description is attributed to Graham Cormode, “Count-Min Sketch,” *Encyclopedia of Algorithms* (2016), DOI 10.1007/978-1-4939-2864-4_579. This attribution does not imply a license to redistribute the book.
