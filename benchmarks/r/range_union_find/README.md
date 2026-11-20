# Range union-find

This profile supports operations that merge every consecutive vertex in a
half-open interval `[a,b)`, query connectivity, and report a component size.
Every component is a contiguous interval because the only updates add edges
between consecutive vertices. Each DSU root stores that component's
exclusive right boundary. For a range union, the root containing `a` points
to the next component at its right boundary; merging repeats until that
boundary reaches `b`, skipping boundaries already covered by earlier range
unions.

## Contract

ABI: `i64_array_scalar`, exported symbol `range_union_find`. Input is
`[n,q,(opcode,a,b)*q]`, with `1 <= n <= 32`, `0 <= q <= 32`, and exactly
`2+3*q` signed 64-bit words. Opcode `0` unites the consecutive vertices in
`[a,b)` and returns the current component count (`0 <= a <= b <= n`). The
range adds edges `(i,i+1)` for `a <= i < b-1`. Empty and single-vertex ranges
are valid no-ops. Opcode `1` returns `1` or `0` for connectivity of vertices
`a,b`, both in `0..n-1`. Opcode `2` returns the size of vertex `a`'s
component and requires `b=0`. Other opcodes and malformed fields return
`-1`.

The scalar result is the sum of each observed operation value multiplied by
its one-based operation index. The maximum valid frame is 98 words; the
parser accepts up to 99 words to reject an extra trailing value explicitly.
The result is bounded by `16,896`. The primary implements Nyaan's
right-boundary component invariant with union by size and path compression.
Each adjacency boundary is merged at most once, for
`O((n+q) alpha(n))` amortized work. The independent oracle constructs the
explicit adjacency graph and recomputes components by BFS.

This operation set differs from pairwise `union_find`, which only accepts
individual vertex pairs, and from `range_parallel_unionfind`, which covers
aligned block-pair updates. Here each update connects every adjacent pair in
one contiguous vertex interval, and the root's exclusive right boundary
skips already-connected components.

## Provenance and rights

The range-union method is identified from Nyaan's
[range-union-find.hpp](https://github.com/NyaanNyaan/library/blob/master/data-structure/range-union-find.hpp).
The repository's [LICENSE](https://github.com/NyaanNyaan/library/blob/master/LICENSE)
is CC0 1.0. This package uses the high-level component-boundary algorithm
description only; the code, tests, fixtures, and text here were independently
written. See [RIGHTS.md](RIGHTS.md).

## Workload and references

[`workload.json`](workload.json) includes overlapping ranges, empty and
single-vertex no-ops, connectivity and size queries, maximum valid and
maximum parseable malformed frames, and invalid operations. The primary
right-boundary DSU reference is [primary_oracle.py](primary_oracle.py); the
independent explicit-graph reference is
[independent_oracle.py](independent_oracle.py). The callable
`validate_inventory(workload)` in [verify_workload.py](verify_workload.py)
checks package inventory, ten exported symbols, README links, and fixture
results against both references. It has not been run.

| Language | Source |
|---|---|
| C | [c/r/range_union_find.c](../../../c/r/range_union_find.c) |
| C3 | [c3/r/range_union_find.c3](../../../c3/r/range_union_find.c3) |
| C++ | [cpp/r/range_union_find.cpp](../../../cpp/r/range_union_find.cpp) |
| Elisa | [elisa/r/range_union_find.elisa](../../../elisa/r/range_union_find.elisa) |
| Mojo | [mojo/r/range_union_find.mojo](../../../mojo/r/range_union_find.mojo) |
| Nim | [nim/r/range_union_find.nim](../../../nim/r/range_union_find.nim) |
| Odin | [odin/r/range_union_find.odin](../../../odin/r/range_union_find.odin) |
| Rust | [rust/r/range_union_find.rs](../../../rust/r/range_union_find.rs) |
| V | [v/r/range_union_find.v](../../../v/r/range_union_find.v) |
| Zig | [zig/r/range_union_find.zig](../../../zig/r/range_union_find.zig) |
