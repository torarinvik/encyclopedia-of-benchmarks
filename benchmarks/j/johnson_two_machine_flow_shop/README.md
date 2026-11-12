# Johnson's two-machine flow shop

This benchmark returns the minimum makespan for a sequence of jobs that must
visit machine 1 and then machine 2, with both machines processing at most one
job at a time. All jobs follow the same order on both machines. The primary
ports use Johnson's rule: jobs with `a_i < b_i` go first, ordered by increasing
`a_i`; the remaining jobs go last, ordered by decreasing `b_i`.

## Contract

The exported scalar ABI symbol is `johnson_two_machine_flow_shop`. Input is a
signed 64-bit array `[N,(a_i,b_i)*N]`, with `1<=N<=8` and each processing time
in `0..=1000`. The input length must be exactly `1+2N`. Invalid, null, or
out-of-profile input returns `-1`. A valid call returns the minimum makespan
as a signed 64-bit integer; ties in Johnson's sort use the original job index
to keep the schedule deterministic. The maximum makespan is 16,000.

The primary oracle applies Johnson's partition-and-sort rule and simulates the
two machines. The independent verifier enumerates every job permutation and
keeps its minimum makespan. The bounded ports use insertion ordering and take
`O(N^2)` time and `O(N)` space; the independent oracle takes `O(N! N)` time,
bounded by `N=8`.

## Distinctness and provenance

[`smith_weighted_completion_time`](../../m/smith_weighted_completion_time/README.md)
orders jobs on one machine to minimize weighted completion sum.
[`assembly_line_scheduling`](../../a/assembly_line_scheduling/README.md) uses
two lines with one station per stage and chooses a route through those
stations. [`optimal_job_scheduling`](../../o/optimal_job_scheduling/README.md)
uses precedence stages with machine-dependent transfer costs. These do not
solve the common-order two-machine flow-shop makespan problem.

Source: [CP-Algorithms, “Scheduling jobs on two machines”](https://cp-algorithms.com/schedules/schedule_two_machines.html),
licensed under CC BY-SA 4.0. This package uses only the high-level Johnson-rule
description; its bounded contract, deterministic tie rule, workload, oracle,
and ports are clean-room work. See [`RIGHTS.md`](RIGHTS.md).

The [`workload`](workload.json) and package-local
[`static inventory checker`](../../check_johnson_two_machine_flow_shop_package.py)
record the fixtures and ten source paths.

## Language ports

| Language | Source |
|---|---|
| C | [`c/j/johnson_two_machine_flow_shop.c`](../../../c/j/johnson_two_machine_flow_shop.c) |
| C3 | [`c3/j/johnson_two_machine_flow_shop.c3`](../../../c3/j/johnson_two_machine_flow_shop.c3) |
| C++ | [`cpp/j/johnson_two_machine_flow_shop.cpp`](../../../cpp/j/johnson_two_machine_flow_shop.cpp) |
| Elisa | [`elisa/j/johnson_two_machine_flow_shop.elisa`](../../../elisa/j/johnson_two_machine_flow_shop.elisa) |
| Mojo | [`mojo/j/johnson_two_machine_flow_shop.mojo`](../../../mojo/j/johnson_two_machine_flow_shop.mojo) |
| Nim | [`nim/j/johnson_two_machine_flow_shop.nim`](../../../nim/j/johnson_two_machine_flow_shop.nim) |
| Odin | [`odin/j/johnson_two_machine_flow_shop.odin`](../../../odin/j/johnson_two_machine_flow_shop.odin) |
| Rust | [`rust/j/johnson_two_machine_flow_shop.rs`](../../../rust/j/johnson_two_machine_flow_shop.rs) |
| V | [`v/j/johnson_two_machine_flow_shop.v`](../../../v/j/johnson_two_machine_flow_shop.v) |
| Zig | [`zig/j/johnson_two_machine_flow_shop.zig`](../../../zig/j/johnson_two_machine_flow_shop.zig) |
