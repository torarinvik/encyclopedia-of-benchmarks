# Optimal Available (OA) speed scaling

OA is the online speed-scaling policy that replans at job arrivals. At each
release time, it builds the Yao–Demers–Shenker minimum-energy schedule for the
remaining work of every job released so far, as if no further jobs will arrive.
The processor follows that plan until its next critical-interval boundary or
the next release; at the release it keeps the exact unfinished work and plans
again. Each critical interval runs its jobs by earliest deadline first (EDF).
Equal deadlines use original job ID as the deterministic tie-break.

This differs from the offline [`yds_speed_scaling`](../../y/yds_speed_scaling/README.md),
which plans once with all future jobs known, and from
[`avr_speed_scaling`](../../a/avr_speed_scaling/README.md), whose speed is the sum of
the original average-rate densities. The distinction in this profile is the
arrival-triggered YDS replanning over unfinished, already-released work.

## Contract

Input is `[N,(release,deadline,work)*N]`, where `1<=N<=2`, integer times are in
`0..4`, and integer work is in `1..4`. Every job has `release < deadline`.
The processor has no speed cap, so every valid job set is feasible. Input
length is exactly `1+3N`; the maximum valid and parseable lengths are 7 and 8
signed 64-bit words. Malformed input and null input return `-1`.

Power is `P(s)=s^3`. All schedule rates, remaining work, completion times, and
energy are exact reduced rationals. At each OA event, sort unfinished jobs by
`(deadline,job_id)`. For every prefix ending at job `k`, compute the sum of
remaining work in that prefix divided by `deadline[k]-now`; select the maximum
density, resolving ties by the earliest critical-interval endpoint. Schedule
that prefix at the selected constant speed up to its endpoint by EDF, remove
it, and continue with the remaining jobs on the compressed timeline. Stop
following the plan at the next release and repeat the computation with exact
remaining work. The primary follows this critical-prefix recurrence. The
independent reference selects between the only two feasible schedule forms
for at most two common-release jobs: one full-window constant-rate block, or
an early-deadline block followed by a late-job block.

Output is little-endian signed-i64 data:
`[segment_count,energy_num,energy_den,(start,end,speed_num,speed_den)*,(finish_num,finish_den)*]`.
Only positive-speed segments are emitted; adjacent equal-speed segments are
merged, including across a release when replanning keeps the same rate. Finish
times are in input order. There are at most three speed segments and 19 output
words (152 bytes). Reduced rational fields fit signed 64-bit under these
bounds. Invalid input returns `-1`; null output or insufficient capacity
returns `-2` without writing.

The algorithm description is in Yao, Demers, and Shenker, [“A Scheduling
Model for Reduced CPU Energy,” FOCS 1995, §§3–4](https://doi.org/10.1109/SFCS.1995.492493).
Section 4 defines OA as recomputing an optimal schedule for the arriving job
and the remaining portions of all available jobs; Section 3 gives the
critical-interval optimizer and EDF dispatch. The chapter is Kirk Pruhs,
[“Speed Scaling,” Encyclopedia of Algorithms, DOI
390](https://doi.org/10.1007/978-1-4939-2864-4_390). Only algorithm
descriptions were consulted; the implementation, bounded contract, and
fixtures are clean-room.

| Language | Port |
|---|---|
| C | [`c/o/oa_speed_scaling.c`](../../../c/o/oa_speed_scaling.c) |
| C3 | [`c3/o/oa_speed_scaling.c3`](../../../c3/o/oa_speed_scaling.c3) |
| C++ | [`cpp/o/oa_speed_scaling.cpp`](../../../cpp/o/oa_speed_scaling.cpp) |
| Elisa | [`elisa/o/oa_speed_scaling.elisa`](../../../elisa/o/oa_speed_scaling.elisa) |
| Mojo | [`mojo/o/oa_speed_scaling.mojo`](../../../mojo/o/oa_speed_scaling.mojo) |
| Nim | [`nim/o/oa_speed_scaling.nim`](../../../nim/o/oa_speed_scaling.nim) |
| Odin | [`odin/o/oa_speed_scaling.odin`](../../../odin/o/oa_speed_scaling.odin) |
| Rust | [`rust/o/oa_speed_scaling.rs`](../../../rust/o/oa_speed_scaling.rs) |
| V | [`v/o/oa_speed_scaling.v`](../../../v/o/oa_speed_scaling.v) |
| Zig | [`zig/o/oa_speed_scaling.zig`](../../../zig/o/oa_speed_scaling.zig) |

The Python primary and independent references are
[`primary_oracle.py`](primary_oracle.py) and
[`independent_oracle.py`](independent_oracle.py). The workload is
[`workload.json`](workload.json); static package inventory is checked by
[`verify_workload.py`](verify_workload.py).
