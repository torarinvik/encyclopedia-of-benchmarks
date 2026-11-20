# Free polyomino enumeration

This scalar profile returns the number of free polyominoes of order `n` for
`1 <= n <= 8`. Cells share an edge, the occupied cells must form one connected
set, and translations, rotations, and reflections do not create a new shape.
The result sequence through the bound is `1, 1, 2, 5, 12, 35, 108, 369`.

The ten primary ports use canonical growth. They start from one cell, add each
edge-neighbor that is not already occupied, normalize each candidate across
the eight square symmetries and translations, and deduplicate the resulting
sorted coordinate signatures at every size. A shape holds at most eight
coordinates; at most 512 signatures are stored in a size layer. With that
small bound, direct signature comparison is used in place of a hash table.

For a layer with `S_k <= 512` shapes, each shape contributes at most `4*k`
candidate extensions. Canonicalizing one candidate takes `O(8*k^2)` work with
the bounded insertion sort, and checking it against the next layer takes
`O(S_(k+1)*k)`. The primary time bound is therefore
`O(sum_{k=1}^{n-1} 4*k*S_k*(8*k^2 + S_(k+1)*k))`; its two state layers use
`O(2*512*n)` coordinate words. The independent restricted-growth reference
visits fixed shapes by increasing size, uses `O(n)` frontier bookkeeping per
visit for its copied blocked/frontier sets, and performs `O(8*n*log(n))` work
to canonicalize each completed fixed shape. If `F_k` is the fixed-shape count,
the conservative time bound is
`O(n^2*sum_k F_k + 8*n*log(n)*F_n)`. Because this reference copies blocked
sets along the active recursion stack, its conservative space bound is
`O(n^3)` plus the stored free signatures.

The primary oracle follows the same canonical-growth profile. The independent
oracle uses a fixed-orientation restricted-growth search: it anchors the
bottom-left cell at the origin, restricts cells to the upper half-plane and
nonnegative x-axis, and excludes older-sibling points while recursively
extending the reachable frontier. It canonicalizes the completed fixed shapes
under D4 only when counting free classes. The restricted-growth idea follows
Redelmeier's fixed-polyomino enumeration; the primary ports do not claim to be
that exact algorithm.

## Input and output

The `i64_array_scalar` input is `[n]`. Exactly one signed 64-bit word is
required, with `1 <= n <= 8`. The output is the number of distinct free
polyominoes and lies in `1..369`. Null, malformed, trailing, or out-of-range
input returns `-1`.

## Provenance and neighboring profiles

The title was discovered in the RosettaGit [task index](https://rosettagit.org/tasks/)
and its [Free polyominoes enumeration entry](https://rosettagit.org/tasks/free-polyominoes-enumeration/);
these pages are used only as idea indexes. The algorithm references are D. Hugh
Redelmeier, “Counting Polyominoes: Yet Another Attack,” *Discrete Mathematics*
36(2), 191–203 (1981), [DOI 10.1016/0012-365X(81)90237-5](https://doi.org/10.1016/0012-365X(81)90237-5),
and the later exposition [“Redelmeier's algorithm for counting lattice
animals”](https://arxiv.org/abs/1106.1078). The primary uses canonical growth;
the independent reference implements restricted fixed-shape growth and then
applies symmetry canonicalization. All code, workload values, and explanatory
text are independently authored. No task text, examples, tests, or source
code are reused.

This is a lattice-shape enumeration profile, distinct from
[`connected_labeled_graph_count`](../../c/connected_labeled_graph_count/README.md),
which counts simple graphs on labeled vertex sets. This package uses square-
lattice edge neighbors and identifies shapes under translation and D4 symmetry.

## Language ports

| Language | Source |
|---|---|
| C | [free_polyomino_enumeration.c](../../../c/f/free_polyomino_enumeration.c) |
| C3 | [free_polyomino_enumeration.c3](../../../c3/f/free_polyomino_enumeration.c3) |
| C++ | [free_polyomino_enumeration.cpp](../../../cpp/f/free_polyomino_enumeration.cpp) |
| Elisa | [free_polyomino_enumeration.elisa](../../../elisa/f/free_polyomino_enumeration.elisa) |
| Mojo | [free_polyomino_enumeration.mojo](../../../mojo/f/free_polyomino_enumeration.mojo) |
| Nim | [free_polyomino_enumeration.nim](../../../nim/f/free_polyomino_enumeration.nim) |
| Odin | [free_polyomino_enumeration.odin](../../../odin/f/free_polyomino_enumeration.odin) |
| Rust | [free_polyomino_enumeration.rs](../../../rust/f/free_polyomino_enumeration.rs) |
| V | [free_polyomino_enumeration.v](../../../v/f/free_polyomino_enumeration.v) |
| Zig | [free_polyomino_enumeration.zig](../../../zig/f/free_polyomino_enumeration.zig) |

The package-local `check_inventory.py` records the static port and fixture
inventory. No programs, tests, scripts, checkers, builds, compilers, profilers,
or benchmarks have been run for this package.
