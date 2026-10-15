# Prefix sum

Build cumulative sums for an integer array, answer inclusive range-sum queries, and test whether any nonempty contiguous subarray has a requested sum. The package covers the core operations exposed by the pinned prefix-sum implementations.

## Contract

The `i64_array_bytes_output` input is selected by its first two values:

- `[0, n, values...]` returns all inclusive prefix sums `values[0]`, `values[0]+values[1]`, and so on.
- `[1, n, values..., left, right]` returns the sum for the zero-based inclusive range `[left, right]`.
- `[2, n, values..., target]` returns `1` if any nonempty contiguous subarray sums to `target`, else `0`.

The declared length `n` is 0 through 256. Each array element is a signed 32-bit integer. Range queries require a nonempty array and valid ordered endpoints. `target` is in `[-10^12, 10^12]`. Each successful operation emits one or more signed 64-bit words encoded little-endian; the result is the number of words written. Malformed input returns `-1`; insufficient output capacity returns `-2` before writing.

The bounded domain keeps all prefix sums and subtractions in signed 64-bit range. Prefix construction uses an exclusive leading zero internally, then operation 0 emits the inclusive prefixes. The range-query operation follows the sources' inclusive indexing. The contains-sum operation uses a set of prior prefix values, matching Python's `PrefixSum.contains_sum` behavior and excluding an empty subarray.

## Source mapping

Java `PrefixSum` and Python `PrefixSum` preprocess prefix sums and answer inclusive range queries. Python also exposes `contains_sum`. Julia's `prefix_sum` returns the inclusive cumulative-sum vector. The two C++ `prefix_sum_array` candidates build a leading-zero table and answer inclusive range queries; the C++-1 source retains its table in global state, so these stateless benchmark ports rebuild the table for each call. This shared selector ABI makes each family operation observable while keeping the input and output representation the same across all nine target languages.

Pinned sources: [Java `PrefixSum.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/prefixsum/PrefixSum.java), [Python `prefix_sum.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/arrays/prefix_sum.py), [Julia `prefix_sum.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/basic/prefix_sum.jl), [C++ `prefix_sum_array.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/range_queries/prefix_sum_array.cpp), and [C++-1 `prefix_sum_array.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/range_queries/prefix_sum_array.cpp).

## Workload and implementations

The workload covers empty prefixes, negative values, inclusive ranges, a valid result of `-1`, subarray-sum membership with and without negative values, malformed inputs, and insufficient output capacity.

Build and record with:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm prefix_sum --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/p/prefix_sum/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/p/prefix_sum.c`](../../../c/p/prefix_sum.c) |
| C3 | [`c3/p/prefix_sum.c3`](../../../c3/p/prefix_sum.c3) |
| C++ | [`cpp/p/prefix_sum.cpp`](../../../cpp/p/prefix_sum.cpp) |
| Elisa | [`elisa/p/prefix_sum.elisa`](../../../elisa/p/prefix_sum.elisa) |
| Nim | [`nim/p/prefix_sum.nim`](../../../nim/p/prefix_sum.nim) |
| Odin | [`odin/p/prefix_sum.odin`](../../../odin/p/prefix_sum.odin) |
| Rust | [`rust/p/prefix_sum.rs`](../../../rust/p/prefix_sum.rs) |
| V | [`v/p/prefix_sum.v`](../../../v/p/prefix_sum.v) |
| Zig | [`zig/p/prefix_sum.zig`](../../../zig/p/prefix_sum.zig) |
