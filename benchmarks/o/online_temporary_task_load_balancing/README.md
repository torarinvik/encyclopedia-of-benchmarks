# Online temporary-task load balancing

Assign each arriving temporary task immediately to an identical machine with
the smallest active load. A task contributes its weight on the chosen machine
during the half-open interval `[arrival, arrival + duration)`. Tasks that finish
at a time are removed before any task arriving at that same time. Input order
breaks ties between simultaneous arrivals; machine ties go to the lowest ID.
Assignments are irrevocable.

## Contract

The byte-output symbol is `online_temporary_task_load_balancing`. Input is
`[machine_count, task_count, (arrival, weight, duration)*]`. There are 1–8
machines and 0–32 tasks. Arrival times are integers in `[0,1000]` and must be
nondecreasing. Weights and durations are integers in `[1,1000]`, and every
completion time is at most 2000. The exact input length is `2 + 3*task_count`.

The output is a little-endian i64 vector
`[peak_active_load, machine_for_task_0, ..., machine_for_task_(n-1)]`.
Machine IDs are zero-based. With no tasks, the output is `[0]`. Maximum output
capacity is 264 bytes; workspace is 2048 bytes. Invalid input returns `-1`.
Null output or insufficient capacity returns `-2` without writing.

This benchmark profiles the chapter's identical-machine greedy trace. Its
least-current-load selector is Graham's same choice as permanent-job
[`list_scheduling`](../list_scheduling/README.md). The added task-arrival and
expiration events change the online state: active machine loads can decrease
between assignments, and the result records the peak over the full trace. The
primary oracle keeps a min-heap of completion events. The independent verifier
recomputes each machine's active load by scanning the full prior assignment
history, so it does not reuse the primary event structure.

## Provenance and rights

Based on Leah Epstein, “Online Load Balancing of Temporary Tasks,”
*Encyclopedia of Algorithms*, DOI
[10.1007/978-1-4939-2864-4_206](https://doi.org/10.1007/978-1-4939-2864-4_206).
The package uses the chapter's task-arrival/duration model and identical-machine
least-current-load rule. The bounded integer contract, tie refinements, workload,
oracles, and ports are independently authored; no book prose, source code, or
figures are reproduced. See [`RIGHTS.md`](RIGHTS.md),
[`workload.json`](workload.json), the [primary oracle](../../online_temporary_task_load_balancing_oracle.py),
the [independent verifier](../../online_temporary_task_load_balancing_verifier_oracle.py),
and the [static inventory checker](../../check_online_temporary_task_load_balancing_package.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/o/online_temporary_task_load_balancing.c`](../../../c/o/online_temporary_task_load_balancing.c) |
| C3 | [`c3/o/online_temporary_task_load_balancing.c3`](../../../c3/o/online_temporary_task_load_balancing.c3) |
| C++ | [`cpp/o/online_temporary_task_load_balancing.cpp`](../../../cpp/o/online_temporary_task_load_balancing.cpp) |
| Elisa | [`elisa/o/online_temporary_task_load_balancing.elisa`](../../../elisa/o/online_temporary_task_load_balancing.elisa) |
| Mojo | [`mojo/o/online_temporary_task_load_balancing.mojo`](../../../mojo/o/online_temporary_task_load_balancing.mojo) |
| Nim | [`nim/o/online_temporary_task_load_balancing.nim`](../../../nim/o/online_temporary_task_load_balancing.nim) |
| Odin | [`odin/o/online_temporary_task_load_balancing.odin`](../../../odin/o/online_temporary_task_load_balancing.odin) |
| Rust | [`rust/o/online_temporary_task_load_balancing.rs`](../../../rust/o/online_temporary_task_load_balancing.rs) |
| V | [`v/o/online_temporary_task_load_balancing.v`](../../../v/o/online_temporary_task_load_balancing.v) |
| Zig | [`zig/o/online_temporary_task_load_balancing.zig`](../../../zig/o/online_temporary_task_load_balancing.zig) |
