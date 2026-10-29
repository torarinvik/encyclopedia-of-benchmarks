# Link-Cut Tree

This benchmark maintains a dynamic forest with link, cut, and path-sum operations. Its taxonomy follows the [OI Wiki Link-Cut Tree article](https://en.oi-wiki.org/ds/lct/); the implementations here are clean-room ports of the data-structure concepts, not copied submission code.

## Input and output

The input is a signed 64-bit array:

```text
[n, q, weight(0), ..., weight(n-1), (operation, u, v) repeated q times]
```

`1 <= n <= 16`, `1 <= q <= 64`, and each initial vertex weight is in `[0, 1_000_000]`. The array length must equal `2 + n + 3q`. Vertices are zero-based, and the initial forest has no edges. Operation `0` attempts to link two distinct vertices: it returns `1` and adds the edge if they are disconnected, otherwise `0`. Operation `1` cuts the edge `(u,v)`, returning `1` if that exact edge exists and `0` otherwise. Operation `2` returns the sum of vertex weights on the `u`-to-`v` path, or `-1` if the vertices are disconnected. A path from a vertex to itself contains that vertex. Nonnegative weights keep `-1` reserved for the disconnected-query result.

Successful calls emit one signed 64-bit result per operation, in operation order, encoded as little-endian bytes; the function result is the number of bytes written (`8q`). Invalid pointers, malformed framing, out-of-range weights/vertices, or unknown operation codes return `-1`. A null output pointer or insufficient output capacity returns `-2`. The complete input and output capacity are checked before operations begin, so error returns leave the caller's buffer untouched. The bounded workload ensures path sums fit in signed 64-bit values.

## Algorithm and limits

Each port uses a link-cut tree represented by an auxiliary splay forest. Reversal flags support path rerooting; each splay node aggregates the sum of its represented path. `link`, `cut`, and path queries take `O(log n)` amortized time and the structure uses `O(n)` storage. The small limits keep each benchmark call deterministic and bounded while exercising the dynamic-tree operations.

## Language ports

| Language | Source |
| --- | --- |
| C | [c/l/link_cut_tree.c](../../../c/l/link_cut_tree.c) |
| C3 | [c3/l/link_cut_tree.c3](../../../c3/l/link_cut_tree.c3) |
| C++ | [cpp/l/link_cut_tree.cpp](../../../cpp/l/link_cut_tree.cpp) |
| Elisa | [elisa/l/link_cut_tree.elisa](../../../elisa/l/link_cut_tree.elisa) |
| Nim | [nim/l/link_cut_tree.nim](../../../nim/l/link_cut_tree.nim) |
| Odin | [odin/l/link_cut_tree.odin](../../../odin/l/link_cut_tree.odin) |
| Rust | [rust/l/link_cut_tree.rs](../../../rust/l/link_cut_tree.rs) |
| V | [v/l/link_cut_tree.v](../../../v/l/link_cut_tree.v) |
| Zig | [zig/l/link_cut_tree.zig](../../../zig/l/link_cut_tree.zig) |

The independent package oracle uses a plain forest adjacency representation and BFS to resolve connectivity and path sums.
