# Round-robin scheduling

This package ports the pinned Python [`round_robin.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/scheduling/round_robin.py). It preserves `calculate_waiting_times` with a fixed quantum of two, all jobs ready at time zero, and input-order cycling. It then preserves `calculate_turn_around_times` as burst plus waiting time for each corresponding pair; the source uses `zip`, so this benchmark supplies equal-length lists.

## Contract

- ABI: `i64_array_bytes_output`. Input is `[job_count, burst_0, ..., burst_(job_count-1)]`; the count must be in `0..32`, the burst list must have exactly `job_count` elements, and each burst must be an integer in `0..4096`.
- Every job arrives at time zero. In each round, visit unfinished jobs in input order and run each for two time units or its remaining burst, whichever is smaller. A zero-burst job is already finished and keeps waiting time zero.
- Output is `[job_count, waiting_times..., turnaround_times...]`, encoded as signed 64-bit little-endian values. Turnaround values equal burst plus waiting time. Empty nonnull input `[0]` returns the explicit vector `[0]`.
- Success returns the number of output bytes, `8 * (1 + 2 * job_count)`. Invalid input, including a null input pointer, returns `-1`. A null output pointer or insufficient output capacity returns `-2`; input validation has precedence. Failures do not write output. Maximum output and workspace are 520 bytes.

The burst limit bounds the cyclic simulation while keeping all elapsed-time arithmetic exact in signed 64-bit values. The [independent oracle](../../round_robin_oracle.py) and [`workload.json`](workload.json) cover the source examples, quantum boundaries, zero bursts, input order, the maximum job count, malformed input, null pointers, and short/exact output capacities.

## Build and verify

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm round_robin --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm round_robin
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm round_robin --languages rust
```

## Implementations

| Language | Port |
|---|---|
| C | [`c/r/round_robin.c`](../../../c/r/round_robin.c) |
| C3 | [`c3/r/round_robin.c3`](../../../c3/r/round_robin.c3) |
| C++ | [`cpp/r/round_robin.cpp`](../../../cpp/r/round_robin.cpp) |
| Elisa | [`elisa/r/round_robin.elisa`](../../../elisa/r/round_robin.elisa) |
| Nim | [`nim/r/round_robin.nim`](../../../nim/r/round_robin.nim) |
| Odin | [`odin/r/round_robin.odin`](../../../odin/r/round_robin.odin) |
| Rust | [`rust/r/round_robin.rs`](../../../rust/r/round_robin.rs) |
| V | [`v/r/round_robin.v`](../../../v/r/round_robin.v) |
| Zig | [`zig/r/round_robin.zig`](../../../zig/r/round_robin.zig) |
