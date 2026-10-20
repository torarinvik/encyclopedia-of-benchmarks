# Batch-dynamic k-d tree

This bounded workload exercises the update/query pattern of ParGeo's
batch-dynamic k-d tree (BDL-tree), which uses logarithmically sized static
components. It starts with a small point set, applies batches of insertions or
deletions, then performs one exact 1-nearest-neighbor query after each batch.
Insertions carry through occupied logarithmic levels; deletions mark points
inactive (tombstones) until a later carry rebuilds a component. Each occupied
component is queried through a bounded static k-d tree with exact bounding-box
branch-and-bound for 1-NN. Tree construction partitions by alternating axes
with deterministic coordinate/ID tie ordering; inactive tombstones remain in
component boxes but are ignored as candidates. The bounded ports rebuild these
compact trees for each query, excluding ParGeo's parallel rebuild and
multi-neighbor machinery.

This operation is distinct from [`kdtree`](../kdtree/README.md), which runs
single-point insertions and several point queries on one median-built tree,
and [`k_d_tree`](../k_d_tree/README.md), which builds a static floating-point
tree for one nearest-neighbor query. Here the workload explicitly interleaves
whole update batches and post-update nearest queries.

## Contract

The `i64_array_bytes_output` entry point is `batch_dynamic_kd_tree`. Input is
`[initial_count, (id,x,y)*, batch_count, batch...]`. Each batch begins with
`kind,count`; kind `0` carries `count` inserted `(id,x,y)` records, while kind
`1` carries `count` deleted IDs. Every batch ends with a query point `(qx,qy)`.
The query runs after the entire batch has been applied. IDs range from 0 to
31 and cannot be reused during one call. Coordinates are integers in
`[-1000,1000]`. Active points must have distinct coordinates. Initial count is
0 through 8; there are 1 through 8 batches, each with 1 through 8 updates;
there are at most 32 inserted IDs over the full trace. Deletes must refer to
distinct active IDs. Every post-batch query requires a nonempty active set.

One signed 64-bit little-endian squared distance to the nearest active point
is returned per batch (ties have the same distance result). The output is
exactly `8*batch_count` bytes, at most 64. Invalid input returns `-1` before
output checks. Null output or a capacity below the exact result size returns
`-2` without writing. Success returns the byte count.

The independent [`batch_dynamic_kd_tree_oracle.py`](../../batch_dynamic_kd_tree_oracle.py)
applies batches to a simple active-point set and computes each nearest distance
by exhaustive scan. [`workload.json`](workload.json) defines fixtures and
strict frame bounds.

## Pinned source and license

The BDL-tree operation is pinned to ParGeo commit
`4911408762c46b7c262f6d617d7adcb0cb0f219b`: [`logtree.h`](https://github.com/ParAlg/ParGeo/blob/4911408762c46b7c262f6d617d7adcb0cb0f219b/include/batchKdtree/log-tree/logtree.h)
implements logarithmic static-tree levels and batch insertion, while
[`kdtree.h`](https://github.com/ParAlg/ParGeo/blob/4911408762c46b7c262f6d617d7adcb0cb0f219b/include/batchKdtree/shared/kdtree.h)
provides the static k-d-tree and query operations. The example batch workload
is in [`batchKdTree.cpp`](https://github.com/ParAlg/ParGeo/blob/4911408762c46b7c262f6d617d7adcb0cb0f219b/example/batchKdTree.cpp).
The source is MIT-licensed; the full notice and source copyright attribution
are bundled in [`LICENSE.txt`](LICENSE.txt).

## Ports

| Language | Port |
|---|---|
| C | [`c/b/batch_dynamic_kd_tree.c`](../../../c/b/batch_dynamic_kd_tree.c) |
| C3 | [`c3/b/batch_dynamic_kd_tree.c3`](../../../c3/b/batch_dynamic_kd_tree.c3) |
| C++ | [`cpp/b/batch_dynamic_kd_tree.cpp`](../../../cpp/b/batch_dynamic_kd_tree.cpp) |
| Elisa | [`elisa/b/batch_dynamic_kd_tree.elisa`](../../../elisa/b/batch_dynamic_kd_tree.elisa) |
| Nim | [`nim/b/batch_dynamic_kd_tree.nim`](../../../nim/b/batch_dynamic_kd_tree.nim) |
| Odin | [`odin/b/batch_dynamic_kd_tree.odin`](../../../odin/b/batch_dynamic_kd_tree.odin) |
| Rust | [`rust/b/batch_dynamic_kd_tree.rs`](../../../rust/b/batch_dynamic_kd_tree.rs) |
| V | [`v/b/batch_dynamic_kd_tree.v`](../../../v/b/batch_dynamic_kd_tree.v) |
| Zig | [`zig/b/batch_dynamic_kd_tree.zig`](../../../zig/b/batch_dynamic_kd_tree.zig) |
