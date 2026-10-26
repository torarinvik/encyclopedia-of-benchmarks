# Universal sequencing: doubling algorithm

This clean-room profile implements the deterministic Doubling Algorithm summarized in the *Encyclopedia of Algorithms* chapter “Universal Sequencing on an Unreliable Machine,” DOI [`10.1007/978-1-4939-2864-4_543`](https://doi.org/10.1007/978-1-4939-2864-4_543). It computes a fixed job sequence intended to remain within the chapter's factor-4 guarantee across machine speed changes and breakdowns. The benchmark measures construction of that sequence; it does not simulate failures or measure a realized schedule.

## Bounded contract

- ABI: `i64_array_bytes_output`; input is `[n,p0,w0,...,p(n-1),w(n-1)]`, with jobs identified by their input index.
- `1 <= n <= 12`, integer processing times `1..255`, and integer weights `1..32`. The total weight `W` must be a power of two in `1..32`. This restriction preserves the source figure's stated level range `0..floor(log W)` while ensuring the highest knapsack budget includes every job; non-power-of-two totals are rejected rather than silently changing that bound.
- At each level `i=0..log2(W)`, solve the 0/1 knapsack subproblem maximizing total processing time under weight capacity `2^i`. Equal processing totals choose the numerically smallest job-membership bit mask (job 0 is the low bit). For the final sequence, assign each job to the smallest level whose selected set contains it, process levels from largest to smallest, and append IDs in ascending order within a level. This realizes the chapter's `J_i* \ union_{k<i} J_k*` grouping with deterministic ties.
- Output is `[n,job_id_0,...,job_id_(n-1)]` as little-endian signed 64-bit words. The maximum input is 25 words and the fixed output is 104 bytes. Invalid input returns `-1`; null or short output returns `-2` without writes.
- The profile is exact for its integer input domain: each level uses bounded 0/1 dynamic programming, not a heuristic or an FPTAS. The chapter's machine-behavior model and approximation guarantee concern this sequence and are not evaluated by the ABI.

The output is a permutation because the highest level has capacity `W` and positive processing times make its selected set contain all jobs; the per-job lowest containing level assigns each job once. The stable tie choices only select one of the chapter-permitted optimal knapsack subsets and one permitted within-level ordering.

## Provenance and rights

The mathematical algorithm is attributed to Julián Mestre and Nicole Megow, “Universal Sequencing on an Unreliable Machine,” *Encyclopedia of Algorithms*, DOI `10.1007/978-1-4939-2864-4_543`. The chapter and its summarized original papers remain copyrighted. This package contains no copied source code, prose, or figures; the ports are clean-room implementations of the stated knapsack-and-doubling rule. No upstream code license is asserted. See [`RIGHTS.md`](RIGHTS.md).

## Package files

- [`workload.json`](workload.json)
- [primary dynamic-programming oracle](../../universal_sequencing_doubling_oracle.py)
- [independent exhaustive-subset verifier oracle](../../universal_sequencing_doubling_verifier_oracle.py)

| Language | Port |
|---|---|
| C | [`c/t/universal_sequencing_doubling.c`](../../../c/t/universal_sequencing_doubling.c) |
| C3 | [`c3/t/universal_sequencing_doubling.c3`](../../../c3/t/universal_sequencing_doubling.c3) |
| C++ | [`cpp/t/universal_sequencing_doubling.cpp`](../../../cpp/t/universal_sequencing_doubling.cpp) |
| Elisa | [`elisa/t/universal_sequencing_doubling.elisa`](../../../elisa/t/universal_sequencing_doubling.elisa) |
| Nim | [`nim/t/universal_sequencing_doubling.nim`](../../../nim/t/universal_sequencing_doubling.nim) |
| Odin | [`odin/t/universal_sequencing_doubling.odin`](../../../odin/t/universal_sequencing_doubling.odin) |
| Rust | [`rust/t/universal_sequencing_doubling.rs`](../../../rust/t/universal_sequencing_doubling.rs) |
| V | [`v/t/universal_sequencing_doubling.v`](../../../v/t/universal_sequencing_doubling.v) |
| Zig | [`zig/t/universal_sequencing_doubling.zig`](../../../zig/t/universal_sequencing_doubling.zig) |
