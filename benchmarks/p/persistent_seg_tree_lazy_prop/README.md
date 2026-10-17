# Persistent segment tree with lazy range updates

This package benchmarks the pinned C++ persistent segment tree with inclusive
range-add updates and historical range-sum queries. Each update applies to the
latest version and appends a version; a query selects any version created so
far. This remains distinct from the existing point-update
[`persistent_segment_tree`](../persistent_segment_tree/README.md) benchmark.

## Contract

The `i64_array_scalar` input is
`[n, q, initial_values[n], (op, a, b, c)*q]` with exact length
`2 + n + 4*q`. The array length `n` is 1..64, operation count `q` is 0..64,
and initial values and update deltas are in -1,000..1,000.

- `op=0` is an update record `(0, left, right, delta)`. It adds `delta` to
  every element in the inclusive range and appends a new version derived from
  the latest version.
- `op=1` is a query record `(1, version, left, right)`. It returns the sum of
  the inclusive range in the selected version, where version 0 is the initial
  array and version `k` is the result after `k` updates already seen.

Both endpoints must satisfy `0 <= left <= right < n`. A query version must be
in `0..version_count-1`. The scalar result is the low 63 bits of FNV-1a-64 over
`[version_count, query_count, query_sum_0, ...]`, with every word encoded as
signed 64-bit little-endian two's complement. The FNV offset basis is
`14695981039346656037` and the prime is `1099511628211`. Malformed input
returns `-1`.

The [independent oracle](../../persistent_seg_tree_lazy_prop_oracle.py) stores
plain array snapshots for each version and scans the requested ranges. The
[workload](workload.json) covers historical reads, full and partial updates,
overlapping and zero-delta updates, negative deltas, single-element ranges,
and invalid versions and endpoints.

## Upstream sources

- [TheAlgorithms/C-Plus-Plus `persistent_seg_tree_lazy_prop.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/range_queries/persistent_seg_tree_lazy_prop.cpp)
- [TheAlgorithms/C-Plus-Plus-1 `persistent_seg_tree_lazy_prop.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/range_queries/persistent_seg_tree_lazy_prop.cpp)

| Language | Port |
|---|---|
| C | [`c/p/persistent_seg_tree_lazy_prop.c`](../../../c/p/persistent_seg_tree_lazy_prop.c) |
| C3 | [`c3/p/persistent_seg_tree_lazy_prop.c3`](../../../c3/p/persistent_seg_tree_lazy_prop.c3) |
| C++ | [`cpp/p/persistent_seg_tree_lazy_prop.cpp`](../../../cpp/p/persistent_seg_tree_lazy_prop.cpp) |
| Elisa | [`elisa/p/persistent_seg_tree_lazy_prop.elisa`](../../../elisa/p/persistent_seg_tree_lazy_prop.elisa) |
| Nim | [`nim/p/persistent_seg_tree_lazy_prop.nim`](../../../nim/p/persistent_seg_tree_lazy_prop.nim) |
| Odin | [`odin/p/persistent_seg_tree_lazy_prop.odin`](../../../odin/p/persistent_seg_tree_lazy_prop.odin) |
| Rust | [`rust/p/persistent_seg_tree_lazy_prop.rs`](../../../rust/p/persistent_seg_tree_lazy_prop.rs) |
| V | [`v/p/persistent_seg_tree_lazy_prop.v`](../../../v/p/persistent_seg_tree_lazy_prop.v) |
| Zig | [`zig/p/persistent_seg_tree_lazy_prop.zig`](../../../zig/p/persistent_seg_tree_lazy_prop.zig) |
