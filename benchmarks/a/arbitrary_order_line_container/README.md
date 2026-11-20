# Arbitrary-order line container

This benchmark maintains a minimum or maximum envelope of lines
`y = slope*x + intercept`. Lines may arrive in any slope order, queries may
visit coordinates in any order, and parallel lines are supported. The bounded
ports follow the behavior of NyaanNyaan's `LineContainer`: keep lines ordered
by transformed slope, record integer intersection breakpoints, prune lines
whose active interval disappears, and locate a query line by binary search on
breakpoints.

## Contract

The ABI is `i64_array_scalar`; the exported symbol and package id are
`arbitrary_order_line_container`. Input is
`[objective,q,(opcode,a,b)*q]`, with exact length `2+3*q` and `0<=q<=32`:

- Objective `0` requests a minimum; objective `1` requests a maximum.
- `[0,slope,intercept]` inserts a line. Both coefficients are in `[-1000,1000]`.
- `[1,x,0]` queries the current envelope at `x` in `[-1000,1000]`. The final
  field is reserved and must be zero. A query requires an earlier insertion.
- Duplicate slopes keep only the line that dominates for the selected
  objective. Equal duplicates coalesce.
- The result is `sum((i+1)*(extremum_i+2,000,001))`, where `i` is the
  zero-based query order. No queries returns zero; malformed or null input
  returns `-1`.

The full line value is within `[-1,001,000,1,001,000]`. With at most 31
queries in a 32-operation trace, the checksum is in
`[0,1,488,496,496]`.
The largest valid frame is 98 signed 64-bit words; the parser permits up to 99
before exact-length validation.

## Algorithm and distinctions

For maximum queries, the ports store lines by increasing slope. Each line's
integer breakpoint is the greatest integer coordinate where it remains the
chosen line. Intersections use floor division, so ties at an integer crossing
stay with the lower transformed slope. Insertion repairs neighboring
breakpoints and removes any lines with empty active intervals. A query finds
the first breakpoint not less than `x` in `O(log I)` time. The bounded
array-based insertion shifts at most 32 records and takes `O(I)` time.
Minimum mode negates inserted slope and intercept, runs the same maximum
envelope procedure, then negates the answer.

This is distinct from [`li_chao_tree`](../../l/li_chao_tree/README.md), which
routes each line through a segment tree over a fixed coordinate domain and
does not order the active envelope by slope breakpoints. It is also distinct
from [`monotone_convex_hull_trick`](../../m/monotone_convex_hull_trick/README.md),
which requires slopes and queries to arrive in monotone order and uses a deque.

The primary oracle uses the bounded breakpoint container. The independent
oracle retains every inserted line and scans all lines at each query.
[`workload.json`](workload.json) covers both objectives, arbitrary insertion
and query orders, duplicate slopes, exact-integer and half-integer crossings,
frame bounds, and malformed traces.

## Source and rights

The algorithm behavior follows NyaanNyaan's
[`line-container.hpp`](https://github.com/NyaanNyaan/library/blob/master/data-structure/line-container.hpp)
and its [`CC0 license`](https://github.com/NyaanNyaan/library/blob/master/LICENSE).
The ports, references, and workload are clean-room implementations from the
published behavior; no source code, prose, tests, or fixtures were copied.
See [RIGHTS.md](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [`c/a/arbitrary_order_line_container.c`](../../../c/a/arbitrary_order_line_container.c) |
| C3 | [`c3/a/arbitrary_order_line_container.c3`](../../../c3/a/arbitrary_order_line_container.c3) |
| C++ | [`cpp/a/arbitrary_order_line_container.cpp`](../../../cpp/a/arbitrary_order_line_container.cpp) |
| Elisa | [`elisa/a/arbitrary_order_line_container.elisa`](../../../elisa/a/arbitrary_order_line_container.elisa) |
| Mojo | [`mojo/a/arbitrary_order_line_container.mojo`](../../../mojo/a/arbitrary_order_line_container.mojo) |
| Nim | [`nim/a/arbitrary_order_line_container.nim`](../../../nim/a/arbitrary_order_line_container.nim) |
| Odin | [`odin/a/arbitrary_order_line_container.odin`](../../../odin/a/arbitrary_order_line_container.odin) |
| Rust | [`rust/a/arbitrary_order_line_container.rs`](../../../rust/a/arbitrary_order_line_container.rs) |
| V | [`v/a/arbitrary_order_line_container.v`](../../../v/a/arbitrary_order_line_container.v) |
| Zig | [`zig/a/arbitrary_order_line_container.zig`](../../../zig/a/arbitrary_order_line_container.zig) |
