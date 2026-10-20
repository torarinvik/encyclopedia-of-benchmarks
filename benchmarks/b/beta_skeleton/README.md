# Beta skeleton

This package builds the planar beta=2 lune-based skeleton. For every pair of
distinct input points `p_i`, `p_j`, let `d²` be their squared Euclidean
distance. The undirected edge `(i,j)` is present exactly when no third point
`p_k` satisfies both `|p_k-p_i|² < d²` and `|p_k-p_j|² < d²`. The strict
inequalities make points on either circle boundary non-blocking. This is its
own lune emptiness rule; it is not a Delaunay triangulation or a filtered
Delaunay edge set.

## Contract

The exported `beta_skeleton` entry point uses `i64_array_bytes_output`. Input
is `[n, x_0, y_0, ..., x_(n-1), y_(n-1)]`. `n` is 1 through 32; coordinates
are integers in `[-1000,1000]`; duplicate coordinates are invalid. The output
is a lexicographically ordered sequence of undirected edges, each encoded as
two unsigned endpoint-index bytes `(i,j)` with `i<j`. Thus its size is twice
the number of edges, at most 992 bytes. Invalid input returns `-1` before
checking output storage. Null output or capacity below the exact result size
returns `-2` without writing; success returns the byte count. A valid
one-point input has an empty graph and returns zero.

All geometry predicates use exact integer squared distances. The independent
[`beta_skeleton_oracle.py`](../../beta_skeleton_oracle.py) directly checks all
point pairs and all possible blockers. [`workload.json`](workload.json)
contains line, square, empty, boundary, and malformed cases.

## Pinned source and license

The graph is based on ParGeo's beta-skeleton operation in
[`src/spatialGraph/betaSkeleton/betaSkeleton.cpp`](https://github.com/ParAlg/ParGeo/blob/4911408762c46b7c262f6d617d7adcb0cb0f219b/src/spatialGraph/betaSkeleton/betaSkeleton.cpp),
pinned at commit `4911408762c46b7c262f6d617d7adcb0cb0f219b`. ParGeo describes
its lune-based beta skeleton in the project
[README](https://github.com/ParAlg/ParGeo/blob/4911408762c46b7c262f6d617d7adcb0cb0f219b/README.md).
These bounded ports use the same beta=2 lune rule with exact integer
predicates and a direct pair scan rather than ParGeo's Delaunay/KD-tree
acceleration. The pinned repository uses the MIT License; the complete notice
is bundled in [`LICENSE.txt`](LICENSE.txt).

## Ports

| Language | Port |
|---|---|
| C | [`c/b/beta_skeleton.c`](../../../c/b/beta_skeleton.c) |
| C3 | [`c3/b/beta_skeleton.c3`](../../../c3/b/beta_skeleton.c3) |
| C++ | [`cpp/b/beta_skeleton.cpp`](../../../cpp/b/beta_skeleton.cpp) |
| Elisa | [`elisa/b/beta_skeleton.elisa`](../../../elisa/b/beta_skeleton.elisa) |
| Nim | [`nim/b/beta_skeleton.nim`](../../../nim/b/beta_skeleton.nim) |
| Odin | [`odin/b/beta_skeleton.odin`](../../../odin/b/beta_skeleton.odin) |
| Rust | [`rust/b/beta_skeleton.rs`](../../../rust/b/beta_skeleton.rs) |
| V | [`v/b/beta_skeleton.v`](../../../v/b/beta_skeleton.v) |
| Zig | [`zig/b/beta_skeleton.zig`](../../../zig/b/beta_skeleton.zig) |
