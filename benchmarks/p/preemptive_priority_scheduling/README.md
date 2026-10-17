# Preemptive priority scheduling

This benchmark follows the pinned Java scheduler one time unit at a time and records the selected process ID at each tick. Higher numeric priority runs first; arrival time breaks priority ties.

## Contract

- The ABI is `i32_array_bytes_output`. Input is `[process_count, (process_id, arrival_time, burst_time, priority)...]` as signed-i32 values, with 0–8 process records and exactly `1 + 4 * process_count` words. IDs are unique integers in `0..7`, arrivals are in `0..16`, bursts are in `1..8`, and priorities are signed-i32 values. The `(priority, arrival_time)` pair must be unique so the Java `PriorityQueue` comparator never has an unresolved tie.
- At each tick, every process with `arrival_time <= current_time` enters the ready queue. The scheduler selects the greatest priority, then the earliest arrival, runs that process for one unit, and reinserts it if its burst remains. If no process is ready, the tick emits the idle marker `-1`. IDs map to their decimal strings in the pinned `ProcessDetails` object and map back to the same integers in the output.
- Output is `[tick_count, id_or_-1_for_idle...]` serialized as little-endian signed-i32 values. An empty process list returns `[0]` in 4 bytes. At most 64 burst ticks and 16 idle ticks are possible, so output is bounded at 324 bytes. Invalid or null input returns `-1` before output-buffer checks; a null output pointer or insufficient capacity returns `-2` without writes.

The fixtures in [workload.json](workload.json) cover preemption, priority and arrival tie-breaking, idle periods, boundary values, malformed inputs, and maximum schedule length. The independent oracle is [preemptive_priority_scheduling_oracle.py](../../preemptive_priority_scheduling_oracle.py).

Pinned sources: [TheAlgorithms/Java `PreemptivePriorityScheduling.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/scheduling/PreemptivePriorityScheduling.java) and its [`ProcessDetails.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/devutils/entities/ProcessDetails.java), both at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.

## Reproduce

~~~
python3 benchmarks/build_abi.py --family i32_array_bytes_output --algorithm preemptive_priority_scheduling --language rust
python3 benchmarks/run_i32_array_bytes_output.py --build-manifest build/i32_array_bytes_output/p/preemptive_priority_scheduling/rust/build.json
python3 benchmarks/verify_i32_array_bytes_output.py --algorithm preemptive_priority_scheduling --languages rust
~~~

## Language ports

| Language | Source |
| --- | --- |
| C | [c/p/preemptive_priority_scheduling.c](../../../c/p/preemptive_priority_scheduling.c) |
| C3 | [c3/p/preemptive_priority_scheduling.c3](../../../c3/p/preemptive_priority_scheduling.c3) |
| C++ | [cpp/p/preemptive_priority_scheduling.cpp](../../../cpp/p/preemptive_priority_scheduling.cpp) |
| Elisa | [elisa/p/preemptive_priority_scheduling.elisa](../../../elisa/p/preemptive_priority_scheduling.elisa) |
| Nim | [nim/p/preemptive_priority_scheduling.nim](../../../nim/p/preemptive_priority_scheduling.nim) |
| Odin | [odin/p/preemptive_priority_scheduling.odin](../../../odin/p/preemptive_priority_scheduling.odin) |
| Rust | [rust/p/preemptive_priority_scheduling.rs](../../../rust/p/preemptive_priority_scheduling.rs) |
| V | [v/p/preemptive_priority_scheduling.v](../../../v/p/preemptive_priority_scheduling.v) |
| Zig | [zig/p/preemptive_priority_scheduling.zig](../../../zig/p/preemptive_priority_scheduling.zig) |
