# Fast AMS second-moment sketch

This package models the “fast AMS” streaming sketch from the chapter “AMS Sketch,” *Encyclopedia of Algorithms* (DOI [10.1007/978-1-4939-2864-4_578](https://doi.org/10.1007/978-1-4939-2864-4_578)). For each stream update, every row maps the item to a bucket and adds its signed update multiplied by a row/item sign. A row estimates the second frequency moment by summing the squares of its bucket counters; the sketch returns the median row estimate.

## Contract

The `i64_array_bytes_output` frame is `[depth,width,key_count,update_count,(bucket,sign)*(depth*key_count),(key,weight)*update_count]`. Depth is odd and 1, 3, or 5; width is 1–8; there are 1–8 key IDs and at most 16 updates. Hash outcomes are supplied explicitly as a deterministic bounded profile: each row/key pair has a bucket in `[0,width)` and a sign of `-1` or `+1`. Updates name a key ID and have a signed weight in `[-1000,1000]`. For each row, the port adds `weight*sign` into the selected bucket; the output is the median of the rows' sums of squared counters. Odd depth avoids an unspecified even-median convention.

The maximum input frame is 116 signed-i64 values and output is one little-endian signed-i64 estimate (8 bytes). Malformed input returns `-1`; null or short output returns `-2`. The entire input is validated before capacity checks, and the output is written only after both succeed. This bounded deterministic profile does not claim the source's probabilistic error guarantee: it supplies one explicit set of hash outcomes and measures the update/query core, not hash-family construction or randomness.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/ams_sketch.c`](../../../c/a/ams_sketch.c) |
| C3 | [`c3/a/ams_sketch.c3`](../../../c3/a/ams_sketch.c3) |
| C++ | [`cpp/a/ams_sketch.cpp`](../../../cpp/a/ams_sketch.cpp) |
| Elisa | [`elisa/a/ams_sketch.elisa`](../../../elisa/a/ams_sketch.elisa) |
| Nim | [`nim/a/ams_sketch.nim`](../../../nim/a/ams_sketch.nim) |
| Odin | [`odin/a/ams_sketch.odin`](../../../odin/a/ams_sketch.odin) |
| Rust | [`rust/a/ams_sketch.rs`](../../../rust/a/ams_sketch.rs) |
| V | [`v/a/ams_sketch.v`](../../../v/a/ams_sketch.v) |
| Zig | [`zig/a/ams_sketch.zig`](../../../zig/a/ams_sketch.zig) |

The primary oracle is [`ams_sketch_oracle.py`](../../ams_sketch_oracle.py); the independent verifier recomputes row estimates from a dictionary of bucket counters in [`ams_sketch_verifier_oracle.py`](../../ams_sketch_verifier_oracle.py).

## Attribution and rights

The algorithm is attributed to Alon, Matias, and Szegedy and to Graham Cormode’s “AMS Sketch,” *Encyclopedia of Algorithms* (2016), DOI 10.1007/978-1-4939-2864-4_578. The Springer chapter is used only to identify the operation. No chapter prose, figures, or code are reproduced; all ports are independently written. This attribution does not grant rights to redistribute the book.
