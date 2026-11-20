# Fixed-point HITS hub-authority ranking

This profile runs Kleinberg's mutually reinforcing hub and authority updates
on a bounded directed graph. Hubs accumulate the authority scores of their
out-neighbors; authorities accumulate the hub scores of their in-neighbors.
The local PageRank profile follows a different transition-and-damping process,
so it does not duplicate HITS.

## Contract

The exported scalar symbol is `hits_fixed_point`. Input is
`[N,M,K,(source,target)*M]`, with `1<=N<=16`, `0<=M<=64`, and `0<=K<=32`.
The graph is directed and simple: endpoints are in `[0,N)`, self-loops and
duplicate ordered arcs are invalid. Exact input length is `3+2M`; the maximum
valid and parseable lengths are 131 and 132 i64 values. Invalid input returns
`-1`.

All ports use integer scores with scale `S=1,000,000`. Initial hubs are `S`
and initial authorities are zero. Each iteration computes authority values
from incoming arcs, then hub values from outgoing arcs. After each update,
values are normalized by `floor(raw[i]*S/sum(raw))`; an all-zero raw vector
normalizes to all zeroes. The final result is
`sum((i+1)*(authority[i]+65537*hub[i]))`, using one-based vertex indices.
The fixed-point rule and iteration count are part of the benchmark contract.

The language ports validate duplicate arcs with pairwise scans, so the primary
uses `O(M² + K(N+M))` time and `O(N+M)` space. The independent oracle applies
the same integer recurrence through a dense adjacency matrix, using
`O(M + N² + K N²)` time.

## Provenance and rights

The algorithm is from Jon M. Kleinberg, “Authoritative Sources in a
Hyperlinked Environment,” *Journal of the ACM* 46(5), 1999, pp. 604–632,
DOI [10.1145/324133.324140](https://doi.org/10.1145/324133.324140). This source
is cited for the HITS algorithm idea only. The fixed-point contract, fixtures,
oracles, and language ports are independently authored; no source code or text
is reused. See [`RIGHTS.md`](RIGHTS.md), [`workload.json`](workload.json), the
[edge-list primary oracle](../../hits_fixed_point_oracle.py), the
[dense verifier](../../hits_fixed_point_verifier_oracle.py), and the
[static package checker](../../check_hits_fixed_point_package.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/h/hits_fixed_point.c`](../../../c/h/hits_fixed_point.c) |
| C3 | [`c3/h/hits_fixed_point.c3`](../../../c3/h/hits_fixed_point.c3) |
| C++ | [`cpp/h/hits_fixed_point.cpp`](../../../cpp/h/hits_fixed_point.cpp) |
| Elisa | [`elisa/h/hits_fixed_point.elisa`](../../../elisa/h/hits_fixed_point.elisa) |
| Mojo | [`mojo/h/hits_fixed_point.mojo`](../../../mojo/h/hits_fixed_point.mojo) |
| Nim | [`nim/h/hits_fixed_point.nim`](../../../nim/h/hits_fixed_point.nim) |
| Odin | [`odin/h/hits_fixed_point.odin`](../../../odin/h/hits_fixed_point.odin) |
| Rust | [`rust/h/hits_fixed_point.rs`](../../../rust/h/hits_fixed_point.rs) |
| V | [`v/h/hits_fixed_point.v`](../../../v/h/hits_fixed_point.v) |
| Zig | [`zig/h/hits_fixed_point.zig`](../../../zig/h/hits_fixed_point.zig) |
