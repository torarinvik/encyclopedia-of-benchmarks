# GBBS randomized-greedy maximal matching

This benchmark isolates the edge-priority core of GBBS MaximalMatching at commit dbd1dcad582c0a316c5ba0d5524319d596dd82da. The pinned kernel repeatedly commits currently live edges with no higher-priority adjacent edge, then removes edges incident to matched vertices. A total explicit edge-rank order makes this bounded profile reproducible: rank zero is highest priority, matching the source's minimum-index reservation, and edges are processed from lowest rank to highest.

Input is [node_count, edge_count, rank_0, ..., rank_(m-1), u_0, v_0, ..., u_(m-1), v_(m-1)]. The simple undirected graph has 1–16 vertices and at most 64 edges. Each edge is canonical (u < v), appears once, and has a unique rank that is a permutation of 0..m-1. The output is one little-endian signed 64-bit value per input edge, 1 for selected and 0 otherwise. The matching is maximal, not necessarily maximum-cardinality.

This deterministic profile covers the source's priority-greedy matching kernel. GBBS's randomized edge sampling, prefix filtering, parallel reservation, graph loading, and timing are excluded. The local Hopcroft–Karp and Kuhn benchmarks solve maximum-cardinality bipartite matching, a different objective and input contract.

Source: benchmarks/MaximalMatching/RandomGreedy/MaximalMatching.h, symbol gbbs::MaximalMatching, at the pinned source (https://github.com/ParAlg/gbbs/blob/dbd1dcad582c0a316c5ba0d5524319d596dd82da/benchmarks/MaximalMatching/RandomGreedy/MaximalMatching.h). The package retains the repository's MIT license in LICENSE.txt. The primary profile oracle scans by ascending edge rank; the independent verifier simulates rounds of live local minima.
