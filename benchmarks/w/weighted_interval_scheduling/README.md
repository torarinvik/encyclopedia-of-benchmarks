# Weighted interval scheduling

Choose a non-overlapping subset of intervals with maximum total weight. The pinned Python implementation sorts intervals stably by finish time, finds each interval's compatible predecessor with `bisect_right`, fills a dynamic-programming table, and reconstructs the selected intervals. Equal-weight choices follow the source's strict `include > exclude` check, so a tie skips the interval being considered during backtracking.

## Contract

The `i64_array_bytes_output` ABI packs input as `[n, start_0, end_0, weight_0, ...]`. It accepts 0 to 64 intervals, with exact length `1 + 3*n`. Starts and ends are integers in `[-100000, 100000]`, each start must be less than its end, and integer weights are in `[0, 1000000]`. Intervals whose end equals another interval's start are compatible.

The output starts with the maximum total weight as a signed 64-bit little-endian integer, then the number of selected intervals as a signed 64-bit little-endian integer, followed by the selected original input indices as signed 32-bit little-endian integers. Indices appear in the source's reconstructed order, which is nondecreasing finish time with stable input order for equal finish times. Success returns the output byte length. Invalid input returns `-1`; a null output pointer or insufficient capacity returns `-2` without writing.

## Workload and source

[`workload.json`](workload.json) covers the pinned examples, ties, touching endpoints, empty schedules, maximum length, invalid intervals, and insufficient output capacity.

- Python [`weighted_interval_scheduling.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/scheduling/weighted_interval_scheduling.py)

## Build and run

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm weighted_interval_scheduling --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/w/weighted_interval_scheduling/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/w/weighted_interval_scheduling.c`](../../../c/w/weighted_interval_scheduling.c) |
| C3 | [`c3/w/weighted_interval_scheduling.c3`](../../../c3/w/weighted_interval_scheduling.c3) |
| C++ | [`cpp/w/weighted_interval_scheduling.cpp`](../../../cpp/w/weighted_interval_scheduling.cpp) |
| Elisa | [`elisa/w/weighted_interval_scheduling.elisa`](../../../elisa/w/weighted_interval_scheduling.elisa) |
| Nim | [`nim/w/weighted_interval_scheduling.nim`](../../../nim/w/weighted_interval_scheduling.nim) |
| Odin | [`odin/w/weighted_interval_scheduling.odin`](../../../odin/w/weighted_interval_scheduling.odin) |
| Rust | [`rust/w/weighted_interval_scheduling.rs`](../../../rust/w/weighted_interval_scheduling.rs) |
| V | [`v/w/weighted_interval_scheduling.v`](../../../v/w/weighted_interval_scheduling.v) |
| Zig | [`zig/w/weighted_interval_scheduling.zig`](../../../zig/w/weighted_interval_scheduling.zig) |
