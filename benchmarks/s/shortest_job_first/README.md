# Shortest job first (preemptive)

This benchmark ports the pinned Python [`shortest_job_first.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/scheduling/shortest_job_first.py). Despite the filename, `calculate_waitingtime` implements preemptive shortest-remaining-time-first (SRTF): at each integer time it scans jobs in input order, selects a ready job only when its remaining burst is strictly less than the current minimum, and executes that job for one time unit. `calculate_turnaroundtime` returns each burst plus its waiting time.

## Contract

- ABI: `i64_array_bytes_output`. Input is `[job_count, arrival_times[job_count], burst_times[job_count]]`. The count is in `0..32`; arrays have equal lengths by construction. Arrival times are in `0..64` and nonempty jobs have positive burst times in `1..128`.
- The bounded positive-burst domain avoids the source's nontermination for a zero-burst job: that job is never selected and never increments the completion count. The burst limit also stays far below the source's `999999999` minimum-time sentinel. Empty nonnull input `[0]` is valid and returns `[0]`.
- At each integer time, preserve the source's scan order and persistent strict-tie state. If no process has arrived yet, time advances by one. A completed job's waiting time is `max(finish_time - arrival_time - burst_time, 0)`.
- Output is `[job_count, waiting_times..., turnaround_times...]` as signed 64-bit little-endian values. Success returns the byte count, `8 * (1 + 2 * job_count)`, up to 520 bytes. Invalid input, including a null input pointer, returns `-1`. A null output pointer or insufficient capacity returns `-2`; input validation takes precedence and failures do not write output.

The [independent oracle](../../shortest_job_first_oracle.py) and [`workload.json`](workload.json) cover the pinned source examples, idle arrivals, preemption, tie persistence, completion order, malformed vectors, null pointers, and short/exact output capacities.

## Build and verify

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm shortest_job_first --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm shortest_job_first
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm shortest_job_first --languages rust
```

## Implementations

| Language | Port |
|---|---|
| C | [`c/s/shortest_job_first.c`](../../../c/s/shortest_job_first.c) |
| C3 | [`c3/s/shortest_job_first.c3`](../../../c3/s/shortest_job_first.c3) |
| C++ | [`cpp/s/shortest_job_first.cpp`](../../../cpp/s/shortest_job_first.cpp) |
| Elisa | [`elisa/s/shortest_job_first.elisa`](../../../elisa/s/shortest_job_first.elisa) |
| Nim | [`nim/s/shortest_job_first.nim`](../../../nim/s/shortest_job_first.nim) |
| Odin | [`odin/s/shortest_job_first.odin`](../../../odin/s/shortest_job_first.odin) |
| Rust | [`rust/s/shortest_job_first.rs`](../../../rust/s/shortest_job_first.rs) |
| V | [`v/s/shortest_job_first.v`](../../../v/s/shortest_job_first.v) |
| Zig | [`zig/s/shortest_job_first.zig`](../../../zig/s/shortest_job_first.zig) |
