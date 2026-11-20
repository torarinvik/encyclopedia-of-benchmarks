# PMR edge quadtree construction

This package implements the incremental PMR quadtree rule described in
Chapter 585 of the *Encyclopedia of Algorithms*. Each nondegenerate straight
segment is inserted into every quadtree region it intersects. A leaf splits
when its segment count exceeds the fixed threshold; existing segments are
redistributed to every intersected child in northwest, northeast, southwest,
southeast order.

## Bounded profile

The export is `pmr_edge_quadtree` with the `i64_array_bytes_output` ABI. Input
is `[segment_count, threshold, x0,y0,x1,y1, ...]`, with 0–8 segments,
threshold 1–8, and integer endpoints in `[0,255]²`. Each segment must have
distinct endpoints, while intersections and duplicate segments are accepted.
The root is `[-0.5,255.5]²`; cell boundaries are represented in
doubled integer coordinates. Cells are closed, so a segment crossing a split
boundary is stored in every child it intersects. The maximum depth is 8 and
the node allocation is capped at 2,048; an overfull leaf at the depth limit or
a node-capacity overflow returns `-1` without writing output. Two identical
vertical segments exercise the depth-limit error because both copies remain
together in every intersected leaf until the cap is reached.

The output is little-endian signed-i64 words beginning with
`[node_count, segment_count]`. Each node then emits `[parent_id, quadrant,
depth, local_segment_count, segment_ids...]`. The root has parent and quadrant
`-1`; child quadrants are 0=NW, 1=NE, 2=SW, 3=SE. A split node has four child
records and no local segment IDs. Nodes are serialized in canonical preorder
with children visited in quadrant order; segment IDs retain input order. The
maximum output is 196,624 bytes. Invalid input
returns `-1`; null or short output returns `-2`; errors write no bytes.

This is distinct from the local point-oriented [`quad_tree`](../q/quad_tree/README.md),
which inserts points and performs square range queries, and from
[`morton_sort`](../m/morton_sort/README.md), which orders points by Morton
code. The PMR package indexes line segments and applies edge-count splits.

The primary oracle builds the incremental tree with exact orientation-based
segment/box tests. The independent oracle uses rational clipping and a
top-down reconstruction from the final segment set. The latter checks the
serialized tree and leaf memberships without sharing the incremental update
logic. `verify_workload.py` only inspects package metadata and source paths; it
does not invoke either oracle.

The method is described in Haverkort and Toma, “Quadtrees and Morton
Indexing,” Chapter 585, *Encyclopedia of Algorithms* (2016),
[doi:10.1007/978-1-4939-2864-4_585](https://doi.org/10.1007/978-1-4939-2864-4_585),
especially the PM-quadtree section. Only the mathematical construction rule
was consulted; all bounds, boundary conventions, serialization, fixtures,
and ports are clean-room profile choices. See [RIGHTS.md](RIGHTS.md),
[`workload.json`](workload.json), and [`INVENTORY.md`](INVENTORY.md).

## Language ports

- [C](../../../c/p/pmr_edge_quadtree.c)
- [C3](../../../c3/p/pmr_edge_quadtree.c3)
- [C++](../../../cpp/p/pmr_edge_quadtree.cpp)
- [Elisa](../../../elisa/p/pmr_edge_quadtree.elisa)
- [Mojo](../../../mojo/p/pmr_edge_quadtree.mojo)
- [Nim](../../../nim/p/pmr_edge_quadtree.nim)
- [Odin](../../../odin/p/pmr_edge_quadtree.odin)
- [Rust](../../../rust/p/pmr_edge_quadtree.rs)
- [V](../../../v/p/pmr_edge_quadtree.v)
- [Zig](../../../zig/p/pmr_edge_quadtree.zig)
