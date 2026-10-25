# Ptrdist Kernighan–Lin graph partitioning

This package ports the default, unweighted `KS_MODE`-off path from Ptrdist's
`ks` benchmark. It performs balanced two-way netlist partitioning: greedily
select one pair of opposite-side modules at a time, record every paired-swap
gain, commit the best positive cumulative prefix, and repeat until a pass has
no positive gain. This is distinct from local partition/subset-sum packages,
which decide whether a set can reach a target; it optimizes a graph/netlist cut.

## Contract

- ABI: `i64_array_scalar`, symbol `ptrdist_ks`.
- Input: `[module_count, net_count, degree_0, member_0..., ...]`. Module
  identifiers are zero-based. Each net is an unweighted hyperedge with 2
  through `module_count` distinct members. The module count is even and from 2
  through 8; net count is from 0 through 16.
- Initial partition is the source's balanced split: modules `[0,n/2)` start in
  group A and `[n/2,n)` in group B.
- Pair selection scans the current A list then current B list and keeps the
  first pair on equal gain, as the source does. A net contributes one unit for
  every cross-partition module pair. The gain for a trial pair is the current
  edge-cut count minus the count after that pair is swapped.
- Each pass records the greedy swaps and selects the first prefix with maximum
  cumulative gain. A prefix is committed only when its gain is positive. The
  source's swap-list order is retained between accepted passes.
- Result fields are packed as
  `group_a_mask + (edge_cut_pairs << 8) + (cut_net_count << 17) + (accepted_passes << 22)`.
  Bit `i` of the low byte identifies module `i` in group A. `edge_cut_pairs`
  counts cross-side pairs inside every net; `cut_net_count` counts nets with
  members on both sides. The bounds keep every field disjoint in a signed
  64-bit result.
- Invalid framing, odd/out-of-range module counts, invalid degrees, repeated
  members, or out-of-range identifiers return `-1`.

The Python [oracle](../../ptrdist_ks_oracle.py) recomputes every candidate
partition's cut directly rather than using the source's incremental D-value
updates. `generated_inputs()` supplies small verifier inputs across zero-net,
pair-edge, overlapping-net, and six-module cases.

## Provenance and rights

The pinned launcher compiles `KS-1.c` and `KS-2.c` and runs `KL-4.in`. The
source headers identify Todd M. Austin and date the program February 25, 1993,
and describe modified Kernighan–Lin/Kernighan–Schweikert graph partitioning.
The pinned source includes no explicit license or redistribution grant. The
ports and oracle are independently written from the algorithmic behavior; no
upstream implementation text or benchmark input file is copied. The workload
below uses small hand-described inputs, not the source's large netlist.

- [`KS-1.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Ptrdist/ks/KS-1.c)
- [`KS-2.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Ptrdist/ks/KS-2.c)
- [`KS.h`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Ptrdist/ks/KS.h)
- [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Ptrdist/ks/info.sh)

## Language ports

| Language | Source |
| --- | --- |
| C | [c/k/ptrdist_ks.c](../../../c/k/ptrdist_ks.c) |
| C3 | [c3/k/ptrdist_ks.c3](../../../c3/k/ptrdist_ks.c3) |
| C++ | [cpp/k/ptrdist_ks.cpp](../../../cpp/k/ptrdist_ks.cpp) |
| Elisa | [elisa/k/ptrdist_ks.elisa](../../../elisa/k/ptrdist_ks.elisa) |
| Nim | [nim/k/ptrdist_ks.nim](../../../nim/k/ptrdist_ks.nim) |
| Odin | [odin/k/ptrdist_ks.odin](../../../odin/k/ptrdist_ks.odin) |
| Rust | [rust/k/ptrdist_ks.rs](../../../rust/k/ptrdist_ks.rs) |
| V | [v/k/ptrdist_ks.v](../../../v/k/ptrdist_ks.v) |
| Zig | [zig/k/ptrdist_ks.zig](../../../zig/k/ptrdist_ks.zig) |
