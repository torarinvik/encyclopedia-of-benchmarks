# Nonpreemptive shortest-job-first scheduling

This benchmark preserves the execution order returned by the pinned Java
`SJFScheduling` implementation. It uses the nonpreemptive SJF algorithm,
which chooses the shortest burst among processes that have arrived.

## Contract

- ABI: `i32_array_bytes_output`. Input is
  `[process_count, (arrival_time, burst_time)*]` as signed-i32 values, with
  exactly two cells per process. There are 0..64 processes; arrival times are
  0..255 and burst times are 1..255.
- The adapter assigns each process its input index as a unique decimal
  `processId` string. A fresh scheduler is created and
  `scheduleProcesses()` is called once. Processes are stably sorted by
  arrival time. At each dispatch, all processes with arrival time at or before
  the current time enter the ready list. The scheduler selects the smallest
  burst; ties keep the first ready-list process (arrival order, then input
  order). If the ready list is empty, time advances by one. A selected job
  runs to completion before another dispatch.
- Output is the input indices in completion order, as little-endian signed-i32
  values. The return value is the number of bytes written, up to 256 bytes.
  Invalid framing or values and a null input pointer return `-1`. A null
  output pointer or short capacity returns `-2` after validating the full
  input and writes nothing. A nonnull output with zero capacity succeeds for
  an empty process list. The maximum valid input is 129 words; 130 words are
  parseable for malformed trailing-input checks.

[workload.json](workload.json) covers idle periods, nonpreemptive arrivals,
shortest-ready-job selection, stable ties, input bounds, null pointers, and
output capacity. The independent oracle is
[sjfscheduling_oracle.py](../../sjfscheduling_oracle.py).

Pinned source: [TheAlgorithms/Java `SJFScheduling.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/scheduling/SJFScheduling.java)
and its [`ProcessDetails` dependency](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/devutils/entities/ProcessDetails.java),
both at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.

## Reproduce

~~~
python3 benchmarks/build_abi.py --family i32_array_bytes_output --algorithm sjfscheduling --language rust
python3 benchmarks/run_i32_array_bytes_output.py --build-manifest build/i32_array_bytes_output/s/sjfscheduling/rust/build.json
python3 benchmarks/verify_i32_array_bytes_output.py --algorithm sjfscheduling --languages rust
~~~

## Language ports

| Language | Source |
| --- | --- |
| C | [c/s/sjfscheduling.c](../../../c/s/sjfscheduling.c) |
| C3 | [c3/s/sjfscheduling.c3](../../../c3/s/sjfscheduling.c3) |
| C++ | [cpp/s/sjfscheduling.cpp](../../../cpp/s/sjfscheduling.cpp) |
| Elisa | [elisa/s/sjfscheduling.elisa](../../../elisa/s/sjfscheduling.elisa) |
| Nim | [nim/s/sjfscheduling.nim](../../../nim/s/sjfscheduling.nim) |
| Odin | [odin/s/sjfscheduling.odin](../../../odin/s/sjfscheduling.odin) |
| Rust | [rust/s/sjfscheduling.rs](../../../rust/s/sjfscheduling.rs) |
| V | [v/s/sjfscheduling.v](../../../v/s/sjfscheduling.v) |
| Zig | [zig/s/sjfscheduling.zig](../../../zig/s/sjfscheduling.zig) |
