# Hashiwokakero small solver reservation

## Discovery and rights

The discovery lead is the title and tags on Codewars' public [Algorithms +
Graph Theory listing](https://www.codewars.com/kata?tags=Algorithms%2CGraph+Theory):
“Hashiwokakero (Bridges) Solver.” The challenge page, description, examples,
tests, submissions, and code were not opened or reused. The local inventory and
active reservations contain no Hashiwokakero puzzle solver. This is distinct
from graph bridge-finding (cut edges) and from local crossword/nonogram
constraint solvers because it assigns multiplicities to geometric candidate
edges subject to exact degrees, noncrossing, and global connectivity.

Use Nikoli's [official Hashiwokakero rules](https://www.nikoli.co.jp/en/puzzles/hashiwokakero/)
for behavior context and the published [Hashiwokakero branch-and-cut study](https://arxiv.org/abs/1905.00973)
for solver/complexity context. These references supply ideas only. Do not copy
Codewars, Nikoli, or paper text, code, figures, examples, puzzle instances, or
tests. Independently author contract, fixtures, references, and ports.

## Exact bounded contract

- Name: `hashiwokakero_small_solver`.
- ABI: `i64_array_scalar`.
- Input: `[n,(x_0,y_0,d_0),...,(x_(n-1),y_(n-1),d_(n-1))]`.
- `2 <= n <= 6`; coordinates are distinct integer points in `0..7` for both
  axes; demands are integers in `1..8`; input length must be exactly `1+3*n`.
- A candidate bridge joins consecutive islands in one row or column, with no
  island between them. Each candidate receives multiplicity 0, 1, or 2.
- Every island's incident multiplicities must sum to its demand. Bridges are
  horizontal or vertical, may not cross another positive bridge or pass
  through an island, and the positive-multiplicity graph must be connected.
- Candidate edges are ordered by endpoint pair `(i,j)`, with `i<j`, in
  lexicographic order. If multiple solutions exist, return the lexicographically
  smallest multiplicity vector under `0 < 1 < 2`.
- Two distinct bridges conflict only when their interiors intersect. Bridges
  sharing an island endpoint are allowed and do not count as crossing.
- Success returns bit 32 set and each edge multiplicity in two bits beginning
  at `2*edge_index`. A valid unsatisfiable instance returns `-2`. Null,
  malformed, out-of-range, or duplicate-coordinate input returns `-1`.
- The implementation reserves 12 edge slots as a safe capacity. A tighter
  geometric bound is 7 candidate edges: if `r` rows and `c` columns contain
  islands, consecutive visibility edges number `n-r` horizontally plus
  `n-c` vertically, and distinct coordinates require `r*c>=n`; for `n<=6`,
  the maximum is 7. Exhaustive independent checking is therefore bounded by
  `3^7` assignments. The valid input length is at most 19 words and the
  parseable malformed-frame cap is 20 words.

## Method and implementation plan

All ten native ports use fixed arrays for six islands and twelve candidate
edges. The primary reference and ports enumerate edges in endpoint order, with
multiplicities `0,1,2`, maintaining residual degrees. Prune if a residual is
negative or exceeds twice the remaining incident candidate-edge count; reject
positive assignments that cross; use possible-edge reachability to reject
branches that can no longer connect all islands. Validate final connectivity
before accepting the first complete solution.

The independent reference scans complete base-three multiplicity vectors
without incremental degree state or search pruning. Edge 0 is the most
significant base-three digit, so ascending integer scan order is lexicographic
in the edge vector. For each vector it checks degree sums, interior crossings,
and connectivity from scratch. Its enumeration order and acceptance rule
independently pin the same lexicographic result.

Reservation completed: the C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, and
Zig ports, package references, workload, rights, inventory, and static helpers
are present. Scalar suite and catalog registration are recorded in the package
inventory and shared coverage ledger. The source remains uncompiled; no
programs, tests, scripts, checkers, builds, compilers, profilers, or benchmarks
were run.
