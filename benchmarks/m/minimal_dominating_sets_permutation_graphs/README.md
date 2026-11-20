# Minimal dominating sets in permutation graphs

This package counts inclusion-wise minimal dominating sets in a bounded
permutation graph using the five-tuple DAG from the permutation-model section
of the cited paper. It measures a different construction from
[`minimal_dominating_sets_interval`](../minimal_dominating_sets_interval/README.md),
which uses the interval representation and pair states.

## Contract

- ABI: `i64_array_scalar`; symbol: `minimal_dominating_sets_permutation_graphs`.
- Input is `[n, pi_0, ..., pi_(n-1)]`, with `1<=n<=8`. Vertex `i` is the
  segment whose bottom endpoint has rank `i` and top endpoint has rank `pi_i`.
  The `pi_i` values must be a permutation of `0..n-1`. Two vertices cross,
  and therefore are adjacent, exactly when their bottom and top orders are
  reversed.
- Malformed framing, invalid `n`, negative/out-of-range ranks, duplicate ranks,
  and null input return `-1`. The largest valid frame is 9 signed-i64 words;
  the parser accepts at most 10 words so a trailing-word probe is bounded.
- Output is the exact count as a signed-i64 scalar. Since `n<=8`, the count is
  at most `2^8-1=255`.

The primary follows §4 of the paper. A triple of consecutive selected vertices
falls into one of its five relative top-order cases. An Initial or Regular
five-tuple `(i,j,k,r,s)` stores the last three selected vertices, the
previously selected vertex with the relevant maximum top rank (or bottom
sentinel), and the tracked private neighbor (or sentinel). The implementation
checks the Initial/Regular predicates, derives each admissible next tuple
`(j,k,l,r',s')` from conditions A.1–A.5, and counts paths backward from final
states. It counts size-one and size-two minimal dominating sets directly, as
Theorem 20 specifies. Successors are generated when needed; the implementation
does not materialize the potentially large DAG arc set.

The independent oracle enumerates all nonempty vertex subsets. It tests
domination with closed-neighborhood bitmasks and checks the private-neighbor
criterion directly: every selected vertex must have a closed-neighborhood
vertex uncovered by the other selected vertices.

At `n=8`, the primary's state-count table has at most `9^5=59,049` signed-i64
entries, or 472,392 bytes. Adding the graph matrix, rank inverse, and local
state fits within the declared 1 MiB workspace cap. The source gives
`O(n^8)` time for the five-tuple DAG and path count. The independent reference
uses `O(2^n n^2)` time and `O(n)` neighborhood masks.

## Sources and duplicate decision

The operational predicates are from Kanté, Limouzy, Mary, Nourine, and Uno,
“On the Enumeration and Counting of Minimal Dominating sets in Interval and
Permutation Graphs,” ISAAC 2013, §4, Propositions 17–19 and Theorem 20,
[DOI 10.1007/978-3-642-45030-3_32](https://doi.org/10.1007/978-3-642-45030-3_32)
([paper PDF](https://perso.limos.fr/~limouzy/papers/ISAAC2013-2.pdf)). The
Encyclopedia of Algorithms Chapter 721 entry provides the crosswalk context;
the primary paper supplies the concrete permutation states and arc rules.
The existing local minimal-dominating-set benchmark covers interval graphs,
not permutation graphs. No implementation code, paper prose, figure, or
fixture is copied. The references and language ports are clean-room work.

- [Encyclopedia of Algorithms, “Minimal Dominating Set Enumeration,” Chapter 721](https://doi.org/10.1007/978-1-4939-2864-4_721)
- [Kanté et al., ISAAC 2013 paper](https://doi.org/10.1007/978-3-642-45030-3_32)

## Package files

- [`primary_oracle.py`](primary_oracle.py): five-tuple state DAG and path count.
- [`independent_oracle.py`](independent_oracle.py): exhaustive subset reference.
- [`workload.json`](workload.json): original fixtures and bounded input/output contract.
- [`verify_workload.py`](verify_workload.py): static fixture/reference reconciler.
- [`check_inventory.py`](check_inventory.py), [`INVENTORY.json`](INVENTORY.json),
  and [`INVENTORY.md`](INVENTORY.md): package inventory and source metadata.
- [`RIGHTS.md`](RIGHTS.md): provenance and clean-room statement.

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/m/minimal_dominating_sets_permutation_graphs.c`](../../../c/m/minimal_dominating_sets_permutation_graphs.c) |
| C3 | [`c3/m/minimal_dominating_sets_permutation_graphs.c3`](../../../c3/m/minimal_dominating_sets_permutation_graphs.c3) |
| C++ | [`cpp/m/minimal_dominating_sets_permutation_graphs.cpp`](../../../cpp/m/minimal_dominating_sets_permutation_graphs.cpp) |
| Elisa | [`elisa/m/minimal_dominating_sets_permutation_graphs.elisa`](../../../elisa/m/minimal_dominating_sets_permutation_graphs.elisa) |
| Mojo | [`mojo/m/minimal_dominating_sets_permutation_graphs.mojo`](../../../mojo/m/minimal_dominating_sets_permutation_graphs.mojo) |
| Nim | [`nim/m/minimal_dominating_sets_permutation_graphs.nim`](../../../nim/m/minimal_dominating_sets_permutation_graphs.nim) |
| Odin | [`odin/m/minimal_dominating_sets_permutation_graphs.odin`](../../../odin/m/minimal_dominating_sets_permutation_graphs.odin) |
| Rust | [`rust/m/minimal_dominating_sets_permutation_graphs.rs`](../../../rust/m/minimal_dominating_sets_permutation_graphs.rs) |
| V | [`v/m/minimal_dominating_sets_permutation_graphs.v`](../../../v/m/minimal_dominating_sets_permutation_graphs.v) |
| Zig | [`zig/m/minimal_dominating_sets_permutation_graphs.zig`](../../../zig/m/minimal_dominating_sets_permutation_graphs.zig) |

All ten language sources and package artifacts received source-only review.
The package is registered with the shared `i64_array_scalar` runner and
independent verifier. No programs, tests, scripts, helpers/checkers, builds,
compilers, profilers, or benchmarks have been run.
