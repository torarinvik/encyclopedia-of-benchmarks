# Point set tree path composite sum with fixed root

Maintain vertex values and edge affine maps on a tree rooted at vertex 0. After
each update, return the sum of the values at all vertices, where a vertex value
is obtained by starting with its own value and composing the maps along its
root path. The edge nearest the root is the outermost map. This is a dynamic
rooted-tree aggregate with two update types; it differs from the local
`tree_path_composite_sum`, which performs static all-root rerooting.

## Bounded contract

The `i64_array_bytes_output` entry point is
`point_set_tree_path_composite_sum_fixed_root(input, length, output, capacity)`.
Input is `[N,Q,A..., (u,v,b,c)..., updates...]`, with `1<=N<=16` and
`1<=Q<=32`. Vertex values and affine addends are residues in `[0,998244353)`;
edge multipliers are in `[1,998244353)`. Updates are `[0,w,x]` for replacing a
vertex value and `[1,e,y,z]` for replacing an edge map `t -> y*t+z`. The profile
is intentionally small relative to the official `N,Q<=200000` limits while
retaining both update types and light-chain propagation.

Each valid update emits one little-endian signed 64-bit residue, so success
returns `8*Q` bytes. Malformed input or a non-tree returns `-1`; a null or
undersized output returns `-2`. The oracle harness also rejects malformed or
negative capacity metadata as invalid. Errors leave output unchanged. The
maximum input length is 206 words, maximum output is 256 bytes, and fixed
workspace is 8192 bytes.

## Algorithm and workload

The implementation roots the tree at 0 and uses heavy-light decomposition.
For each vertex, it stores an affine transform from the heavy child's subtree
aggregate to its own, folding contributions from light children into the
intercept. A segment tree composes transforms in top-to-bottom order. Point
updates recompute the affected chain head and propagate changes over light
edges; each update takes `O(log^2 N)` time. The bounded preprocessing scans a
dense adjacency table in `O(N^2)` time.

The primary oracle uses the same HLD and affine segment-tree method. The
independent oracle recomputes every rooted subtree aggregate by a postorder
recurrence after each update. The fixtures cover singleton and two-vertex
trees, balanced-tree light-chain propagation, malformed trees and frames, and
output-buffer errors. [`workload.json`](workload.json) records the cases and
the output/workspace bounds. [`verify_workload.py`](verify_workload.py) is a
static inventory and dual-oracle checker; it is included for later review and
has not been run.

## Provenance and rights

The operation, root convention, modulus, and official limits are recorded in
the Library Checker
[task](https://github.com/yosupo06/library-checker-problems/blob/master/tree/point_set_tree_path_composite_sum_fixed_root/task.md)
and [limits file](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/tree/point_set_tree_path_composite_sum_fixed_root/info.toml).
The upstream repository declares Apache-2.0. The implementations, bounded
profile, workload, oracles, and prose are independently written from the
operation contract; no upstream code or generated tests are reused. See
[`RIGHTS.md`](RIGHTS.md).

## Implementations

| Language | Source |
|---|---|
| C | [`c/p/point_set_tree_path_composite_sum_fixed_root.c`](../../../c/p/point_set_tree_path_composite_sum_fixed_root.c) |
| C3 | [`c3/p/point_set_tree_path_composite_sum_fixed_root.c3`](../../../c3/p/point_set_tree_path_composite_sum_fixed_root.c3) |
| C++ | [`cpp/p/point_set_tree_path_composite_sum_fixed_root.cpp`](../../../cpp/p/point_set_tree_path_composite_sum_fixed_root.cpp) |
| Elisa | [`elisa/p/point_set_tree_path_composite_sum_fixed_root.elisa`](../../../elisa/p/point_set_tree_path_composite_sum_fixed_root.elisa) |
| Mojo | [`mojo/p/point_set_tree_path_composite_sum_fixed_root.mojo`](../../../mojo/p/point_set_tree_path_composite_sum_fixed_root.mojo) |
| Nim | [`nim/p/point_set_tree_path_composite_sum_fixed_root.nim`](../../../nim/p/point_set_tree_path_composite_sum_fixed_root.nim) |
| Odin | [`odin/p/point_set_tree_path_composite_sum_fixed_root.odin`](../../../odin/p/point_set_tree_path_composite_sum_fixed_root.odin) |
| Rust | [`rust/p/point_set_tree_path_composite_sum_fixed_root.rs`](../../../rust/p/point_set_tree_path_composite_sum_fixed_root.rs) |
| V | [`v/p/point_set_tree_path_composite_sum_fixed_root.v`](../../../v/p/point_set_tree_path_composite_sum_fixed_root.v) |
| Zig | [`zig/p/point_set_tree_path_composite_sum_fixed_root.zig`](../../../zig/p/point_set_tree_path_composite_sum_fixed_root.zig) |

Root owns shared suite registration and benchmark-corpus wiring.
