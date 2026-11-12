# Static rectangle add, rectangle sum

This profile begins with a zero-valued coordinate plane, applies all weighted
rectangle additions, and then answers a batch of rectangle-sum queries modulo
998244353. All rectangles use half-open bounds.

## Contract

The `i64_array_bytes_output` input is
`[N,Q,(left,down,right,up,weight)*N,(left,down,right,up)*Q]`. Local bounds are
`1<=N<=32`, `0<=Q<=32`, coordinates are in `[0,1,000,000]`, rectangle bounds
have positive width and height, and weights are in `[0,998244352]`. The maximum
valid frame has 290 words; one extra word is parseable and rejected. Successful
calls return one signed 64-bit little-endian residue per query. The output is
at most 256 bytes. Malformed input returns `-1`; null output or insufficient
capacity returns `-2`, with no writes on errors.

## Algorithm and distinctness

The ports collect and compress every x/y boundary from both phases. Each
rectangle update contributes four signed corner events to a two-dimensional
difference grid. A prefix pass recovers the constant value in each compressed
cell. The ports multiply each cell value by its geometric area, build a
modular two-dimensional prefix table, then answer each query by four prefix
lookups. Values are reduced modulo 998244353 before area products, keeping all
intermediate products within signed 64-bit range. The bounded grid has at most
128 boundaries per axis; workspace is fixed at 524,288 bytes.

This is distinct from `prefix_sum2_d`, which queries a fixed dense input matrix;
`segment_tree2_d`, which point-assigns dense cells; `point_add_rectangle_sum`,
which appends sparse points and queries rectangles; and
`rectangle_add_point_get`, which appends rectangles but queries individual
points. This task's updates are all processed before its rectangle-sum queries.

The official [Library Checker task](https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/static_rectangle_add_rectangle_sum/task.md)
allows up to 200,000 updates and queries and returns sums modulo 998244353.
The local caps preserve those operation semantics while keeping the compressed
tables fixed. The primary oracle sums each update's geometric overlap with a
query; the independent verifier scans the induced coordinate cells.

## Workload, rights, and implementations

[`workload.json`](workload.json) covers overlaps, shared boundaries, modular
wraparound, empty query batches, invalid rectangles, and output errors.
[`RIGHTS.md`](RIGHTS.md) records source attribution and the Apache-2.0 terms.
The implementations are clean-room ports of the operation contract.

| Language | Source |
|---|---|
| C | [`c/s/static_rectangle_add_rectangle_sum.c`](../../../c/s/static_rectangle_add_rectangle_sum.c) |
| C3 | [`c3/s/static_rectangle_add_rectangle_sum.c3`](../../../c3/s/static_rectangle_add_rectangle_sum.c3) |
| C++ | [`cpp/s/static_rectangle_add_rectangle_sum.cpp`](../../../cpp/s/static_rectangle_add_rectangle_sum.cpp) |
| Elisa | [`elisa/s/static_rectangle_add_rectangle_sum.elisa`](../../../elisa/s/static_rectangle_add_rectangle_sum.elisa) |
| Mojo | [`mojo/s/static_rectangle_add_rectangle_sum.mojo`](../../../mojo/s/static_rectangle_add_rectangle_sum.mojo) |
| Nim | [`nim/s/static_rectangle_add_rectangle_sum.nim`](../../../nim/s/static_rectangle_add_rectangle_sum.nim) |
| Odin | [`odin/s/static_rectangle_add_rectangle_sum.odin`](../../../odin/s/static_rectangle_add_rectangle_sum.odin) |
| Rust | [`rust/s/static_rectangle_add_rectangle_sum.rs`](../../../rust/s/static_rectangle_add_rectangle_sum.rs) |
| V | [`v/s/static_rectangle_add_rectangle_sum.v`](../../../v/s/static_rectangle_add_rectangle_sum.v) |
| Zig | [`zig/s/static_rectangle_add_rectangle_sum.zig`](../../../zig/s/static_rectangle_add_rectangle_sum.zig) |

Primary oracle: [`static_rectangle_add_rectangle_sum_oracle.py`](../../static_rectangle_add_rectangle_sum_oracle.py).
Independent verifier oracle: [`static_rectangle_add_rectangle_sum_verifier_oracle.py`](../../static_rectangle_add_rectangle_sum_verifier_oracle.py).
