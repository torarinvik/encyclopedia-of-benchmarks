# Three-state perfect phylogeny by 2-SAT

This package decides whether a bounded matrix with up to three observed states
per character admits a perfect phylogeny. It implements the expanded-character
reduction to 2-SAT described by Gusfield and Wu, with explicit handling for
characters that observe fewer than three states, then solves the formula with
implication graph strongly connected components. It returns only feasibility;
it does not construct or serialize a phylogeny.

## Contract

- ABI: `i64_array_scalar`; input is `[taxa_count, character_count, matrix...]`.
- Matrix values are `0`, `1`, or `2`, stored row-major by taxon then character.
- Each nonempty character may observe one, two, or three of those labels.
- `1 <= taxa_count <= 8`; `0 <= character_count <= 8`.
- The exact frame length is `2 + taxa_count * character_count`; maximum valid
  length is 66 words, and 67 words are parseable to reject trailing data.
- Zero characters are valid. That instance has no constraints and is
  satisfiable for every allowed positive taxa count.
- Invalid or null input returns `-1`. Valid output is `1` for a perfect
  phylogeny and `0` otherwise.

For each original character, the implementation creates one Boolean variable
for each of its three state-sets. The three positive pair clauses require at
least two selected state-sets. For every pair of state-sets from different
characters, it adds a negative pair clause precisely when all four binary
taxon patterns occur. Kosaraju's SCC check decides the resulting 2-CNF. With
at most 24 variables, the implication graph has at most 48 literal vertices
and at most 568 directed arcs, including the bounded missing-state clauses.
For a character observing exactly two states, the implementation adds a
negative unit clause for its absent state-column, forcing both observed
columns to be selected so the character's binary split is preserved. A
constant character needs no such clause because its full and empty columns
are compatible with every split. This is the package's explicit extension
for characters with fewer than three observed states; it leaves the paper's
three-state reduction unchanged when all three states occur. Building the
state masks costs `O(n*m)`; testing all
expanded-column pairs uses fixed-width bit masks, and the fixed-matrix
Kosaraju passes cost `O(m^2)`. The primary profile therefore takes
`O(n*m + m^2)` word operations and `O(m^2)` space. The fixed native adjacency
matrices and SCC state fit the 8 KiB workspace declaration.

The independent reference enumerates omitted states (`3^m` choices) and
directly checks pairwise compatibility. A two-state character may omit only
its absent column; constant characters are ignored. For each choice it
performs `O(n*m^2)` work, giving
`O(3^m*n*m^2)` time and `O(n*m)` space. This uses the exact-two-selected
columns simplification stated in Gusfield and Wu, Theorem 2.2: from any
pairwise-compatible selection containing at least two state-columns for each
character, retain any two for each character; deleting columns cannot create
an incompatibility. The oracle therefore checks the theorem's characterization
without using the implication graph.

The local [directed binary perfect phylogeny](../directed_perfect_phylogeny/README.md)
profile uses a direct binary compatibility test. This package overlaps that
profile's input semantics on binary-only matrices, while also covering
three-state characters and measuring the expanded-column 2-SAT construction.
It is a distinct algorithm profile rather than another implementation of the
binary direct test.

## Sources and rights

The chapter context is Jesper Jansson, “Perfect Phylogeny (Bounded Number of
States),” *Encyclopedia of Algorithms*, Chapter 288,
[DOI 10.1007/978-1-4939-2864-4_288](https://doi.org/10.1007/978-1-4939-2864-4_288).
The operational 3-state reduction is Dan Gusfield and Yufeng Wu, “The
Three-state Perfect Phylogeny Problem Reduces to 2-SAT,” §2, Theorem 2.1,
pp. 297–298, [DOI 10.4310/CIS.2009.v9.n4.a1](https://doi.org/10.4310/CIS.2009.v9.n4.a1).
Chapter 288 supplies the bounded-state problem context. The operational 2-SAT
clauses and reduction are specifically attributed to Gusfield and Wu, rather
than claimed as a procedure stated in the encyclopedia entry. Sources supplied
algorithm descriptions only; all
ports, references, fixtures, and prose here were written independently. No
source-code license is asserted. See [RIGHTS.md](RIGHTS.md).

## References and workload

- [2-SAT primary oracle](primary_oracle.py)
- [Omitted-state independent oracle](independent_oracle.py)
- [Bounded workload](workload.json)
- [Static inventory](INVENTORY.md)
- [Chapter and method source crosswalk](SOURCE_CROSSWALK.md)

## Language ports

| Language | Source |
|---|---|
| C | [`c/p/perfect_phylogeny_three_state_2sat.c`](../../../c/p/perfect_phylogeny_three_state_2sat.c) |
| C3 | [`c3/p/perfect_phylogeny_three_state_2sat.c3`](../../../c3/p/perfect_phylogeny_three_state_2sat.c3) |
| C++ | [`cpp/p/perfect_phylogeny_three_state_2sat.cpp`](../../../cpp/p/perfect_phylogeny_three_state_2sat.cpp) |
| Elisa | [`elisa/p/perfect_phylogeny_three_state_2sat.elisa`](../../../elisa/p/perfect_phylogeny_three_state_2sat.elisa) |
| Mojo | [`mojo/p/perfect_phylogeny_three_state_2sat.mojo`](../../../mojo/p/perfect_phylogeny_three_state_2sat.mojo) |
| Nim | [`nim/p/perfect_phylogeny_three_state_2sat.nim`](../../../nim/p/perfect_phylogeny_three_state_2sat.nim) |
| Odin | [`odin/p/perfect_phylogeny_three_state_2sat.odin`](../../../odin/p/perfect_phylogeny_three_state_2sat.odin) |
| Rust | [`rust/p/perfect_phylogeny_three_state_2sat.rs`](../../../rust/p/perfect_phylogeny_three_state_2sat.rs) |
| V | [`v/p/perfect_phylogeny_three_state_2sat.v`](../../../v/p/perfect_phylogeny_three_state_2sat.v) |
| Zig | [`zig/p/perfect_phylogeny_three_state_2sat.zig`](../../../zig/p/perfect_phylogeny_three_state_2sat.zig) |

The package is registered in `run_i64_array_scalar.py` and
`verify_i64_array_scalar.py`. No programs, tests, scripts, builds, or compilers
were run.
