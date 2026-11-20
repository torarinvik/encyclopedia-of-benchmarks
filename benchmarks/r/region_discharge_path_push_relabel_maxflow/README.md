# Region-discharge path-augmentation max flow

This package benchmarks a bounded, deterministic sequential implementation of
Shekhovtsov and Hlaváč's sequential Augmented Path Region Discharge algorithm
(S-ARD). It initializes one global preflow and residual network, then visits a
fixed partition of the nonterminal vertices region by region. Inside each
region, it sends excess to the sink first and then to eligible boundary vertices
in increasing region-distance label stages. A region relabel follows each
discharge. The single-call profile is sequential and in-memory; it does not
implement distributed storage, streaming I/O, or the paper's parallel P-ARD
schedule.

## Contract

- ABI: `i64_array_scalar`, symbol `region_discharge_path_push_relabel_maxflow`.
- Input: `[N,M,K,source,sink,region[N],(u,v,capacity)*M]`. `N` includes the
  source and sink. `region[source]` and `region[sink]` are `-1`; all other
  vertices use represented region IDs `0..K-1`.
- Bounds: `4<=N<=8`, `1<=M<=12`, and `2<=K<=min(4,N-2)`. Every region must
  contain a nonterminal vertex. The input must have at least one positive
  capacity arc across regions, so the boundary has at least two vertices.
- Arc capacities are 0 through 7. Parallel and antiparallel arcs are allowed
  and summed. Self-loops, arcs entering the source, and arcs leaving the sink
  are invalid. A direct source-to-sink arc is allowed.
- Exact length is `5+N+3*M`; maximum valid and parseable lengths are 49 and 50
  words. Null input returns -1 at declared lengths 0 and 50. Invalid input
  returns -1.
- The maximum result is 84, bounded by the 12 source-outgoing arc records.

## Sequential S-ARD profile

The set `B` contains nonterminal endpoints of positive inter-region arcs, and
`d∞=|B|`. The initial preflow saturates all source-outgoing arcs; labels start
at zero except the source label `d∞`. Sweeps visit region IDs in ascending
order until no positive-excess vertex has a label below `d∞`.

For region `R`, `B_R` is its set of external nonterminal neighbors. The local
region network uses the current global residual capacities on `R∪{s,t}` and
the two directions between `R` and `B_R`; incoming boundary-to-region
capacities are zeroed. Each regional path augmentation updates the shared
global residual and excess state. For stage `k=0..d∞`,

`T_k = {sink} ∪ {v∈B_R | d(v)<k}`.

The implementation repeatedly selects a shortest residual path from a
positive-excess vertex in `R` to `T_k`, with ascending vertex scans for ties,
and pushes the smaller of the starting excess and path bottleneck. After all
stages, each vertex in `R` receives the smallest stage whose target set it can
reach in the updated local residual network, or `d∞` if no such target is
reachable. Boundary labels remain fixed during that discharge.

The paper proves S-ARD terminates in at most `2|B|²+1` sweeps. The package uses
that bound as its fixed sweep limit. With at most `K` regions and `|B|+1`
nested-target stages per region, each using breadth-first augmenting paths on
at most `N` vertices and `M` arc records, the bounded profile has a conservative
`O((2|B|²+1) K (|B|+1) N M²)` worst-case path-search bound.

The method differs from global push-relabel because it uses augmenting paths
to nested sink/boundary targets and region-distance labels. It differs from
bottom-up block merging because every discharge updates one shared residual
network and preflow; it does not merge independently solved components.

## References and rights

The algorithm is described in Shekhovtsov and Hlaváč, [“A Distributed
Mincut/Maxflow Algorithm Combining Path Augmentation and
Push-Relabel”](https://cmp.felk.cvut.cz/~shekhovt/publications/shekhovtsov-11-mixed_maxflow.pdf),
especially §4.1–4.3 and sequential Algorithm 1. The authors' [technical
report](https://cmp.felk.cvut.cz/~shekhovt/publications/shekhovtsov-11-mixed_maxflow-TR.pdf)
gives additional S-ARD details, Statement 9, and Theorem 3's sweep bound. The
[arXiv record](https://arxiv.org/abs/1109.1146) identifies the work and authors.
Only the algorithm descriptions were used; no source code or benchmark instances
were copied. See [RIGHTS](RIGHTS.md), [workload](workload.json), and the [static
package inventory](../../check_region_discharge_path_push_relabel_maxflow_package.py).

| Language | Port |
|---|---|
| C | [c/r/region_discharge_path_push_relabel_maxflow.c](../../../c/r/region_discharge_path_push_relabel_maxflow.c) |
| C3 | [c3/r/region_discharge_path_push_relabel_maxflow.c3](../../../c3/r/region_discharge_path_push_relabel_maxflow.c3) |
| C++ | [cpp/r/region_discharge_path_push_relabel_maxflow.cpp](../../../cpp/r/region_discharge_path_push_relabel_maxflow.cpp) |
| Elisa | [elisa/r/region_discharge_path_push_relabel_maxflow.elisa](../../../elisa/r/region_discharge_path_push_relabel_maxflow.elisa) |
| Mojo | [mojo/r/region_discharge_path_push_relabel_maxflow.mojo](../../../mojo/r/region_discharge_path_push_relabel_maxflow.mojo) |
| Nim | [nim/r/region_discharge_path_push_relabel_maxflow.nim](../../../nim/r/region_discharge_path_push_relabel_maxflow.nim) |
| Odin | [odin/r/region_discharge_path_push_relabel_maxflow.odin](../../../odin/r/region_discharge_path_push_relabel_maxflow.odin) |
| Rust | [rust/r/region_discharge_path_push_relabel_maxflow.rs](../../../rust/r/region_discharge_path_push_relabel_maxflow.rs) |
| V | [v/r/region_discharge_path_push_relabel_maxflow.v](../../../v/r/region_discharge_path_push_relabel_maxflow.v) |
| Zig | [zig/r/region_discharge_path_push_relabel_maxflow.zig](../../../zig/r/region_discharge_path_push_relabel_maxflow.zig) |
