# CPU Scheduling Algorithms

This benchmark isolates the six scheduling modes in the pinned Python `SchedulerEngine`: first come, first served (FCFS), shortest job first (SJF) non-preemptive, SJF preemptive, priority non-preemptive, priority preemptive, and round robin. The Tkinter interface, animation, plotting, and sleep calls are excluded.

## Contract

The signed 64-bit input is `[mode, process_count, quantum, (process_id, arrival_time, burst_time, priority)*]`. Mode values are `0` FCFS, `1` SJF non-preemptive, `2` SJF preemptive, `3` priority non-preemptive, `4` priority preemptive, and `5` round robin. There may be 0 through 32 processes with unique IDs in `0..31`, arrival times in `0..256`, bursts and quantum in `1..32`, and priorities in `[-32, 32]`.

Processes in the output remain in input order. Each process contributes seven little-endian signed 64-bit values: ID, arrival, burst, completion, turnaround (`completion - arrival`), waiting (`turnaround - burst`), and response (first execution time minus arrival). Lower numeric priorities run first. Ties in priority modes retain input order. FCFS, both SJF modes, and round robin first use stable arrival ordering; SJF ties retain that arrival order. Round robin adds newly arrived processes to the ready queue before requeuing a process whose time slice ended. Invalid input returns `-1`; insufficient output capacity returns `-2` without writing.

## Source and scope

The benchmark follows the pinned [`SchedulerEngine`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/scheduling/cpuschedulingalgorithms.py). Its scheduling statistics are retained; GUI behavior is not. The contract requires distinct numeric process IDs, positive bursts, bounded priorities, and positive quantum so results are unambiguous and all six modes terminate.

[`workload.json`](workload.json) covers every mode, arrival gaps, stable tie-breaking, preemption, round-robin queue ordering, input bounds, and malformed records. The verifier compares all nine ports with an independent scheduling oracle.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/cpu_scheduling_algorithms.c`](../../../c/c/cpu_scheduling_algorithms.c) |
| C3 | [`c3/cpu_scheduling_algorithms.c3`](../../../c3/c/cpu_scheduling_algorithms.c3) |
| C++ | [`cpp/cpu_scheduling_algorithms.cpp`](../../../cpp/c/cpu_scheduling_algorithms.cpp) |
| Elisa | [`elisa/cpu_scheduling_algorithms.elisa`](../../../elisa/c/cpu_scheduling_algorithms.elisa) |
| Nim | [`nim/cpu_scheduling_algorithms.nim`](../../../nim/c/cpu_scheduling_algorithms.nim) |
| Odin | [`odin/cpu_scheduling_algorithms.odin`](../../../odin/c/cpu_scheduling_algorithms.odin) |
| Rust | [`rust/cpu_scheduling_algorithms.rs`](../../../rust/c/cpu_scheduling_algorithms.rs) |
| V | [`v/cpu_scheduling_algorithms.v`](../../../v/c/cpu_scheduling_algorithms.v) |
| Zig | [`zig/cpu_scheduling_algorithms.zig`](../../../zig/c/cpu_scheduling_algorithms.zig) |

Run the oracle verifier across all languages with:

```sh
python3 benchmarks/verify_cpu_scheduling_algorithms.py
```
