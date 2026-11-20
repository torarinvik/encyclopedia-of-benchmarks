# Tree center by leaf peeling

This benchmark returns the one or two vertices of an unweighted tree whose
maximum distance to any other vertex is minimal. Its primary implementation
repeatedly removes the current leaf layer until at most two vertices remain.
The returned vertex IDs are sorted in ascending order.

## Contract

The `i64_array_bytes_output` symbol is `tree_center`. Input is
`[N,(u,v)...]`, with `1 <= N <= 64` and exactly `N-1` undirected edges.
Endpoints must be distinct, in range, and form a simple connected tree.
Malformed input returns `-1`. A successful result writes one or two
little-endian signed 64-bit center IDs and returns 8 or 16 bytes. A null or
undersized output returns `-2` without writing. The largest valid input has
127 words; the largest output is 16 bytes.

This is distinct from [`tree_diameter`](../tree_diameter/README.md)'s weighted maximum-path
output and from centroid decomposition, which recursively partitions a tree
to balance component sizes. A center minimizes maximum distance; a centroid
balances the sizes of components after removal.

## Workload and references

[`workload.json`](workload.json) includes singleton and two-node trees,
odd/even diameter paths, a star, an asymmetric branching tree, a maximum
path, malformed graph frames, and output-buffer errors. The leaf-peeling
primary reference is in [`primary_oracle.py`](primary_oracle.py). The
independent reference computes every vertex's eccentricity with BFS and
selects the minimum; it is in [`independent_oracle.py`](independent_oracle.py).

The algorithm idea is sourced from William Fiset's
[`TreeCenter.java`](https://github.com/williamfiset/Algorithms/blob/master/src/main/java/com/williamfiset/algorithms/graphtheory/treealgorithms/TreeCenter.java).
The ports implement the standard stop condition of retaining at most two
vertices. They do not copy the Java implementation, prose, or fixtures.
See [`RIGHTS.md`](RIGHTS.md).

## Implementations

| Language | Source |
|---|---|
| C | [`c/t/tree_center.c`](../../../c/t/tree_center.c) |
| C3 | [`c3/t/tree_center.c3`](../../../c3/t/tree_center.c3) |
| C++ | [`cpp/t/tree_center.cpp`](../../../cpp/t/tree_center.cpp) |
| Elisa | [`elisa/t/tree_center.elisa`](../../../elisa/t/tree_center.elisa) |
| Mojo | [`mojo/t/tree_center.mojo`](../../../mojo/t/tree_center.mojo) |
| Nim | [`nim/t/tree_center.nim`](../../../nim/t/tree_center.nim) |
| Odin | [`odin/t/tree_center.odin`](../../../odin/t/tree_center.odin) |
| Rust | [`rust/t/tree_center.rs`](../../../rust/t/tree_center.rs) |
| V | [`v/t/tree_center.v`](../../../v/t/tree_center.v) |
| Zig | [`zig/t/tree_center.zig`](../../../zig/t/tree_center.zig) |

`verify_workload.py` statically checks workload metadata and the ten-port
inventory. The byte-output runner and verifier register the algorithm and its
independent BFS oracle.
