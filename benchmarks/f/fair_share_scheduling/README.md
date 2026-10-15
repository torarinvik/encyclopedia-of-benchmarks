# Fair-Share Scheduling

## Contract

Allocate a fixed resource total among up to 64 users in proportion to the sum of their task weights. The signed 64-bit input is `[user_count, task_count, total_resources, user_id_0, ..., task_owner_0, task_weight_0, ...]`. User IDs are unique and lie in 0..63; there are at most 128 tasks; task owners lie in 0..63; task weights and the resource total lie in 0..1,000,000. Tasks assigned to an ID that is not in the user list are ignored, matching the source's `addTask` behavior.

The output sorts users by ID and emits `[user_id, aggregate_task_weight, allocation]` for each one as little-endian signed 64-bit fields. Allocation is `floor(aggregate_task_weight * total_resources / total_weight)`. When total weight is zero, allocations are zero. Integer remainders are left unallocated, as in the source; they are not redistributed. This contract uses exact bounded integer arithmetic for the mathematical truncation of the source's proportional calculation. Limits keep source-style 32-bit aggregate weights in range and the multiplication in signed 64-bit range. Malformed inputs and insufficient output capacity return `-2` without writing bytes.

## Workload and verification

[`workload.json`](workload.json) covers aggregation, proportional shares, discarded remainders, unknown task owners, zero weights and resources, maximum sizes, and invalid inputs. The checker-only verifier compiles all nine ports and checks 5,997 deterministic oracle cases per language without running the timed workload:

```sh
python3 benchmarks/verify_fair_share_scheduling.py
```

Pass `--elisa-compiler /path/to/elisac` if the Elisa compiler is not available under the default executable name.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/f/fair_share_scheduling.c](../../../c/f/fair_share_scheduling.c) |
| C3 | [c3/f/fair_share_scheduling.c3](../../../c3/f/fair_share_scheduling.c3) |
| C++ | [cpp/f/fair_share_scheduling.cpp](../../../cpp/f/fair_share_scheduling.cpp) |
| Elisa | [elisa/f/fair_share_scheduling.elisa](../../../elisa/f/fair_share_scheduling.elisa) |
| Nim | [nim/f/fair_share_scheduling.nim](../../../nim/f/fair_share_scheduling.nim) |
| Odin | [odin/f/fair_share_scheduling.odin](../../../odin/f/fair_share_scheduling.odin) |
| Rust | [rust/f/fair_share_scheduling.rs](../../../rust/f/fair_share_scheduling.rs) |
| V | [v/f/fair_share_scheduling.v](../../../v/f/fair_share_scheduling.v) |
| Zig | [zig/f/fair_share_scheduling.zig](../../../zig/f/fair_share_scheduling.zig) |

## TheAlgorithms reference

- [Java `FairShareScheduling.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/scheduling/FairShareScheduling.java)
