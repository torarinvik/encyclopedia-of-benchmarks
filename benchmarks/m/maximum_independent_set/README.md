# Maximum Independent Set

This bounded exact graph benchmark returns the cardinality of a maximum
independent vertex set in a simple undirected graph. Each implementation stores
neighbor sets as bit masks, branches on a remaining vertex of maximum induced
degree, and explores including that vertex before excluding it. A greedy clique
cover of the remaining graph supplies a safe upper bound because an independent
set can contain at most one vertex from each clique.

## Contract

Input is `[n,m,u0,v0,...]`: `0 <= n <= 22`, followed by `m` distinct undirected
edges with `0 <= m <= n(n-1)/2` and endpoints in `[0,n)`. Loops, duplicate
edges, truncated frames, and trailing words return `-1`. A valid graph returns
the maximum independent-set cardinality in `[0,n]`.

The exact search takes `O(2^n poly(n))` time in the worst case and `O(n)`
recursion depth, in addition to the `O(n^2)` input adjacency representation.
The bound improves pruning on dense subgraphs while preserving exactness.
The input is capped at 464 signed 64-bit words; 465 words are accepted for
explicit trailing-input rejection. The primary oracle uses the same bounded
branch-and-bound idea; a separate exhaustive-subset oracle checks the fixtures.

## Provenance and distinctness

The candidate is covered by [Exact Algorithms for Maximum Independent Set,
Encyclopedia of Algorithms, chapter 514](https://doi.org/10.1007/978-1-4939-2864-4_514).
The existing list-ranking package selects independent positions on paths, while
the local clique packages enumerate maximal or all cliques; none solves the
maximum-cardinality independent-set optimization problem. Implementations and
fixtures are independently authored from the algorithm description.

See [`workload.json`](workload.json), the [primary oracle](../maximum_independent_set_oracle.py),
the [independent verifier oracle](../maximum_independent_set_verifier_oracle.py),
and [`RIGHTS.md`](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [`c/m/maximum_independent_set.c`](../../../c/m/maximum_independent_set.c) |
| C3 | [`c3/m/maximum_independent_set.c3`](../../../c3/m/maximum_independent_set.c3) |
| C++ | [`cpp/m/maximum_independent_set.cpp`](../../../cpp/m/maximum_independent_set.cpp) |
| Elisa | [`elisa/m/maximum_independent_set.elisa`](../../../elisa/m/maximum_independent_set.elisa) |
| Mojo | [`mojo/m/maximum_independent_set.mojo`](../../../mojo/m/maximum_independent_set.mojo) |
| Nim | [`nim/m/maximum_independent_set.nim`](../../../nim/m/maximum_independent_set.nim) |
| Odin | [`odin/m/maximum_independent_set.odin`](../../../odin/m/maximum_independent_set.odin) |
| Rust | [`rust/m/maximum_independent_set.rs`](../../../rust/m/maximum_independent_set.rs) |
| V | [`v/m/maximum_independent_set.v`](../../../v/m/maximum_independent_set.v) |
| Zig | [`zig/m/maximum_independent_set.zig`](../../../zig/m/maximum_independent_set.zig) |
