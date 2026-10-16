# Difference array range updates

This benchmark follows the pinned Java `DifferenceArray` class: initialize adjacent differences, apply inclusive range additions with two boundary changes per update, then reconstruct the final array with a prefix sum.

## Contract

- The `i64_array_bytes_output` ABI packs `[n, q, initial_values..., (left, right, delta)*]`.
- `n` is `1..=64`, `q` is `0..=64`, and the packed length is exactly `2 + n + 3*q`. Initial values and deltas are in `[-1,000,000, 1,000,000]`. Each update uses zero-based inclusive endpoints satisfying `0 <= left <= right < n`.
- Initialization is `diff[0] = initial[0]` and `diff[i] = initial[i] - initial[i-1]`. Each update applies `diff[left] += delta` and `diff[right+1] -= delta`. Reconstruct by prefix summation and emit the final `n` values as little-endian signed 64-bit integers.
- Invalid packing, values, or ranges return `-1`; a null or undersized output buffer returns `-2`. Success returns `8*n` bytes. Maximum output workspace is 512 bytes.

The bounded initial values keep Java's `int` subtraction during initialization in range. Difference and result storage use `long`, matching the source; these bounds keep all accumulated values far below its limits. The workload measures batch range additions followed by reconstruction, not point queries or a range-sum data structure.

## Pinned source

[TheAlgorithms/Java `DifferenceArray.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/prefixsum/DifferenceArray.java) allocates `n+1` difference entries so `right+1` can be updated without a special boundary branch. The benchmark preserves that update scheme. [`workload.json`](workload.json) covers overlapping and disjoint ranges, endpoints, no updates, and malformed input/capacity cases.

## Build, record, and verify

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm difference_array --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/d/difference_array/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm difference_array --language rust
```

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/d/difference_array.c`](../../../c/d/difference_array.c) |
| C3 | [`c3/d/difference_array.c3`](../../../c3/d/difference_array.c3) |
| C++ | [`cpp/d/difference_array.cpp`](../../../cpp/d/difference_array.cpp) |
| Elisa | [`elisa/d/difference_array.elisa`](../../../elisa/d/difference_array.elisa) |
| Nim | [`nim/d/difference_array.nim`](../../../nim/d/difference_array.nim) |
| Odin | [`odin/d/difference_array.odin`](../../../odin/d/difference_array.odin) |
| Rust | [`rust/d/difference_array.rs`](../../../rust/d/difference_array.rs) |
| V | [`v/d/difference_array.v`](../../../v/d/difference_array.v) |
| Zig | [`zig/d/difference_array.zig`](../../../zig/d/difference_array.zig) |
