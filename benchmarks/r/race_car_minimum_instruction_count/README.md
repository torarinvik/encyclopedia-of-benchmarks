# Race-car minimum instruction count

This bounded scalar profile finds the shortest command count that moves a
one-dimensional car from `(position=0,speed=+1)` to a requested nonnegative
integer position. An accelerate command adds the current signed speed to the
position and doubles the speed. A reverse command leaves position unchanged
and resets speed to `-1` when speed was positive, or `+1` otherwise.

## Contract

The ABI is `i64_array_scalar`; the package and exported symbol are
`race_car_minimum_instruction_count`. Input is exactly `[target]` with
`0 <= target <= 127`. Target zero returns zero. All valid targets are
reachable. Null input, a missing or extra word, or an out-of-range target
returns `-1`.

The native primary uses a fixed 128-element i32 table, so declared workspace
is 512 bytes. The maximum result is at most 379: from the reset state, one
accelerate command reaches position one, and each further one-unit advance
can use two reverse commands followed by accelerate, for a valid route of
`1 + 3*(target-1)` commands. This bound and every recurrence cost fit i32 and
the signed-i64 scalar ABI.

## Algorithms and distinction

The primary dynamic program fills positions in increasing order. A run of
`k` accelerations reaches `2^k-1`. For a target between two such positions,
the recurrence compares a full overshoot followed by a reverse with every
shorter run to the lower milestone, a reverse, a partial backward run, and a
second reverse. With `k=bit_length(t)`, `U=2^k-1`, and `L=2^(k-1)-1`, the
non-milestone recurrence is
`D(t)=min(k+1+D(U-t), min_{0<=j<k-1}(k+j+1+D(t-(L-(2^j-1)))))`.
Each remaining distance is smaller than `t`, so the table is already
available. The [Scale Engineer Race Car analysis](https://scaleengineer.com/dsa/problems/race-car)
describes this run-length decomposition.

The independent reference performs breadth-first search over exact
`(position,speed)` states and returns when it first reaches the target. It
uses the state transitions directly and does not use the distance recurrence.
It applies no coordinate or speed cutoff; every bounded target has a finite
route under the stated transitions, so the first-target BFS terminates.

This method differs from [`minimum_refueling_stops_heap`](../../m/minimum_refueling_stops_heap/README.md),
which chooses fuel stations on a one-way route, and [`gas_station`](../../g/gas_station/README.md),
which checks circular-route feasibility. Local graph shortest-path packages
traverse fixed graph edges; this profile minimizes a command sequence over a
speed-changing integer state.

## Sources and rights

The public [LeetCode 818 title](https://leetcode.com/problems/race-car/) was
used only to discover the candidate. The recurrence reference above supports
the general method; the benchmark contract, workload, references, ports, and
prose are independently authored. No task text, code, examples, tests, or
submissions are copied. See [`RIGHTS.md`](RIGHTS.md).

[`workload.json`](workload.json) contains repository-created target values
and hand-derived scalar results. The static workload and inventory helpers
are included but were not run. The package is registered in the shared scalar
runner and verifier, the root catalog, and the expansion coverage ledger.

## Native ports

| Language | Source |
| --- | --- |
| C | [`c/r/race_car_minimum_instruction_count.c`](../../../c/r/race_car_minimum_instruction_count.c) |
| C3 | [`c3/r/race_car_minimum_instruction_count.c3`](../../../c3/race_car_minimum_instruction_count.c3) |
| C++ | [`cpp/r/race_car_minimum_instruction_count.cpp`](../../../cpp/r/race_car_minimum_instruction_count.cpp) |
| Elisa | [`elisa/r/race_car_minimum_instruction_count.elisa`](../../../elisa/r/race_car_minimum_instruction_count.elisa) |
| Mojo | [`mojo/r/race_car_minimum_instruction_count.mojo`](../../../mojo/r/race_car_minimum_instruction_count.mojo) |
| Nim | [`nim/r/race_car_minimum_instruction_count.nim`](../../../nim/r/race_car_minimum_instruction_count.nim) |
| Odin | [`odin/r/race_car_minimum_instruction_count.odin`](../../../odin/r/race_car_minimum_instruction_count.odin) |
| Rust | [`rust/r/race_car_minimum_instruction_count.rs`](../../../rust/r/race_car_minimum_instruction_count.rs) |
| V | [`v/r/race_car_minimum_instruction_count.v`](../../../v/r/race_car_minimum_instruction_count.v) |
| Zig | [`zig/r/race_car_minimum_instruction_count.zig`](../../../zig/r/race_car_minimum_instruction_count.zig) |
