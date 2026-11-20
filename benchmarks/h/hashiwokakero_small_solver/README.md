# Hashiwokakero Small Solver

This benchmark solves a bounded Hashiwokakero layout using candidate bridges
between consecutive islands. It chooses the lexicographically smallest valid
bridge-multiplicity vector, with a deterministic edge order and a fixed exact
search bound.

## Contract

- ABI: `i64_array_scalar`.
- Input: `[n,(x_0,y_0,d_0),...,(x_(n-1),y_(n-1),d_(n-1))]`, with `2<=n<=6`.
- Coordinates are distinct integer points in `0..7`; demands are in `1..8`.
  Input length must be exactly `1+3*n`, at most 19 words. Length 20 is the
  largest parseable malformed frame.
- A candidate bridge joins consecutive islands in the same row or column.
  Each candidate has multiplicity `0`, `1`, or `2`.
- Incident multiplicities must add to each island's demand. Positive bridges
  may not intersect in their interiors; bridges that share an island endpoint
  are allowed. The graph formed by positive bridges must connect every island.
- Candidate edges are ordered by increasing `(i,j)`, with `i<j`. Among all
  valid bridge assignments, return the lexicographically smallest vector under
  `0<1<2`.
- Success returns bit 32 set and each multiplicity in two bits starting at
  `2*edge_index`. Invalid or malformed input returns `-1`; a valid instance
  with no solution returns `-2`.

## Method

Candidate visibility is built by checking all island pairs and rejecting a
pair when a third island lies between them. With `r` occupied rows and `c`
occupied columns, there are at most `n-r` horizontal plus `n-c` vertical
candidates. Distinct coordinates require `r*c>=n`; for `n<=6`, the maximum is
seven candidate edges. The native arrays reserve twelve edge slots.

The primary search assigns edges in endpoint-pair order and tries multiplicity
`0`, then `1`, then `2`. It tracks residual island degrees and remaining
incident edge counts, pruning when a residual is negative or exceeds the
remaining capacity. It rejects a new positive bridge if its interior crosses
an earlier positive bridge. A possible-edge reachability check rejects a
partial assignment when even the unassigned edges that remain legal cannot
connect the islands. The first complete solution is therefore the
lexicographically smallest one.

The independent oracle uses a different control path: it enumerates complete
base-three edge vectors and checks all constraints from scratch. Edge zero is
the most-significant trit, so ascending integer enumeration follows the same
lexicographic vector order. At most `3^7 = 2,187` complete vectors are checked.
Both the native search and the independent oracle use integer coordinates and
strict interior-intersection tests, which permit shared endpoints.

Candidate generation takes `O(n^3)`. Search and exhaustive verification take
`O(3^E * (n+E^2))` in the bounded profile, where `E<=7`; fixed scratch is
`O(n+E^2)`.

## Sources and rights

- Discovery only: the public Codewars [Algorithms + Graph Theory title/tag
  listing](https://www.codewars.com/kata?tags=Algorithms%2CGraph+Theory).
  No Codewars kata page, statement, examples, tests, submissions, or code was
  consulted or reused.
- Rules context: Nikoli's [official Hashiwokakero rules](https://www.nikoli.co.jp/en/puzzles/hashiwokakero/).
- Solver context: the published [Hashiwokakero branch-and-cut study](https://arxiv.org/abs/1905.00973).

All code, contract details, oracles, and fixtures are independently authored.
The references provide behavior or method context only; no copyrighted prose,
code, figures, puzzle instances, examples, or tests were copied. See
[RIGHTS.md](RIGHTS.md) for the provenance note.

## Package artifacts

- [workload.json](workload.json): contract, source roles, and fixtures.
- [primary_oracle.py](primary_oracle.py): residual-degree constrained search.
- [independent_oracle.py](independent_oracle.py): complete-vector validation.
- [verify_workload.py](verify_workload.py): static fixture/reference reconciler.
- [check_inventory.py](check_inventory.py): static package/source inventory.
- [INVENTORY.json](INVENTORY.json) and [INVENTORY.md](INVENTORY.md): file and
  port inventories.

## Native ports

| Language | Source |
|---|---|
| C | `c/h/hashiwokakero_small_solver.c` |
| C3 | `c3/h/hashiwokakero_small_solver.c3` |
| C++ | `cpp/h/hashiwokakero_small_solver.cpp` |
| Elisa | `elisa/h/hashiwokakero_small_solver.elisa` |
| Mojo | `mojo/h/hashiwokakero_small_solver.mojo` |
| Nim | `nim/h/hashiwokakero_small_solver.nim` |
| Odin | `odin/h/hashiwokakero_small_solver.odin` |
| Rust | `rust/h/hashiwokakero_small_solver.rs` |
| V | `v/h/hashiwokakero_small_solver.v` |
| Zig | `zig/h/hashiwokakero_small_solver.zig` |

Static review only; no programs, scripts, checkers, tests, builds, compilers,
or benchmarks have been run.
