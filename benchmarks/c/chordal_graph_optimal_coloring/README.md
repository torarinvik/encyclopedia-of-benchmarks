# Optimal coloring of a chordal graph

Return the chromatic number of a simple undirected chordal graph. Input is
`[n,row_mask[0..n-1]]`, where `1 <= n <= 16`, each nonnegative row mask fits
in `n` bits, the diagonal is zero, and adjacency is symmetric. Exact length
is `n+1`; lengths through 18 are parseable. Invalid or null input returns `-1`;
a valid nonchordal graph returns `-2`.

Maximum cardinality search chooses an unnumbered vertex with the most
previously selected neighbors, breaking ties by smallest ID. Check that each
selected vertex's earlier neighbors form a clique. If so, greedily color in
selection order with the smallest available color. This is reverse perfect
elimination order, so the coloring is optimal on a chordal graph. A direct
adjacency-matrix implementation uses `O(n^3)` time for clique validation and
`O(n^2)` space. An independent small-graph reference recognizes chordality by
repeated simplicial-vertex deletion and finds the maximum clique by subset
enumeration; chordal graphs have equal clique and chromatic numbers.

The existing [`chordal_graph_recognition`](../../g/chordal_graph_recognition/README.md)
outputs a PEO or induced-hole certificate, not a coloring. The existing
[`graph_coloring`](../../g/graph_coloring/README.md) counts labeled colorings
with backtracking rather than using a perfect elimination order for optimal
coloring. The [graph theory lecture notes](https://www.cs.uoi.gr/~loukas/courses/grad/Algorithmic_Graph_Theory/index.files/GraphTheoreticAlgorithms-TBiedl.pdf)
describe the perfect-elimination coloring property. Only mathematical ideas
are used; contract, code, and fixtures are independently authored.

The contract, reference models, ten language drafts, workload, rights note,
package checker, and scalar-suite wiring are drafted. Verifier source
specifies every graph through five vertices and maximum-size complete and
empty graphs. The timed workload also includes full-size complete, empty,
path, and induced-cycle graphs. All remain unverified; nothing has been
compiled or executed.
