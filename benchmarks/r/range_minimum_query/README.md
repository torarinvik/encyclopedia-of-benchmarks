# Static range minimum query

Build a sparse table for a static integer array, then answer range minimum queries in constant time each. This follows the pinned Rust `RangeMinimumQuery` structure and its half-open range convention.

## Contract

- Input is packed as `[n, values..., q, (start, end)...]` in signed 64-bit integers.
- `n` is 1 through 64; each value is in `[-1000, 1000]`; `q` is 1 through 64.
- Each query is half-open `[start, end)`, with `0 <= start < end <= n`.
- Output contains one signed 64-bit minimum per query, in query order, encoded as little-endian bytes. The function returns the number of output bytes (`8*q`).
- Invalid array packing or values return `-1`. Each invalid query maps to `INT64_MIN`; valid answers cannot equal this sentinel because input values are bounded to `[-1000, 1000]`. Insufficient output capacity returns `-2`.
- Preprocessing takes O(n log n) time and space. Each query takes O(1) time.

The source stores indices of interval minima. For each query it selects two overlapping power-of-two blocks covering the requested interval and returns the lower of their values. Equal minima may select either index, but the returned minimum value is the same.

## Source and distinction

The pinned source is Rust `src/data_structures/range_minimum_query.rs` at commit `fed66cb0c74c4a939ec5163648458a8c2b46fd4c`. Its `get_range_min(start, end)` rejects empty/reversed and out-of-bounds ranges. This package maps those per-query errors to the documented sentinel.

The existing [`segment_tree`](../../s/segment_tree/README.md) benchmark includes minimum aggregation along with updates and other aggregate modes. This package isolates the static sparse-table method and its preprocessing/query shape.

- [TheAlgorithms/Rust pinned `range_minimum_query.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/data_structures/range_minimum_query.rs)

## Workload and recording

[`workload.json`](workload.json) covers full, subrange, singleton, duplicate-minimum, invalid-range, out-of-bounds, malformed-packing, and value-bound cases. The nine ports use the shared `i64_array_bytes_output` ABI, whose runner oracle handles the sparse-table query results and per-query invalid-range sentinel.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm range_minimum_query --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm range_minimum_query
```
