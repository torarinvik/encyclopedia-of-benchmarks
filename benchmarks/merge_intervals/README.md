# Merge intervals

This package ports the pinned Java and Python implementations of merge intervals. Both sort by ascending start and merge closed intervals whenever the next start is less than or equal to the current end.

## Contract

- The ABI accepts a signed i64 array laid out as `[interval_count, start_0, end_0, ...]`.
- `interval_count` is 0 through 256, the array length must be exactly `1 + 2 * interval_count`, and every endpoint must fit signed i32. Each interval must satisfy `start <= end`.
- Intervals are closed. Overlapping intervals and intervals that touch at an endpoint are merged. Results are sorted by start.
- The byte output is the flat sequence `[start_0, end_0, ...]` encoded as little-endian signed i32 values. No count header is included; the return value is the byte count, so the merged interval count is `return_value / 8`.
- Invalid input returns `-1` before output-buffer checks. A null output pointer returns `-2`, including for empty results. A non-null buffer with capacity 0 succeeds for empty input. Insufficient capacity returns `-2` without writing partial output.
- Maximum output is 2,048 bytes.

The Java source mutates its input rows while merging, while Python sorts a copy. Each ABI call decodes its own input and returns only the merged pairs, so those mutation differences do not affect the observable result.

## Workload and oracle

[workload.json](workload.json) covers empty, overlapping, touching, nested, duplicate, unsorted, signed-boundary, maximum-size, malformed-input, null-output, and short-capacity cases. The independent union-find oracle is [merge_intervals_oracle.py](../merge_intervals_oracle.py).

Pinned sources:

- [TheAlgorithms/Java MergeIntervals.java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/greedyalgorithms/MergeIntervals.java)
- [TheAlgorithms/Python merge_intervals.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/arrays/merge_intervals.py)

## Running and verifying

Build a selected ABI port with:

    python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm merge_intervals --language rust

Record the workload with:

    python3 benchmarks/run_i64_array_bytes_output.py --algorithm merge_intervals

Verify a selected port with:

    python3 benchmarks/verify_i64_array_bytes_output.py --algorithm merge_intervals --languages rust

## Implementations

| Language | Source |
| --- | --- |
| C | [c/m/merge_intervals.c](../../c/m/merge_intervals.c) |
| C3 | [c3/m/merge_intervals.c3](../../c3/m/merge_intervals.c3) |
| C++ | [cpp/m/merge_intervals.cpp](../../cpp/m/merge_intervals.cpp) |
| Elisa | [elisa/m/merge_intervals.elisa](../../elisa/m/merge_intervals.elisa) |
| Nim | [nim/m/merge_intervals.nim](../../nim/m/merge_intervals.nim) |
| Odin | [odin/m/merge_intervals.odin](../../odin/m/merge_intervals.odin) |
| Rust | [rust/m/merge_intervals.rs](../../rust/m/merge_intervals.rs) |
| V | [v/m/merge_intervals.v](../../v/m/merge_intervals.v) |
| Zig | [zig/m/merge_intervals.zig](../../zig/m/merge_intervals.zig) |
