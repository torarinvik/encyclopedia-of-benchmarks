# First-Come, First-Served Scheduling

## Contract

Schedule up to 64 non-preemptive processes. The signed 64-bit input is `[process_count, process_id, arrival_time, burst_time, ...]`; process IDs must be unique and in 0..63, arrival times in 0..1,000,000, and burst times in 1..1,000,000. The scheduler orders processes by arrival time, then by ascending process ID for ties. If the CPU is idle, it waits for the next arrival.

For every scheduled process, output six little-endian signed 64-bit integers: process ID, arrival time, burst time, completion time, turnaround time (`completion - arrival`), and waiting time (`turnaround - burst`). Malformed inputs and insufficient output capacity return `-2` without writing output. Ports use fixed-size arrays and portable scalar operations.

The pinned C++ sources include demonstration and self-test code. This package measures only the scheduling calculation.

## Workload and verification

[`workload.json`](workload.json) covers empty and single-process schedules, unsorted input, equal-arrival tie-breaking, idle time, time limits, maximum process count, and malformed inputs. The checker-only verifier compiles all nine ports and checks 5,162 deterministic oracle cases per language without running the timed workload:

```sh
python3 benchmarks/verify_fcfs_scheduling.py
```

If the Elisa compiler is not available as `elisac`, pass its executable path with `--elisa-compiler /path/to/elisac`.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/f/fcfs_scheduling.c](../../../c/f/fcfs_scheduling.c) |
| C3 | [c3/f/fcfs_scheduling.c3](../../../c3/f/fcfs_scheduling.c3) |
| C++ | [cpp/f/fcfs_scheduling.cpp](../../../cpp/f/fcfs_scheduling.cpp) |
| Elisa | [elisa/f/fcfs_scheduling.elisa](../../../elisa/f/fcfs_scheduling.elisa) |
| Nim | [nim/f/fcfs_scheduling.nim](../../../nim/f/fcfs_scheduling.nim) |
| Odin | [odin/f/fcfs_scheduling.odin](../../../odin/f/fcfs_scheduling.odin) |
| Rust | [rust/f/fcfs_scheduling.rs](../../../rust/f/fcfs_scheduling.rs) |
| V | [v/f/fcfs_scheduling.v](../../../v/f/fcfs_scheduling.v) |
| Zig | [zig/f/fcfs_scheduling.zig](../../../zig/f/fcfs_scheduling.zig) |

## TheAlgorithms references

The pinned Julia `fcfs`, Java `FCFSScheduling`, and Python `first_come_first_served` sources take processes in an already selected order and use cumulative burst times to compute waiting and turnaround times. They alias this benchmark on nonempty workloads whose processes are already in FCFS order and are all available before execution. Their source-specific empty-input behavior is outside the shared contract.

- [C++ `fcfs_scheduling.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/cpu_scheduling_algorithms/fcfs_scheduling.cpp)
- [C++-Plus-Plus-1 `fcfs_scheduling.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/cpu_scheduling_algorithms/fcfs_scheduling.cpp)
- [Julia `fcfs.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/scheduling/fcfs.jl)
- [Python `first_come_first_served.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/scheduling/first_come_first_served.py)
- [Java `FCFSScheduling.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/scheduling/FCFSScheduling.java)
