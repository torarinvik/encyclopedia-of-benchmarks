# Hochbaum pseudoflow maximum flow

This package implements a bounded, deterministic version of Hochbaum's
highest-label pseudoflow algorithm. It initializes the simple normalized tree
from §5 with one singleton branch per nonterminal. Source-to-vertex and
vertex-to-sink capacities become signed node weights; the common amount at a
vertex and direct source-to-sink arcs are fixed cut contributions. Internal
arc flows start at zero. A branch is strong when its root has positive excess;
otherwise it is weak, including zero-deficit branches.

At each iteration the branch with the highest-label strong root is selected;
roots tied at that label use FIFO activation order. In the selected branch,
the algorithm scans lowest-label nodes and seeks a residual merger whose head
has label `l-1`, where `l` is the selected node's label. The head may belong
to a strong branch, as allowed by §7.2. Arc ties are resolved by tail vertex,
input arc index, forward before reverse residual direction, then head vertex.
If no such merger exists, the first lowest-label node whose children all
have labels at least `l+1` is relabeled to `l+1`, following §7.1's relabel
rule. After a merger, the strong section of the path is relabeled to one more
than the head label.

The merger removes the selected strong root's attachment to the extended
root, adds the merger arc, and reverses that branch path into the target
branch. The algorithm pushes the strong root's full excess along the unique
normalized-tree path. When an arc has less residual capacity than the excess
still being pushed, it saturates that arc, splits the tree there, and makes
the arc's tail a new strong root with the excess left behind. This is §5's
normalization procedure, not the one-bottleneck cycle exchange from the
separate §10 pseudoflow-simplex variant. When no residual arc leaves the
strong set for the weak set, the strong/weak partition certifies a minimum
cut. The scalar result is that cut capacity; the code does not recover a
feasible edge-by-edge maximum flow.

The paper establishes that the terminal strong set is a minimum cut when no
residual arc leaves it for the weak set. Its labeling analysis bounds labels
by the vertex count and each residual arc's use as a merger by at most
`N-1`. For this contract there are at most 24 original arcs, at most two
residual directions per arc, at most eight total vertices, and at most six
nonterminals to relabel. The implementation uses a static ceiling of 512
merger/relabel iterations, above `2*M*(N-1) + (N-2)*N` at the maximum frame.
Splits within one merger are bounded by the at most six nonterminal tree
edges.

## Input and output

The `i64_array_scalar` input is
`[N,M,source,sink,(u,v,capacity)*M]`. Vertices are numbered from one;
`2<=N<=8`, `0<=M<=24`, terminals are distinct, and capacities are in
`0..100`. The exact frame has `4+3*M` words, at most 76. A frame up to 77
words is parseable so the 77-word trailing-value case is rejected cleanly.
Parallel arcs are supported and remain distinct internally. Self-loops,
arcs into the source, and arcs out of the sink are invalid. Direct
source-to-sink arcs are supported. A valid result is the maximum flow value
in `0..2400`; malformed or null input returns `-1`.

The primary oracle follows the normalized-tree highest-label pseudoflow
procedure. The independent oracle enumerates all at most `2^6=64` source-side subsets
and minimizes the cut capacity directly. Workload fixtures include parallel
terminal arcs, shared bottlenecks, reverse residual capacity, a zero-deficit
pivot, maximum frame size, and malformed frames.

## Provenance and neighboring profiles

Algorithm ideas are drawn from Dorit S. Hochbaum, “The Pseudoflow Algorithm:
A New Algorithm for the Maximum-Flow Problem,” *Operations Research* 56(4),
992–1009 (2008), [DOI 10.1287/opre.1080.0524](https://doi.org/10.1287/opre.1080.0524),
especially the normalized-tree initialization and full-excess normalization
in §5, the labeling rules in §6.3 and highest-label branch choice in §7.2.
The FIFO root tie-break and bounded scan order make the policy deterministic.
No upstream source code or prose is copied. This profile differs from
[highest-label push–relabel](../highest_label_push_relabel/README.md): it
maintains strong/weak normalized-tree branches and sends full branch excess
through their tree paths, then returns a blocking-cut certificate. The
independent cut enumeration is for verification only.

## Language ports

| Language | Source |
|---|---|
| C | [hochbaum_pseudoflow_maxflow.c](../../../c/h/hochbaum_pseudoflow_maxflow.c) |
| C3 | [hochbaum_pseudoflow_maxflow.c3](../../../c3/h/hochbaum_pseudoflow_maxflow.c3) |
| C++ | [hochbaum_pseudoflow_maxflow.cpp](../../../cpp/h/hochbaum_pseudoflow_maxflow.cpp) |
| Elisa | [hochbaum_pseudoflow_maxflow.elisa](../../../elisa/h/hochbaum_pseudoflow_maxflow.elisa) |
| Mojo | [hochbaum_pseudoflow_maxflow.mojo](../../../mojo/h/hochbaum_pseudoflow_maxflow.mojo) |
| Nim | [hochbaum_pseudoflow_maxflow.nim](../../../nim/h/hochbaum_pseudoflow_maxflow.nim) |
| Odin | [hochbaum_pseudoflow_maxflow.odin](../../../odin/h/hochbaum_pseudoflow_maxflow.odin) |
| Rust | [hochbaum_pseudoflow_maxflow.rs](../../../rust/h/hochbaum_pseudoflow_maxflow.rs) |
| V | [hochbaum_pseudoflow_maxflow.v](../../../v/h/hochbaum_pseudoflow_maxflow.v) |
| Zig | [hochbaum_pseudoflow_maxflow.zig](../../../zig/h/hochbaum_pseudoflow_maxflow.zig) |

Static package inventory is described in `check_inventory.py`. No programs,
tests, checkers, compilers, or benchmarks have been run for this package.
