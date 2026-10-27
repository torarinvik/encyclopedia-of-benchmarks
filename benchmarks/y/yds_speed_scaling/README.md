# YDS speed scaling

This bounded profile implements the YDS offline minimum-energy speed-scaling
recurrence for jobs with release times, deadlines, and work requirements. The
power function is fixed to `P(s)=s³`. All job times and work amounts are
integers; the algorithm's speeds and energy are represented exactly as
rationals.

Input is `[job_count,(release,deadline,work)*]`, with one to four jobs,
release/deadline times in `0..8`, `release < deadline`, and work in `1..8`.
At each iteration, consider intervals whose left endpoint is a remaining job's
release and whose right endpoint is a remaining job's deadline. The interval
density is the sum of work for jobs whose complete windows lie inside the
interval divided by its duration. Select maximum density, breaking ties by
smallest left endpoint and then smallest right endpoint. Assign its contained
jobs at constant speed `W/(b-a)` in earliest-deadline order, using job ID for
deadline ties; remove those jobs and compress the chosen time interval out of
the remaining job windows. The profile's output is the critical-interval
decomposition on each progressively compressed time axis, rather than a
floating-point expanded timeline.

Output is little-endian signed-i64 data:
`[stage_count,energy_numerator,energy_denominator,(a,b,W,job_mask)*]`.
Each stage's exact speed is `W/(b-a)`. `job_mask` has bit `j` set for each
original job assigned in that stage; their execution order is recovered by
sorting those jobs by their current compressed deadline and then ID. Total
cubic-power energy is the reduced rational sum
`Σ W³/(b-a)²`. The maximum output is 152 bytes. Invalid input returns `-1`;
null output or insufficient capacity returns `-2` without writing.

Source: “Speed Scaling,” Kirk Pruhs, *Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_390`](https://doi.org/10.1007/978-1-4939-2864-4_390).
This clean-room bounded trace does not copy book prose or source code. It is
distinct from SRPT's total-flow-time objective and does not implement the
chapter's other online policies (OA, AVR, or BKP).

Primary oracle: `benchmarks/yds_speed_scaling_oracle.py`.
Independent verifier: `benchmarks/yds_speed_scaling_verifier_oracle.py`.

| Language | Port |
|---|---|
| C | `c/y/yds_speed_scaling.c` |
| C3 | `c3/y/yds_speed_scaling.c3` |
| C++ | `cpp/y/yds_speed_scaling.cpp` |
| Elisa | `elisa/y/yds_speed_scaling.elisa` |
| Nim | `nim/y/yds_speed_scaling.nim` |
| Odin | `odin/y/yds_speed_scaling.odin` |
| Rust | `rust/y/yds_speed_scaling.rs` |
| V | `v/y/yds_speed_scaling.v` |
| Zig | `zig/y/yds_speed_scaling.zig` |
