# Sparse table range minimum query

This benchmark ports the healthy pinned C++ sparse-table implementation for
static range-minimum queries. Each call builds the table for one array and
answers one inclusive query. The result is the zero-based index of the
leftmost minimum element.

## Contract

The `i64_array_scalar` input is `[n, values..., left, right]`. The array length
`n` is in 1..12,344, each value is a signed 64-bit integer, and the query is a
valid zero-based inclusive range with `0 <= left <= right < n`. The scalar
result is the index of the minimum value in that range; equal minima resolve
to the leftmost index, matching the source's `<=` comparisons. Malformed
framing, sizes, or ranges return `-1`.

The pinned C++ source uses fixed arrays with `N=12,345`, including a `LOG`
array indexed through `n`; the safe source-compatible input bound is therefore
`n <= N-1`. The source's sparse-table levels store minimum indices and answer
queries by comparing two overlapping power-of-two blocks. The workload
includes the source's three example ranges as separate calls, duplicate minima,
negative and extreme values, singleton ranges, and malformed inputs.

## Source variants

This package follows the C++ index-returning API. The Python file with the same
name returns minimum values instead of indices, and Rust's
`RangeMinimumQuery` accepts half-open batched queries; these are source/API
variants of the same sparse-table algorithm, not separate benchmarks. The Rust
`range_minimum_query` catalog name aliases this canonical benchmark. The
similarly named `C-Plus-Plus-1/range_queries/sparse_table.cpp` source is broken
and is excluded from the implementation set.

## Pinned source

- TheAlgorithms/C-Plus-Plus [`data_structures/sparse_table.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/data_structures/sparse_table.cpp), commit `fdcc29b0ac2848e9d1a8d926e171cc5b39f97759`
- TheAlgorithms/Rust [`src/data_structures/range_minimum_query.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/data_structures/range_minimum_query.rs), commit `fed66cb0c74c4a939ec5163648458a8c2b46fd4c`

## Workload

The workload is [`workload.json`](workload.json); the independent linear-scan
oracle is [`benchmarks/sparse_table_oracle.py`](../../sparse_table_oracle.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/s/sparse_table.c`](../../../c/s/sparse_table.c) |
| C3 | [`c3/s/sparse_table.c3`](../../../c3/s/sparse_table.c3) |
| C++ | [`cpp/s/sparse_table.cpp`](../../../cpp/s/sparse_table.cpp) |
| Elisa | [`elisa/s/sparse_table.elisa`](../../../elisa/s/sparse_table.elisa) |
| Nim | [`nim/s/sparse_table.nim`](../../../nim/s/sparse_table.nim) |
| Odin | [`odin/s/sparse_table.odin`](../../../odin/s/sparse_table.odin) |
| Rust | [`rust/s/sparse_table.rs`](../../../rust/s/sparse_table.rs) |
| V | [`v/s/sparse_table.v`](../../../v/s/sparse_table.v) |
| Zig | [`zig/s/sparse_table.zig`](../../../zig/s/sparse_table.zig) |
