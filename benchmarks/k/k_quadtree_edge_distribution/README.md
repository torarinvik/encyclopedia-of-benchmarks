# K-quadtree edge distribution

This package measures the edge-to-cell distribution stage for a supplied
canonical K-quadtree partition. The cells and straight-line edges are input;
quadtree construction and graph generation are outside the measured call.

## Contract

The exported symbol is `k_quadtree_edge_distribution` with the
`i64_array_bytes_output` ABI:

```text
k_quadtree_edge_distribution(input, length, output, capacity)
```

The input is `[n,c,(depth,prefix)*c,(x1,y1,x2,y2)*n]`. There are `0..8`
edges and `1..46` cells. A valid frame has `2 + 2c + 4n` signed-i64 words;
the maximum valid frame is 126 words and the parser accepts at most 127 words
so one trailing-word probe can be rejected. The output is
`[c,mask_0,...,mask_(c-1)]`, serialized as little-endian signed-i64 words.
Bit `j` of a cell mask is set exactly when input edge `j` intersects that
closed cell. The maximum output is 47 words (376 bytes). Invalid input
returns `-1`; null output or insufficient capacity returns `-2`. Input is
validated before output pointer/capacity handling, and errors leave output
untouched. Workspace is capped at 16,384 bytes, excluding caller buffers. The
widest 64-bit-index ports can keep parser state (about 5.8 KiB), sweep arrays
(about 1.6 KiB), and frontier construction arrays (about 3.3 KiB) live at once,
for roughly 10.9 KiB before scalar temporaries, alignment, and ABI-local
bookkeeping; the rounded cap covers that peak. The Mojo helper passes its
large fixed arrays by mutable reference to avoid transient whole-array copies.

Coordinates lie in `[0,255]`. An edge's endpoints must be distinct and no
coordinate may be divisible by 16. Horizontal edges are excluded. Edges are
pairwise disjoint, including endpoints, and no edge passes through an
internal depth-four grid vertex. These conditions make the two monotone
directional traversals unambiguous. The canonical domain is `[0,256]²`.

Each cell descriptor `(depth,prefix)` is a canonical square at depth 0 through
4. The prefix is the base-4 path from the root, with digits
`SW=0,NW=1,SE=2,NE=3`. For a depth-`d` cell, its positive-order Z interval is
`[prefix*4^(4-d),(prefix+1)*4^(4-d))`. Input cells, in original cell-ID order,
must form a complete, prefix-free partition in increasing interval order.
Every leaf contains at most one edge endpoint. Every represented internal
prefix has endpoints in at least two of its immediate child quadrants. For
zero edges, the only valid partition is the root cell `(0,0)`.

For each endpoint, the depth-four Morton key reads coordinate bits 7 through
4 from most to least significant and appends digit `2*x_bit+y_bit`. Each
endpoint maps to the unique supplied leaf interval containing that key.
Edges are normalized from smaller x to larger x; a vertical edge is ordered
from smaller y to larger y. The normalized edge is E+ when `dy>0` (vertical
edges are E+) and E- when `dy<0`.

E+ cells use the input's positive Z order. E- cells use the paper's opposite
Z order `NW,NE,SW,SE`, obtained by remapping positive digits
`SW->2,NW->0,SE->3,NE->1` and sorting transformed intervals. In each order,
every edge's normalized start cell must precede or equal its end cell. Within
each direction, edges are ordered by the normalized start endpoint's
depth-four key and then by edge ID.

The primary follows the paper's two-frontier-stack procedure. For a cut before
cell `j`, refine the supplied partition to its 16-by-16 depth-four atoms and
mark atoms belonging to earlier cells as processed. Each column must be a
bottom prefix; let `h[x]` be its processed height. The resulting nonincreasing
profile defines the monotone staircase `B_j`: from the unit square's
northwest corner, follow the perimeter to the first interface point, follow
the processed/unprocessed interface, then follow the perimeter to the
southeast corner. The current cell's lower-left corner lies on this chain and
splits it into the source's left-edge-to-corner and corner-to-bottom portions.
This finite representation has at most 33 grid vertices.

`SL` and `SB` hold earlier-starting edges whose unique crossing of `B_j` lies
on the first or second portion, respectively, in boundary order. At each
cell, pop intersecting tops from both stacks, merge those edges with starts
in the cell, emit the incidences, and dispatch continuing edges by their
exact exit side: top exits go to `SL`, right exits to `SB`, ordered toward
the cell's upper-right corner. Before the next cell, if its lower-left corner
moves upward, transfer `SL` tops until the top edge's crossing of `B_(j+1)`
remains on the first portion; otherwise transfer `SB` tops until its crossing
remains on the second portion. This is the source's corner-side stopping
predicate expressed as an exact finite-frontier membership test. Edge/chain
crossings use integer orientations; exit and crossing order use exact rational
comparisons. The input general-position rule excludes frontier vertices and
ties.

For E-, rotate coordinates to `(x′,y′)=(256−y,x)` and rotate each cell box by
the same map. This makes every negative-slope edge positive-slope in the
sweep frame; the same `SL`/`SB` procedure applies under `Z′`, and masks are
written back using original cell and edge IDs. The independent reference
instead checks every edge/cell pair directly using rational Liang–Barsky
clipping. Both use exact geometry without floating-point tolerances. Including
validation and finite-frontier reconstruction, the bounded work is
`O(c*256+n^2+I)`, where `I` is the number of reported edge-cell incidences;
the paper's external-memory I/O bound is not claimed for this ABI profile.

## Source and distinction

The operational algorithm is from H. Haverkort, M. McGranaghan, and L. Toma,
“An Edge Quadtree for External Memory,” §3 and §4.2, [SEA 2013, DOI
10.1007/978-3-642-38527-8_12](https://doi.org/10.1007/978-3-642-38527-8_12).
Chapter 585 of the [Encyclopedia of Algorithms, DOI
10.1007/978-1-4939-2864-4_585](https://doi.org/10.1007/978-1-4939-2864-4_585)
provides the book crosswalk. The bounded profile supplies the partition and
edges, so it isolates distribution and does not measure the preceding sampled
point-subdivision stage in
[`k_quadtree_sampled_point_subdivision`](../k_quadtree_sampled_point_subdivision/README.md).
It is also distinct from the repository's point-quadtree insertion and Morton
sorting benchmarks.

The references and ten language ports are clean-room implementations of the
published procedure. See [workload.json](workload.json),
[RIGHTS.md](RIGHTS.md), and [INVENTORY.md](INVENTORY.md). The package-local
metadata helpers are included for static review and have not been executed.
Shared runner/catalog integration remains with the repository integrator.
