# Range-parallel union-find

This benchmark adds aligned batches of edges and reports a component-weighted
pair sum after every batch. The data structure keeps a disjoint-set structure
for each power-of-two block length. Merging two equal-length ranges skips
already-equivalent blocks and descends only into new block pairs; individual
vertex unions update the pair-sum accumulator.

## Contract

The official input provides `N` weights `x[i]` modulo `998244353`, then `Q`
queries `(k,a,b)`. A query adds all undirected edges `(a+i,b+i)` for
`0 <= i < k`. After each query, emit
`sum(x[i]*x[j] for i<j in the same connected component) mod 998244353`.

The bounded ABI uses `[N,Q,x_0,...,x_(N-1),(k,a,b)...]`, with `1 <= N <= 64`
and `1 <= Q <= 64`. Weights satisfy `0 <= x[i] < MOD`; each query satisfies
`0 <= k <= N` and `0 <= a,b <= N-k`. A zero-length range is valid and changes
no edges. Invalid input returns `-1`. Successful calls write one signed
64-bit little-endian result per query and return the number of bytes written.
A null or undersized output buffer returns `-2` without writing.

There are six block levels for the profile. A range merge decomposes into at
most two largest-power-of-two blocks. If a block pair is new, the data
structure records the equivalence and recursively processes its two halves.
At level zero, union-by-size merges connected components and adds the product
of their accumulated weights to the answer. The profile uses bounded local
arrays; it has no historical-version queries.

## Distinctness

The local [`union_find`](../union_find/README.md) package handles single vertex
unions and connectivity; it has no range-aligned parallel union operation or
component-weight pair aggregate. The existing persistent segment-tree
packages persist range values, not connectivity partitions. This workload
applies all updates to one graph state and does not query old versions.

Official contract: [Library Checker — Range Parallel Unionfind](https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/range_parallel_unionfind/task.md)
with limits from its [info.toml](https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/range_parallel_unionfind/info.toml).

## Workload and oracle

[`workload.json`](workload.json) covers single and overlapping range batches,
zero-length updates, invalid ranges and weights, and output-capacity errors.
The independent [`benchmarks/range_parallel_unionfind_oracle.py`](../../range_parallel_unionfind_oracle.py)
adds explicit graph edges and recomputes components by traversal after every
query.

## Implementations

| Language | Port |
|---|---|
| C | [`c/u/range_parallel_unionfind.c`](../../../c/u/range_parallel_unionfind.c) |
| C3 | [`c3/u/range_parallel_unionfind.c3`](../../../c3/u/range_parallel_unionfind.c3) |
| C++ | [`cpp/u/range_parallel_unionfind.cpp`](../../../cpp/u/range_parallel_unionfind.cpp) |
| Elisa | [`elisa/u/range_parallel_unionfind.elisa`](../../../elisa/u/range_parallel_unionfind.elisa) |
| Nim | [`nim/u/range_parallel_unionfind.nim`](../../../nim/u/range_parallel_unionfind.nim) |
| Odin | [`odin/u/range_parallel_unionfind.odin`](../../../odin/u/range_parallel_unionfind.odin) |
| Rust | [`rust/u/range_parallel_unionfind.rs`](../../../rust/u/range_parallel_unionfind.rs) |
| V | [`v/u/range_parallel_unionfind.v`](../../../v/u/range_parallel_unionfind.v) |
| Zig | [`zig/u/range_parallel_unionfind.zig`](../../../zig/u/range_parallel_unionfind.zig) |
| Mojo | [`mojo/u/range_parallel_unionfind.mojo`](../../../mojo/u/range_parallel_unionfind.mojo) |
