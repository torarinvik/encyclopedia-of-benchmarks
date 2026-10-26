# Pannotia local-minimum-priority maximal independent set

This package captures Pannotia's `mis1`/`mis2`/`mis3` rounds as a bounded
maximal-independent-set operation. Each round marks every active vertex whose
priority is strictly lower than every active neighbor, then deactivates those
vertices and their active neighbors. It repeats until all vertices are either
selected or excluded. With distinct priorities, this yields the same result as
processing vertices once in increasing priority order.

## Contract

- Exported symbol: `pannotia_local_minimum_mis`; ABI: `i64_array_bytes_output`.
- Input is `[n, m, p0, ..., p(n-1), (u, v)...]`, with `1 <= n <= 16` and
  `0 <= m <= 64`. Each undirected simple edge appears once with `u < v`.
  Self-loops, repeated or reversed edges, and endpoints outside `[0,n)` are
  invalid. Priorities are distinct integers in `[0,99,999,998]`; the caller
  supplies the ordering explicitly.
- Output is one little-endian signed i64 per vertex: `2` if selected and `0`
  otherwise. Success returns `8*n`; malformed input returns `-1`; null or
  insufficient output returns `-2` without writing.
- The Pannotia launcher calls `srand(7)` and assigns `rand()/(float)RAND_MAX`
  priorities. Because C-library `rand()` sequences differ, this portable
  profile accepts the seeded ordering as explicit priorities. Only the strict
  comparisons affect the local-minimum rounds.
- The package oracle performs serial increasing-priority greedy selection;
  the suite verifier independently simulates simultaneous local-minimum
  rounds. The pinned GBBS `RandomGreedy` MIS has the same priority-DAG
  algorithm and maps to this single package rather than adding duplicate ports.
  GBBS's `spec_for` MIS is a separate ID-ordered speculative strategy.

## Source and rights

The reference kernels are [`mis.cpp`](https://github.com/pannotia/pannotia/blob/16c1f0964516babc13a60f21c74644e28f3651b1/graph_app/mis/mis.cpp)
and [`kernel.cl`](https://github.com/pannotia/pannotia/blob/16c1f0964516babc13a60f21c74644e28f3651b1/graph_app/mis/kernel/kernel.cl)
at Pannotia commit `16c1f0964516babc13a60f21c74644e28f3651b1`. The repository's
full license is retained in [`LICENSE.txt`](LICENSE.txt). These are clean-room
ports of the published operation.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/pannotia_local_minimum_mis.c`](../../../c/p/pannotia_local_minimum_mis.c) |
| C3 | [`c3/p/pannotia_local_minimum_mis.c3`](../../../c3/p/pannotia_local_minimum_mis.c3) |
| C++ | [`cpp/p/pannotia_local_minimum_mis.cpp`](../../../cpp/p/pannotia_local_minimum_mis.cpp) |
| Elisa | [`elisa/p/pannotia_local_minimum_mis.elisa`](../../../elisa/p/pannotia_local_minimum_mis.elisa) |
| Nim | [`nim/p/pannotia_local_minimum_mis.nim`](../../../nim/p/pannotia_local_minimum_mis.nim) |
| Odin | [`odin/p/pannotia_local_minimum_mis.odin`](../../../odin/p/pannotia_local_minimum_mis.odin) |
| Rust | [`rust/p/pannotia_local_minimum_mis.rs`](../../../rust/p/pannotia_local_minimum_mis.rs) |
| V | [`v/p/pannotia_local_minimum_mis.v`](../../../v/p/pannotia_local_minimum_mis.v) |
| Zig | [`zig/p/pannotia_local_minimum_mis.zig`](../../../zig/p/pannotia_local_minimum_mis.zig) |

Workload: [`workload.json`](workload.json). Package oracle:
[`pannotia_local_minimum_mis_oracle.py`](../../pannotia_local_minimum_mis_oracle.py).
