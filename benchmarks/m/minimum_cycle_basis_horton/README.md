# Horton minimum cycle basis

This profile finds the minimum total weight of a cycle basis over
\(\mathbb{F}_2\) for a small connected, simple, undirected graph.

## Contract

The scalar symbol is `minimum_cycle_basis_horton`. Input is
`[N, M, (u, v, weight)*M]` with `3 <= N <= 8`, `N-1 <= M <= 12`, and
`M <= N*(N-1)/2`. Each edge is undirected and encoded with `0 <= u < v < N`;
the edge pairs must be strictly increasing lexicographically. Weights are
integers in `[1,9]`. The graph must be connected. Input length is exactly
`2+3*M`; the maximum valid and parseable lengths are 38 and 39 i64 words.
Invalid or null input returns `-1`.

The result is the minimum sum of edge weights over a basis of the graph's
cycle space over GF(2). A tree has dimension zero and returns 0. A connected
graph's cycle-space dimension is `M-N+1`.

## Algorithm

Horton's candidate-set method constructs one shortest-path tree for each
root. For each root and each non-tree edge `(u,v)`, XOR the edge sets on the
root-to-`u` and root-to-`v` tree paths with the edge itself. The resulting
cycle masks form a polynomial-sized candidate set that contains a minimum
cycle basis. Sort by `(cycle weight, edge mask)` and greedily accept a mask
when it increases GF(2) rank, using bitwise elimination, until the cycle-space
dimension is reached.

Dijkstra uses positive integer weights and a symbolic tie suffix. For edge ID
`i`, its path-search length is `weight*(M+1)*2^M + 2^i`. Every simple path's
suffix sum is at most `2^M-1`, so paths remain ordered first by their original
weight and distinct paths receive distinct suffixes. A basis has at most `M`
cycles, so its total suffix is at most `M*(2^M-1)`; the scale `(M+1)*2^M`
therefore also preserves the ordering of total basis weights. Candidate cycles
are still sorted by their original, unperturbed weight and then mask. At most
`N*M <= 96` generated candidates and 12 edge bits are needed. A simple cycle
weighs at most `8*9=72`; the coupled vertex/edge bounds give a safe total
result bound of 378.

The independent reference enumerates all simple cycles by DFS and applies the
same matroid greedy rule to the full cycle set. This checks the Horton
candidate construction against a structurally different cycle generator.

## Distinctness

This computes a basis spanning the entire undirected cycle space and minimizes
the sum of all basis-cycle weights. It differs from the directed
[`minimum_mean_cycle_karp`](../minimum_mean_cycle_karp/README.md) and
[`minimum_mean_cycle_howard`](../minimum_mean_cycle_howard/README.md), which
optimize the mean weight of one directed cycle; from
[`johnson_elementary_circuit_enumeration`](../johnson_elementary_circuit_enumeration/README.md),
which lists directed simple cycles; and from the graph's MST and connectivity
profiles.

## Provenance and rights

The algorithm is based on J. D. Horton's “A Polynomial-Time Algorithm to Find
the Shortest Cycle Basis of a Graph,” *SIAM Journal on Computing* 16(2),
358–366 (1987), [DOI 10.1137/0216026](https://doi.org/10.1137/0216026).
Mehlhorn and Michail's paper [“Minimum Cycle Bases: Faster and Simpler”](https://people.mpi-inf.mpg.de/~mehlhorn/ftp/MinCycleBasisFasterSimpler.pdf)
also states the shortest-path-tree candidate construction and GF(2) greedy
extraction. The papers remain copyrighted. This package uses their algorithmic
ideas only; all contracts, references, fixtures, and ports are independently
authored. See [`RIGHTS.md`](RIGHTS.md) and [`workload.json`](workload.json).

## Language ports

| Language | Source |
|---|---|
| C | [`c/m/minimum_cycle_basis_horton.c`](../../../c/m/minimum_cycle_basis_horton.c) |
| C3 | [`c3/m/minimum_cycle_basis_horton.c3`](../../../c3/m/minimum_cycle_basis_horton.c3) |
| C++ | [`cpp/m/minimum_cycle_basis_horton.cpp`](../../../cpp/m/minimum_cycle_basis_horton.cpp) |
| Elisa | [`elisa/m/minimum_cycle_basis_horton.elisa`](../../../elisa/m/minimum_cycle_basis_horton.elisa) |
| Mojo | [`mojo/m/minimum_cycle_basis_horton.mojo`](../../../mojo/m/minimum_cycle_basis_horton.mojo) |
| Nim | [`nim/m/minimum_cycle_basis_horton.nim`](../../../nim/m/minimum_cycle_basis_horton.nim) |
| Odin | [`odin/m/minimum_cycle_basis_horton.odin`](../../../odin/m/minimum_cycle_basis_horton.odin) |
| Rust | [`rust/m/minimum_cycle_basis_horton.rs`](../../../rust/m/minimum_cycle_basis_horton.rs) |
| V | [`v/m/minimum_cycle_basis_horton.v`](../../../v/m/minimum_cycle_basis_horton.v) |
| Zig | [`zig/m/minimum_cycle_basis_horton.zig`](../../../zig/m/minimum_cycle_basis_horton.zig) |

The [primary reference](primary_oracle.py),
[independent reference](independent_oracle.py), and
[static package inventory](verify_workload.py) accompany the bounded workload.
