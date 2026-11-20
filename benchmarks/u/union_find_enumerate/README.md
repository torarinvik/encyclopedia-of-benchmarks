# Union-find with component enumeration

This benchmark maintains a disjoint-set partition and enumerates the members
of a component from any supplied vertex. The primary procedure stores a
circular successor list for each component. A successful union joins two
cycles by swapping the successor links at their roots, while union by size and
path compression maintain the partition. An enumeration walks the component
cycle and returns its membership bitmask.

## Contract

The ABI is `i64_array_scalar`; the exported symbol and package id are
`union_find_enumerate`. Input is `[n,q,(opcode,a,b)*q]`, with `1<=n<=16`,
`0<=q<=32`, and exact length `2+3*q`:

- Opcode `0` unions the components containing `a` and `b`; it observes `1`
  when two components merge and `0` when they were already connected.
- Opcode `1` enumerates the component containing `a` as an `n`-bit membership
  mask; `b` is reserved and must be zero.
- Vertex indices are zero-based. Invalid operations, fields, framing, or a
  null input return `-1`.

For every operation with one-based ordinal `i`, the checksum adds
`i*(observed+1)`. The empty trace returns zero. A component mask is at most
`2^16-1`; the checksum is bounded by `34,603,008` for at most 32 operations.
The maximum valid frame has 98 signed 64-bit words. A 99-word frame made by
appending one value to the maximum valid frame is included and returns `-1`;
the parser accepts up to 99 words before exact-length validation. The two
fixed `i64` arrays use 256 bytes of workspace.

## Algorithm and distinction

The parent array stores negative component sizes at roots. Each vertex also
stores a successor in a circular list. After a successful union by size, the
root successor links are exchanged to splice the two cycles in constant
time. Enumerating from any member follows successors until it returns to the
start, taking time proportional to component size. The primary procedure is
`O(alpha(n))` amortized per union and `O(size(component))` per enumeration.

This extends the local [`union_find`](../union_find/README.md) profile, which
reports connectivity, sizes, and component totals but does not enumerate all
members of a component. It also differs from
[`range_union_find`](../range_union_find/README.md), which uses contiguous
component boundaries to skip already-joined adjacent vertices rather than
maintaining arbitrary component-member cycles. The independent oracle builds
an explicit graph and uses BFS to obtain each component mask.

## Source and rights

The circular member-list method follows the high-level behavior documented
for NyaanNyaan/library's
[`union-find-enumerate.hpp`](https://nyaannyaan.github.io/library/data-structure/union-find-enumerate.hpp.html)
([GitHub source](https://github.com/NyaanNyaan/library/blob/master/data-structure/union-find-enumerate.hpp)).
The upstream repository declares CC0 1.0 Universal in its
[`LICENSE`](https://github.com/NyaanNyaan/library/blob/master/LICENSE). The
ports, references, fixtures, and prose here are original clean-room material;
no upstream code or text is included. See [RIGHTS.md](RIGHTS.md).

[`workload.json`](workload.json) covers nontrivial cycle splicing, union-by-size
root swaps, duplicate unions, singleton and full-universe enumeration, the
maximum valid and parseable frames, and malformed inputs.

## Language ports

| Language | Source |
|---|---|
| C | [`c/u/union_find_enumerate.c`](../../../c/u/union_find_enumerate.c) |
| C3 | [`c3/u/union_find_enumerate.c3`](../../../c3/u/union_find_enumerate.c3) |
| C++ | [`cpp/u/union_find_enumerate.cpp`](../../../cpp/u/union_find_enumerate.cpp) |
| Elisa | [`elisa/u/union_find_enumerate.elisa`](../../../elisa/u/union_find_enumerate.elisa) |
| Mojo | [`mojo/u/union_find_enumerate.mojo`](../../../mojo/u/union_find_enumerate.mojo) |
| Nim | [`nim/u/union_find_enumerate.nim`](../../../nim/u/union_find_enumerate.nim) |
| Odin | [`odin/u/union_find_enumerate.odin`](../../../odin/u/union_find_enumerate.odin) |
| Rust | [`rust/u/union_find_enumerate.rs`](../../../rust/u/union_find_enumerate.rs) |
| V | [`v/u/union_find_enumerate.v`](../../../v/u/union_find_enumerate.v) |
| Zig | [`zig/u/union_find_enumerate.zig`](../../../zig/u/union_find_enumerate.zig) |
