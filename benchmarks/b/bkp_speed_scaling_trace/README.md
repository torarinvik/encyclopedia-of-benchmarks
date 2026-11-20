# BKP online speed-scaling trace

This bounded profile evaluates the Bansal–Kimbrel–Pruhs (BKP) rule for
choosing processor speed at supplied observation times. It reports the speed
selected by the BKP window formula only. It does not simulate EDF dispatch,
completion times, schedule feasibility, energy, or a competitive guarantee.

## Input and output

Input is a signed-i64 array:

`[job_count,sample_count,(release,deadline,work)*job_count,(time,unfinished_mask)*sample_count]`

There are 1–4 jobs, 1–8 samples, integer times in `0..8`, and work amounts in
`1..8`. Every job has `release < deadline`. A sample's unfinished mask has no
bits outside the job range and may mark only jobs released by that sample.
Samples may repeat and need not be sorted. An empty unfinished mask means the
processor is idle, so its speed is `0/1`.

For a nonempty mask at time `t`, the profile evaluates the BKP rule using the
original work of all jobs released by `t`. It considers future endpoints
`t2 > t` at each released job's deadline and at each release-boundary crossing
`t2 = (e*t-release)/(e-1)` for releases strictly before `t`. For each endpoint,
it sums work for jobs whose release is at least `t1 = e*t-(e-1)*t2` and whose
deadline is at most `t2`, then takes the maximum of `work/(t2-t)`. Candidate
ties produce the same reported scalar and need no tie rule.

To keep all ports exact and avoid floating-point variation, this profile fixes
`e` to the explicit rational `271828/100000`. Boundary comparisons and speed
selection use exact integer arithmetic; each output fraction is reduced with a
positive denominator.

Output is little-endian signed-i64 data:

`[sample_count,(speed_numerator,speed_denominator)*sample_count]`

There are at most 17 values (136 bytes). Invalid input returns `-1`. A null
output pointer or insufficient capacity returns `-2` without writing.

The primary reference uses integer cross-products over the source's critical
endpoints. The independent reference uses exact rational endpoint sets and
direct interval membership tests.

## Provenance

The rule is attributed to Bansal, Kimbrel, and Pruhs, [“Speed Scaling to Manage
Energy and Temperature,” *Journal of the ACM* 54(1), Article 3
(2007)](https://doi.org/10.1145/1206035.1206038), and is listed in Pruhs,
[“Speed Scaling,” *Encyclopedia of Algorithms*, DOI
10.1007/978-1-4939-2864-4_390](https://doi.org/10.1007/978-1-4939-2864-4_390).
Only algorithmic ideas and bibliographic details are used.

## Ports

| Language | Port |
|---|---|
| C | [c/b/bkp_speed_scaling_trace.c](../../../c/b/bkp_speed_scaling_trace.c) |
| C3 | [c3/b/bkp_speed_scaling_trace.c3](../../../c3/b/bkp_speed_scaling_trace.c3) |
| C++ | [cpp/b/bkp_speed_scaling_trace.cpp](../../../cpp/b/bkp_speed_scaling_trace.cpp) |
| Elisa | [elisa/b/bkp_speed_scaling_trace.elisa](../../../elisa/b/bkp_speed_scaling_trace.elisa) |
| Mojo | [mojo/b/bkp_speed_scaling_trace.mojo](../../../mojo/b/bkp_speed_scaling_trace.mojo) |
| Nim | [nim/b/bkp_speed_scaling_trace.nim](../../../nim/b/bkp_speed_scaling_trace.nim) |
| Odin | [odin/b/bkp_speed_scaling_trace.odin](../../../odin/b/bkp_speed_scaling_trace.odin) |
| Rust | [rust/b/bkp_speed_scaling_trace.rs](../../../rust/b/bkp_speed_scaling_trace.rs) |
| V | [v/b/bkp_speed_scaling_trace.v](../../../v/b/bkp_speed_scaling_trace.v) |
| Zig | [zig/b/bkp_speed_scaling_trace.zig](../../../zig/b/bkp_speed_scaling_trace.zig) |
