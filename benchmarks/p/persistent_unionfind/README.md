# Persistent union-find

This benchmark processes a branching history of graph updates and connectivity
queries. An update creates a graph version by adding one edge to an earlier
update version. A query asks whether two vertices are connected in any earlier
version. Query records do not create graph versions and cannot be used as
parents.

## Contract

The official input is `N Q`, followed by `Q` records `(t,k,u,v)`. Record `i`
has `t` in `{0,1}`, `-1 <= k < i`, and valid vertex indices. If `k >= 0`, its
record must be an update (`t_k=0`). For `t=0`, create version `G_i` from
`G_k` by adding edge `(u,v)`. For `t=1`, output whether `u` and `v` are
connected in `G_k`.

The bounded ABI uses `[N,Q,(t,k,u,v)...]`, with `1 <= N,Q <= 64`. A rollback
DSU with union by size traverses the version tree. Each update records enough
state to undo its union after its descendants have been visited. Path
compression is omitted so rollback remains constant-time per successful
union. Queries save their answers by input index; the output pass then emits
them in original query order.

Successful calls write one signed 64-bit little-endian `0` or `1` for each
type-1 record, returning the number of bytes written. Invalid input returns
`-1`. A null or undersized output buffer returns `-2` without writing. The
bounded profile uses at most 258 input integers and 512 output bytes; local
DSU/version-tree storage is separate from the output-capacity field.

## Distinctness

The ordinary [`union_find`](../../u/union_find/README.md) benchmark processes one
mutable history and has no queries against older branches. The local persistent
segment-tree packages preserve range values, not connectivity partitions.
This candidate adds edges to a selected historical graph version and branches
the update history, so it measures rollback DSU traversal over a version tree.

Official contract: [Library Checker — Persistent Unionfind](https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/persistent_unionfind/task.md)
with limits from its [info.toml](https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/persistent_unionfind/info.toml).

## Workload and oracle

[`workload.json`](workload.json) covers queries against the empty graph,
branching updates, a redundant union, invalid historical references, invalid
records, and insufficient output capacity. The independent
[`benchmarks/persistent_unionfind_oracle.py`](../../persistent_unionfind_oracle.py)
copies explicit edge lists for update versions and uses graph traversal for
connectivity queries.

## Implementations

| Language | Port |
|---|---|
| C | [`c/p/persistent_unionfind.c`](../../../c/p/persistent_unionfind.c) |
| C3 | [`c3/p/persistent_unionfind.c3`](../../../c3/p/persistent_unionfind.c3) |
| C++ | [`cpp/p/persistent_unionfind.cpp`](../../../cpp/p/persistent_unionfind.cpp) |
| Elisa | [`elisa/p/persistent_unionfind.elisa`](../../../elisa/p/persistent_unionfind.elisa) |
| Nim | [`nim/p/persistent_unionfind.nim`](../../../nim/p/persistent_unionfind.nim) |
| Odin | [`odin/p/persistent_unionfind.odin`](../../../odin/p/persistent_unionfind.odin) |
| Rust | [`rust/p/persistent_unionfind.rs`](../../../rust/p/persistent_unionfind.rs) |
| V | [`v/p/persistent_unionfind.v`](../../../v/p/persistent_unionfind.v) |
| Zig | [`zig/p/persistent_unionfind.zig`](../../../zig/p/persistent_unionfind.zig) |
| Mojo | [`mojo/p/persistent_unionfind.mojo`](../../../mojo/p/persistent_unionfind.mojo) |
