# Vector scheduling by explicit randomized assignment

The source chapter describes a randomized algorithm that assigns each job
uniformly to one of the identical machines. This package fixes the random
outcome as part of the input, so each fixture is deterministic while preserving
the source algorithm's assignment and load calculation.

Input is `[n,m,d, machine_choice[n], job_vectors[n*d]]`. There are up to 16
jobs, 8 machines and 4 dimensions. Each vector coordinate is an integer from
0 to 1000 representing a common fixed-point scale of 1/1000. A choice is a
zero-based machine ID supplied for that job. The machine load in each dimension
is the sum of its assigned coordinates; makespan is the maximum coordinate
load across all machines. Output is `[m,d,makespan,(machine-major loads)...]`
as little-endian signed i64 values, at most 280 bytes. Invalid input returns
`-1`; null output or insufficient capacity returns `-2` without writing.

This is the chapter's uniform-random assignment algorithm conditioned on an
explicit draw vector. It does not claim to reproduce a probability estimate or
the chapter's approximation schemes. No random generator is included.

Source: “Vector Scheduling Problems,” *Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_504`](https://doi.org/10.1007/978-1-4939-2864-4_504).
The implementation and documentation are clean-room; no book text or source
code was copied.

## Ports

| Language | Port |
|---|---|
| C | `c/v/vector_scheduling.c` |
| C3 | `c3/v/vector_scheduling.c3` |
| C++ | `cpp/v/vector_scheduling.cpp` |
| Elisa | `elisa/v/vector_scheduling.elisa` |
| Nim | `nim/v/vector_scheduling.nim` |
| Odin | `odin/v/vector_scheduling.odin` |
| Rust | `rust/v/vector_scheduling.rs` |
| V | `v/v/vector_scheduling.v` |
| Zig | `zig/v/vector_scheduling.zig` |

Primary exact-output oracle: `benchmarks/vector_scheduling_oracle.py`.
Independent verifier oracle: `benchmarks/vector_scheduling_verifier_oracle.py`.
