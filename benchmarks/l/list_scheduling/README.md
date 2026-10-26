# Graham list scheduling

Jobs arrive in the supplied order. Each is assigned immediately to the
identical machine with the smallest current load; ties go to the lowest
machine ID. The result includes makespan, the machine selected for each job,
and final machine loads.

Input is `[machine_count, job_count, processing_times...]`, with 1–8 machines,
1–32 positive integer job sizes, and sizes at most 10,000. Output is a
little-endian signed-i64 vector. Invalid input returns `-1`; null output or
insufficient capacity returns `-2` without writing.

Source: “List Scheduling,” DOI
[`10.1007/978-1-4939-2864-4_205`](https://doi.org/10.1007/978-1-4939-2864-4_205).
This is a deterministic clean-room bounded profile of Graham's online rule.

| Language | Port |
|---|---|
| C | `c/l/list_scheduling.c` |
| C3 | `c3/l/list_scheduling.c3` |
| C++ | `cpp/l/list_scheduling.cpp` |
| Elisa | `elisa/l/list_scheduling.elisa` |
| Nim | `nim/l/list_scheduling.nim` |
| Odin | `odin/l/list_scheduling.odin` |
| Rust | `rust/l/list_scheduling.rs` |
| V | `v/l/list_scheduling.v` |
| Zig | `zig/l/list_scheduling.zig` |
