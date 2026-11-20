# Zwick deterministic witness-prefix bridging set

This package profiles the deterministic `find-bridge` construction for an
unweighted directed graph, using a supplied shortest-path witness matrix. It
measures bridge-constraint construction and greedy hitting-set selection; it
does not run the outer APSP distance-product algorithm.

## Contract

- ABI: `i64_array_scalar`; symbol: `zwick_deterministic_bridging_set`.
- Input is `[n,s,A[n*n],W[n*n]]`, with `2<=n<=8` and `2<=s<=n`.
  `A` is a row-major 0/1 adjacency matrix for a loop-free directed graph.
  The graph must be strongly connected. `W` is a row-major witness matrix:
  zero means the represented shortest path is the direct edge (or the empty
  path on the diagonal); a positive entry `v+1` names internal vertex `v`.
- Every non-direct witness must split a shortest path: if `W[i,j]=v+1`, the
  all-pairs unit-edge distances must satisfy
  `dist(i,v)+dist(v,j)=dist(i,j)`. This strictly decreases both recursive
  subproblem distances, so the witness path is finite and simple. Direct
  entries must correspond to an edge or a diagonal pair.
- For each ordered pair `(i,j)` in row-major order, the primary extracts up to
  `s` internal vertices from the witness path using the paper's recursive
  `sub-path` rule, unions those vertices with `{i,j}`, and retains that set as
  a constraint if its cardinality is at least `s`. `C` is a set family, so
  identical vertex masks are coalesced, retaining their first row-major
  occurrence.
- The greedy hitting pass repeatedly chooses the vertex belonging to the
  largest number of currently unhit constraints; ties choose the lowest vertex
  ID. The result is the selected vertex set encoded as an unsigned bit mask in
  the scalar result. This deterministic tie rule refines the paper's greedy
  hitting-set step.
- Malformed frames, invalid adjacency/witness data, non-strongly-connected
  graphs, and null input return `-1`. The largest valid frame is 130 i64 words;
  the parser accepts at most 131 words to bound a trailing-word probe. The
  result lies in `[0,255]`. Native workspace is bounded by 4,096 bytes.

The primary follows the recursive prefix extraction from Figure 11 and the
constraint/greedy-hit construction in Section 6. The independent reference
materializes each complete witness path by iteratively expanding witness
pairs, then takes its first `s` internal vertices before constructing the
same set family. Identical vertex masks are coalesced at their first
row-major occurrence, matching Figure 10's `C <- C union {U_ij}` semantics.
Both validate the supplied shortest path witnesses against graph distances.

With `n<=8`, validation and distance construction use `O(n^3)` time, prefix
construction uses `O(n^2 s)` time, and the bounded greedy pass uses `O(n^4)`
time and `O(n^2)` storage. The independent reference also uses `O(n^4)` time
and `O(n^2)` storage.

## Sources and duplicate decision

The operational algorithm is Uri Zwick, “All Pairs Shortest Paths using
Bridging Sets and Rectangular Matrix Multiplication,” Section 6, Figures 10–11
and Lemma 6.6, [DOI 10.1145/567112.567114](https://doi.org/10.1145/567112.567114)
([author-hosted paper](https://cadmo.ethz.ch/education/lectures/FS18/SAADS/papers/JACM02_APSP_Using_Bridging_Sets.pdf)).
The chapter crosswalk is *Encyclopedia of Algorithms*, “All Pairs Shortest
Paths via Matrix Multiplication,” Chapter 12,
[DOI 10.1007/978-1-4939-2864-4_12](https://doi.org/10.1007/978-1-4939-2864-4_12).
The chapter summarizes the accelerated Zwick framework and defers its
bridging-set construction details to the paper.

Local `floyd_warshall` and `apsp_min_plus_repeated_squaring` compute distance
matrices; `min_plus_distance_product` computes one matrix product. None builds
the deterministic hitting set over sampled witness-path prefixes. This
package isolates that Chapter 12 algorithmic component and makes no claim to
implement the subcubic matrix-multiplication speedup or the complete APSP
framework. No source code, text, figures, examples, or tests are copied.

## Package files

- [`primary_oracle.py`](primary_oracle.py): recursive source-style witness
  prefix extraction and greedy hitting set.
- [`independent_oracle.py`](independent_oracle.py): iterative full-path
  expansion and prefix truncation reference.
- [`workload.json`](workload.json) and [`verify_workload.py`](verify_workload.py):
  bounded fixtures and source-only reference reconciliation.
- [`check_inventory.py`](check_inventory.py), [`INVENTORY.json`](INVENTORY.json),
  and [`INVENTORY.md`](INVENTORY.md): package metadata and static inventory.
- [`RIGHTS.md`](RIGHTS.md): provenance and clean-room statement.

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/z/zwick_deterministic_bridging_set.c`](../../../c/z/zwick_deterministic_bridging_set.c) |
| C3 | [`c3/z/zwick_deterministic_bridging_set.c3`](../../../c3/z/zwick_deterministic_bridging_set.c3) |
| C++ | [`cpp/z/zwick_deterministic_bridging_set.cpp`](../../../cpp/z/zwick_deterministic_bridging_set.cpp) |
| Elisa | [`elisa/z/zwick_deterministic_bridging_set.elisa`](../../../elisa/z/zwick_deterministic_bridging_set.elisa) |
| Mojo | [`mojo/z/zwick_deterministic_bridging_set.mojo`](../../../mojo/z/zwick_deterministic_bridging_set.mojo) |
| Nim | [`nim/z/zwick_deterministic_bridging_set.nim`](../../../nim/z/zwick_deterministic_bridging_set.nim) |
| Odin | [`odin/z/zwick_deterministic_bridging_set.odin`](../../../odin/z/zwick_deterministic_bridging_set.odin) |
| Rust | [`rust/z/zwick_deterministic_bridging_set.rs`](../../../rust/z/zwick_deterministic_bridging_set.rs) |
| V | [`v/z/zwick_deterministic_bridging_set.v`](../../../v/z/zwick_deterministic_bridging_set.v) |
| Zig | [`zig/z/zwick_deterministic_bridging_set.zig`](../../../zig/z/zwick_deterministic_bridging_set.zig) |

The package is integrated with the `i64_array_scalar` runner/verifier and
catalog. No programs, tests, scripts, helpers/checkers, builds, compilers,
profilers, or benchmarks were run.
