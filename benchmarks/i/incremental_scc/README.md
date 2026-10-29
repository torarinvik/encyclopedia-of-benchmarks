# Incremental strongly connected components

This benchmark maintains directed-graph reachability as arcs arrive one at a time, then counts the current strongly connected components after every insertion.

## Contract

- Input is `[n, m, (u, v)...]`, with vertices numbered from `0` through `n-1` and arcs inserted in record order.
- `n` is 1–8 and `m` is 0–32. Self-loops and parallel arcs are valid distinct insertions. The input length must be exactly `2 + 2m`; endpoints must be in range.
- After each one-based step `s`, count the SCCs and add `s * component_count` to the result. An empty insertion sequence returns `0`. Invalid framing, limits, endpoints, or a null input pointer return `-1`.
- The maintained relation is reflexive transitive closure. Before inserting `u -> v`, the implementation snapshots every current predecessor of `u` and every current successor of `v`; all predecessor/successor pairs become reachable. SCCs are equivalence classes under mutual reachability.

The direct closure update and component recount take `O(n^2)` per insertion, for `O(m*n^2)` total time. The implementation stores an `n` by `n` reachability matrix and the bounded edge list, using `O(n^2 + m)` space. The small limits make the update rule and changing SCC partition visible without substituting a full-graph recomputation in the measured implementation.

[`workload.json`](workload.json) includes empty and maximal sequences, cycle formation, loops, parallel arcs, invalid frames, and a null-pointer probe. [`benchmarks/incremental_scc_oracle.py`](../../incremental_scc_oracle.py) independently rebuilds transitive closure from each prefix. [`benchmarks/verify_incremental_scc.py`](../../verify_incremental_scc.py) is a static workload and source-path checker.

## Provenance

- [Library Checker](https://judge.yosupo.jp/) lists “Strongly Connected Components (Incremental)” as the problem taxonomy for the operation.
- King and Sagert, [“A Fully Dynamic Algorithm for Maintaining the Transitive Closure”](https://doi.org/10.1006/jcss.2002.1883), describe dynamic maintenance of the transitive-closure adjacency matrix.
- Schwentick, Vortmeier, and Zeume, [“Sketches of Dynamic Complexity”](https://sigmodrecord.org/2020/09/04/sketches-of-dynamic-complexity/), presents the single-edge insertion update rule: new reachability is old reachability plus the Cartesian product of predecessors of the tail and successors of the head.

All nine implementations are independent ports for the shared `i64_array_scalar` ABI in `c/i`, `c3/i`, `cpp/i`, `elisa/i`, `nim/i`, `odin/i`, `rust/i`, `v/i`, and `zig/i`.
