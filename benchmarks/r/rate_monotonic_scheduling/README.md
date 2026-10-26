# Rate-monotonic scheduling analysis

This profile tests a synchronous periodic task set under rate-monotonic (RM)
priorities. Each task has integer execution requirement `C` and period/deadline
`T`. Tasks with smaller periods have higher fixed priority; equal periods are
ordered by input task ID. The implementation simulates each task's critical
instant, when its job and all higher-priority jobs arrive together, then
reports the target job's response time or a deadline miss.

Input is `[task_count, C_0, T_0, ..., C_(n-1), T_(n-1)]`, with 1–8 tasks,
`1 <= C <= 16`, and `1 <= T <= 32`. Computation and time are integral units;
the profile is the integer-time subset of the chapter's periodic task model.
Output is `[schedulable, first_missed_task_id, response_time_by_input_id...]`
as little-endian signed 64-bit values. `schedulable` is 1 or 0; the missed
task ID is `-1` when all tasks pass. On a miss, that task and lower-priority
tasks have response time `-1`; earlier higher-priority responses are reported.
Invalid input returns `-1`; null output or insufficient capacity returns
`-2` without writing. Maximum output is 80 bytes.

The primary oracle simulates discrete critical-instant jobs. The independent
verifier computes fixed-point response-time recurrences. Both use the chapter's
critical-instant theorem for independent preemptive tasks with implicit
deadlines. The profile excludes non-integer execution, offsets, sporadic
minimum inter-arrival times, shared resources, and deadline-monotonic tasks.

Source: “Rate-Monotonic Scheduling,” Nathan Fisher and Sanjoy K. Baruah,
*Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_334`](https://doi.org/10.1007/978-1-4939-2864-4_334).
The chapter is used only to identify the model and critical-instant method;
the package is clean-room and contains no copied book text, figures, or code.
It is distinct from generic [`preemptive_priority_scheduling`](../preemptive_priority_scheduling/README.md),
whose priorities and arrivals are explicit per process and do not model
periodically recurring jobs.

## Workload and ports

The [workload](workload.json) covers RM ordering, equal-period ties, exact
deadline completion, a missed deadline, maximum task count, malformed task
records, null buffers, and insufficient output capacity. The primary oracle is
[`rate_monotonic_scheduling_oracle.py`](../../rate_monotonic_scheduling_oracle.py);
the independent verifier is
[`rate_monotonic_scheduling_verifier_oracle.py`](../../rate_monotonic_scheduling_verifier_oracle.py).

| Language | Port |
|---|---|
| C | `c/r/rate_monotonic_scheduling.c` |
| C3 | `c3/r/rate_monotonic_scheduling.c3` |
| C++ | `cpp/r/rate_monotonic_scheduling.cpp` |
| Elisa | `elisa/r/rate_monotonic_scheduling.elisa` |
| Nim | `nim/r/rate_monotonic_scheduling.nim` |
| Odin | `odin/r/rate_monotonic_scheduling.odin` |
| Rust | `rust/r/rate_monotonic_scheduling.rs` |
| V | `v/r/rate_monotonic_scheduling.v` |
| Zig | `zig/r/rate_monotonic_scheduling.zig` |
