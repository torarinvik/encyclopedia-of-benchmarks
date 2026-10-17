# Multi-level feedback queue scheduler

This benchmark follows the pinned Java `MLFQScheduler` with a bounded, sequential process list. All processes enter queue 0 in input order. Each outer pass scans queues from highest to lowest priority and runs at most one process from each nonempty queue for the smaller of its remaining burst and that queue's quantum. An unfinished process moves down one queue, or returns to the end of the final queue. Because the scan continues to lower queues, a demoted process can run again during the same outer pass. Finished processes are recorded immediately in scheduler order.

The source stores but ignores `arrivalTime`; the contract retains it as input and does not delay a process. Priority is incremented on demotion but does not affect queue selection. Positive quanta and nonnegative bounded bursts ensure the scheduler terminates within the selected integer range. A zero burst completes at the current time without advancing it.

## Contract

Input is `[level_count, process_count, quantum[level_count], (pid, burst, arrival_time)*]`. There are 1–4 levels, 0–16 processes, and each quantum is 1–32. Process IDs are signed 32-bit integers, burst times are 0–1000, and arrival times are 0–1,000,000.

Output is a little-endian signed 64-bit vector `[current_time, completion_count, (pid, finish_time)*]`. Completion pairs follow the exact order in which the source finishes processes. The function returns the number of output elements. Invalid input returns `-1`; a null or undersized output buffer returns `-2` without writing. With no processes, output is `[0, 0]`.

See [workload](workload.json), [oracle](../../mlfqscheduler_oracle.py), and the pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/scheduling/MLFQScheduler.java).

| Language | Port |
|---|---|
| C | [c/m/mlfqscheduler.c](../../../c/m/mlfqscheduler.c) |
| C3 | [c3/m/mlfqscheduler.c3](../../../c3/m/mlfqscheduler.c3) |
| C++ | [cpp/m/mlfqscheduler.cpp](../../../cpp/m/mlfqscheduler.cpp) |
| Elisa | [elisa/m/mlfqscheduler.elisa](../../../elisa/m/mlfqscheduler.elisa) |
| Nim | [nim/m/mlfqscheduler.nim](../../../nim/m/mlfqscheduler.nim) |
| Odin | [odin/m/mlfqscheduler.odin](../../../odin/m/mlfqscheduler.odin) |
| Rust | [rust/m/mlfqscheduler.rs](../../../rust/m/mlfqscheduler.rs) |
| V | [v/m/mlfqscheduler.v](../../../v/m/mlfqscheduler.v) |
| Zig | [zig/m/mlfqscheduler.zig](../../../zig/m/mlfqscheduler.zig) |
