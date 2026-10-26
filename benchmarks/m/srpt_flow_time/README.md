# SRPT flow time on identical machines

This package implements the preemptive shortest-remaining-processing-time
(SRPT) policy on one to four identical machines. At each integer time slot,
it runs up to `m` released unfinished jobs with the least remaining work; ties
are resolved by lower job ID. If none is ready, time advances to the next
release. The result is total flow time followed by each job's completion time.

## Contract

Input is `[m,n,(release,processing)[n]]`, with `1<=m<=4`, `1<=n<=12`, release
times in `[0,50]`, and processing times in `[1,10]`. Times are integral and
preemption decisions occur at each integer boundary. Output is
`[total_flow_time,completion_time_by_job_id...]`, little-endian signed 64-bit
words. The input maximum is 26 words; output maximum is 104 bytes. Malformed
input returns `-1`; null or insufficient output returns `-2` without writes.
For `m=1`, this is the single-machine SRPT policy that is optimal for total
flow time. For multiple machines, the chapter identifies SRPT as a
preemptive policy with a bound depending on the largest-to-smallest processing
time ratio; this profile does not assert an optimality guarantee there.

## Source and scope

The single-machine behavior is based on “Minimum Flow Time,” DOI
[`10.1007/978-1-4939-2864-4_235`](https://doi.org/10.1007/978-1-4939-2864-4_235).
The multi-machine policy is from “Flow Time Minimization,” DOI
[`10.1007/978-1-4939-2864-4_146`](https://doi.org/10.1007/978-1-4939-2864-4_146).
Both describe SRPT selection; the generalized profile avoids a second package
for the same policy. This bounded discrete-time implementation contains no
copied book text or code. See [`RIGHTS.md`](RIGHTS.md).

The primary oracle is
[`srpt_flow_time_oracle.py`](../../srpt_flow_time_oracle.py); the independent
event-driven verifier is
[`srpt_flow_time_verifier_oracle.py`](../../srpt_flow_time_verifier_oracle.py).
Fixtures are in [`workload.json`](workload.json).

| Language | Port |
|---|---|
| C | `c/m/srpt_flow_time.c` |
| C3 | `c3/m/srpt_flow_time.c3` |
| C++ | `cpp/m/srpt_flow_time.cpp` |
| Elisa | `elisa/m/srpt_flow_time.elisa` |
| Nim | `nim/m/srpt_flow_time.nim` |
| Odin | `odin/m/srpt_flow_time.odin` |
| Rust | `rust/m/srpt_flow_time.rs` |
| V | `v/m/srpt_flow_time.v` |
| Zig | `zig/m/srpt_flow_time.zig` |
