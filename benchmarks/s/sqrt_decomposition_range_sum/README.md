# Square-root decomposition range sum

This package adapts the pinned Go `SqrtDecomposition` to integer range-sum queries and point replacement.

## Contract

- ABI: `i64_array_bytes_output`.
- Input is `[n, initial_values[n], op_count, (kind,arg1,arg2)*op_count]`; its exact length is `2+n+3*op_count`.
- `1 <= n <= 64`, `0 <= op_count <= 64`. Initial and replacement values are in `[-1000,1000]`.
- Kind `0` queries the half-open range `[start,end)`, with `0 <= start < end <= n`. It emits that range's sum.
- Kind `1` replaces element `index` with `value`, with `0 <= index < n`. It emits no result.
- Operations run in input order; each query observes earlier replacements. Output contains one little-endian signed-i64 sum per query, in query order. Success returns `8 * query_count` bytes.
- Invalid framing, operation kind, range, index, or value returns `-1` before output storage is checked. Null output returns `-2`, including when there are no queries. A nonnull output with capacity 0 succeeds when there are no queries; otherwise null or short output returns `-2` without writing.
- The adapter creates a fresh decomposition for each call.

## Source behavior

The pinned constructor chooses `blockSize = floor(sqrt(n))` and allocates `ceil(n/blockSize)` block aggregates. It builds each aggregate with the single-element mapping and addition callback. A range query scans the partial blocks at the ends and combines complete block sums in the middle. A point replacement updates its block aggregate as `blockSum - oldValue + newValue` before storing the new element. The bounded sum specialization uses signed-i64 accumulators; every possible sum is within `[-64,000,64,000]`.

This is square-root block decomposition, distinct from a lazy segment tree with range updates.

`workload.json` covers boundary ranges, partial/full blocks, ordered updates and queries, the maximum input/output sizes, and invalid operations. The independent oracle evaluates each query directly from the current list.

## Pinned source

- [Go sqrtdecomposition.go at 5ba447ec5ff3d1213de65b92e726ee74c5d5cc19](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/sqrt/sqrtdecomposition.go)

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm sqrt_decomposition_range_sum --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm sqrt_decomposition_range_sum
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/sqrt_decomposition_range_sum.c`](../../../c/s/sqrt_decomposition_range_sum.c) |
| C3 | [`c3/s/sqrt_decomposition_range_sum.c3`](../../../c3/s/sqrt_decomposition_range_sum.c3) |
| C++ | [`cpp/s/sqrt_decomposition_range_sum.cpp`](../../../cpp/s/sqrt_decomposition_range_sum.cpp) |
| Elisa | [`elisa/s/sqrt_decomposition_range_sum.elisa`](../../../elisa/s/sqrt_decomposition_range_sum.elisa) |
| Nim | [`nim/s/sqrt_decomposition_range_sum.nim`](../../../nim/s/sqrt_decomposition_range_sum.nim) |
| Odin | [`odin/s/sqrt_decomposition_range_sum.odin`](../../../odin/s/sqrt_decomposition_range_sum.odin) |
| Rust | [`rust/s/sqrt_decomposition_range_sum.rs`](../../../rust/s/sqrt_decomposition_range_sum.rs) |
| V | [`v/s/sqrt_decomposition_range_sum.v`](../../../v/s/sqrt_decomposition_range_sum.v) |
| Zig | [`zig/s/sqrt_decomposition_range_sum.zig`](../../../zig/s/sqrt_decomposition_range_sum.zig) |
