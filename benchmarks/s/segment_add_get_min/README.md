# Segment Add Get Min

This benchmark maintains the minimum of line segments over integer coordinates.
Its task taxonomy follows [Library Checker: Segment Add Get Min](https://judge.yosupo.jp/problem/segment_add_get_min), whose source specification is available [here](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/data_structure/segment_add_get_min/task.md). The task semantics are used as a reference; the implementations, bounded contract, workload, and oracle are independently written. No statement text or source code was copied.

## Contract

Input is `[N, Q, (l, r, a, b)*N, operations...]`. Each initial segment stores
`y = a*x + b` for integer `x` in `[l,r)`. An update is `0 l r a b`; a query
is `1 p`. Query records are variable length, as in the task. `N` is from 0 to
16, `Q` is from 0 to 32, segment endpoints satisfy `-32 <= l < r <= 32`, and
the queried integer `p` is in `[-32,31]`. Slopes and intercepts are in
`[-1000,1000]`. A query with no covering segment uses the benchmark sentinel
`1,000,000,000,000` for `INFINITY`.

The scalar ABI returns `sum(q * (answer + 33,001))`, where `q` is the
one-based query order. This encodes every query answer deterministically in the
existing `i64_array_scalar` ABI. Invalid framing or values return `-1`. The
input is at most 226 signed 64-bit values.

## Algorithm and oracle

Each segment update decomposes its interval into canonical nodes of an
implicit segment tree. At each fully covered node, a Li Chao insertion keeps
the line that wins at the midpoint and descends the other line only into a
half where it can improve the minimum. Queries inspect the stored lines on
one root-to-leaf path. Parallel and overlapping segments remain separate
insertions. With `U = 64` integer coordinates, insertion costs
`O(log^2 U)`, a point query costs `O(log U)`, and the fixed tree uses `O(U)`
space. Initial segments use the same insertion path as later updates.

The independent oracle scans all active intervals for each query, with
`O(N + Q*I)` work in the bounded workload, where `I` is the number of
segments inserted by the end of the trace. It shares no tree structure with
the measured ports. See [`workload.json`](workload.json), the
[direct-scan oracle](../../segment_add_get_min_oracle.py), and the
[static fixture/source checker](../../verify_segment_add_get_min.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/s/segment_add_get_min.c`](../../../c/s/segment_add_get_min.c) |
| C3 | [`c3/s/segment_add_get_min.c3`](../../../c3/s/segment_add_get_min.c3) |
| C++ | [`cpp/s/segment_add_get_min.cpp`](../../../cpp/s/segment_add_get_min.cpp) |
| Elisa | [`elisa/s/segment_add_get_min.elisa`](../../../elisa/s/segment_add_get_min.elisa) |
| Nim | [`nim/s/segment_add_get_min.nim`](../../../nim/s/segment_add_get_min.nim) |
| Odin | [`odin/s/segment_add_get_min.odin`](../../../odin/s/segment_add_get_min.odin) |
| Rust | [`rust/s/segment_add_get_min.rs`](../../../rust/s/segment_add_get_min.rs) |
| V | [`v/s/segment_add_get_min.v`](../../../v/s/segment_add_get_min.v) |
| Zig | [`zig/s/segment_add_get_min.zig`](../../../zig/s/segment_add_get_min.zig) |
