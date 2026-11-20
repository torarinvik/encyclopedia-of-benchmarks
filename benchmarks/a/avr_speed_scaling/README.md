# Average Rate (AVR) speed scaling

AVR sets processor speed to the sum of each active job's average rate,
`work/(deadline-release)`, on that job's window `[release,deadline)`. The
resulting speed profile is scheduled by earliest deadline first (EDF), with
original job order breaking deadline ties. The package reports both the
piecewise-constant speed profile and the exact EDF job completion times.

This is distinct from local [`yds_speed_scaling`](../yds_speed_scaling/README.md),
which uses the offline Yao–Demers–Shenker maximum-density interval recurrence
to construct a minimum-energy schedule. AVR is an online policy: each job's
rate contribution depends only on its own work and feasibility window.

## Contract

Input is `[job_count,(release,deadline,work)*]`, with `1<=job_count<=8`, integer
times in `0..8`, `release<deadline`, and work in `1..8`. AVR densities are
represented exactly using the common scale `840=lcm(1,...,8)`.

Output is a little-endian signed-i64 array:
`[segment_count,energy_num,energy_den,(start,end,speed_num,speed_den)*,(finish_num,finish_den)*]`.
Speed segments are positive, sorted, and maximal: adjacent intervals with the
same reduced speed are merged. Completion fractions are in original job
order. Energy is the reduced exact integral of `speed^3` over time. There are
at most 15 segments and 79 output values (632 bytes). Invalid input returns
`-1`; null output or insufficient capacity returns `-2` without writing.

The AVR speed rule is described in Bansal, Bunde, Chan, and Pruhs, [Average
Rate Speed Scaling](https://doi.org/10.1007/s00453-009-9379-z), and the
algorithm is listed as an uncovered online policy in the 2016 [Encyclopedia
of Algorithms speed-scaling chapter](https://doi.org/10.1007/978-1-4939-2864-4_390).
Only algorithm descriptions were consulted. The bounded contract, workload,
references, and ports are independently authored.

| Language | Port |
|---|---|
| C | [c/a/avr_speed_scaling.c](../../../c/a/avr_speed_scaling.c) |
| C3 | [c3/a/avr_speed_scaling.c3](../../../c3/a/avr_speed_scaling.c3) |
| C++ | [cpp/a/avr_speed_scaling.cpp](../../../cpp/a/avr_speed_scaling.cpp) |
| Elisa | [elisa/a/avr_speed_scaling.elisa](../../../elisa/a/avr_speed_scaling.elisa) |
| Mojo | [mojo/a/avr_speed_scaling.mojo](../../../mojo/a/avr_speed_scaling.mojo) |
| Nim | [nim/a/avr_speed_scaling.nim](../../../nim/a/avr_speed_scaling.nim) |
| Odin | [odin/a/avr_speed_scaling.odin](../../../odin/a/avr_speed_scaling.odin) |
| Rust | [rust/a/avr_speed_scaling.rs](../../../rust/a/avr_speed_scaling.rs) |
| V | [v/a/avr_speed_scaling.v](../../../v/a/avr_speed_scaling.v) |
| Zig | [zig/a/avr_speed_scaling.zig](../../../zig/a/avr_speed_scaling.zig) |
