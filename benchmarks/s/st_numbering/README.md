# st-numbering

Compute an st-numbering for a simple undirected biconnected graph and a selected edge `(s, t)`. The returned rank sequence places `s` first and `t` last, with every other vertex having a neighbor on both sides of its rank.

## Contract

- Input is `[n, m, s, t, (u, v) * m]`, with `2 <= n <= 8` and `0 <= m <= 28`.
- Vertices are zero-based. The graph must be simple, every endpoint must be in range, and `s` and `t` must be distinct and adjacent.
- The graph must be biconnected. Malformed or non-biconnected inputs return `-1`.
- On success, output has `n` bytes. Byte `v` contains vertex `v`'s rank, from 1 to `n`; `s` has rank 1 and `t` has rank `n`.
- A null output buffer or capacity below `n` returns `-2`. Errors leave output untouched.

The ports use the Even–Tarjan DFS/lowpoint construction. DFS begins at `s` and explores the selected edge to `t` first. The lowpoint values and DFS parents guide each internal vertex's insertion before or after its parent in an order list. An articulation check rejects graphs that cannot have the requested numbering. The linked adjacency and order arrays use `O(n + m)` space; the algorithm takes `O(n + m)` time.

## Provenance

The official [Library Checker problem list](https://judge.yosupo.jp/) classifies st-Numbering under Graph. The mathematical task follows [Even and Tarjan, “Computing an st-numbering”](https://www.sciencedirect.com/science/article/pii/0304397576900864), which gives a linear-time DFS-based construction for a biconnected graph and designated edge. These ports are clean-room implementations of the DFS/lowpoint approach.

The bounded workload includes cycles and complete graphs, nonzero terminals, output errors, and malformed, disconnected, or articulation-point inputs. The package oracle constructs a deterministic numbering; the static checker independently enumerates internal-vertex orders to confirm the st-property on the published fixtures.

## Language ports

| Language | Source |
| --- | --- |
| C | [c/s/st_numbering.c](../../../c/s/st_numbering.c) |
| C3 | [c3/s/st_numbering.c3](../../../c3/s/st_numbering.c3) |
| C++ | [cpp/s/st_numbering.cpp](../../../cpp/s/st_numbering.cpp) |
| Elisa | [elisa/s/st_numbering.elisa](../../../elisa/s/st_numbering.elisa) |
| Nim | [nim/s/st_numbering.nim](../../../nim/s/st_numbering.nim) |
| Odin | [odin/s/st_numbering.odin](../../../odin/s/st_numbering.odin) |
| Rust | [rust/s/st_numbering.rs](../../../rust/s/st_numbering.rs) |
| V | [v/s/st_numbering.v](../../../v/s/st_numbering.v) |
| Zig | [zig/s/st_numbering.zig](../../../zig/s/st_numbering.zig) |

The ABI is `i64_array_bytes_output`, with `st_numbering` as the exported symbol.
