# Slide-window aggregation deque

This benchmark maintains an ordered deque of 2×2 matrices over
`Z/97Z`. It supports pushes and pops at both ends and returns the product of
the current sequence in front-to-back order. The primary procedure stores
end-oriented aggregates in two stacks and rebuilds a balanced split when a
pop reaches an empty side.

## Contract

The ABI is `i64_array_scalar`; the exported symbol and package id are
`slide_window_aggregation_deque`. Input begins with operation count `q`,
`0<=q<=32`, followed by variable-width operation rows:

- `0,a,b,c,d`: push the matrix `[[a,b],[c,d]]` at the front.
- `1,a,b,c,d`: push the matrix at the back.
- `2`: pop the front; invalid when empty.
- `3`: pop the back; invalid when empty.
- `4`: query the complete product. The empty deque's product is the identity.

Matrix entries are in `[0,96]`; multiplication is modulo 97. The returned
matrix is packed as `m00 + 97*m01 + 97^2*m10 + 97^3*m11`. For each query in
one-based query order `i`, the checksum adds `i*(packed_matrix+1)`. A trace
with no query returns zero; malformed input or a pop from an empty deque
returns `-1`. With at most 32 queries, the valid scalar result is bounded by
`32*33/2 * 97^4 = 46,743,460,368`.
The largest valid frame is 161 signed 64-bit words; the parser accepts up to
162 before exact-length validation. Four-field matrix arrays plus the
rebalance array use 5,120 bytes in the uncompressed ports. Mojo stores each
matrix as one base-97 encoded word, reducing those arrays to 1,280 bytes.

## Algorithm and distinctions

The front stack stores its elements from newest front to oldest, with each
aggregate formed as `new_element * previous_front_aggregate`. The back stack
stores elements in deque order and aggregates them as
`previous_back_aggregate * new_element`. A full query combines the two stored
folds. If a pop reaches an empty side, the logical deque is flattened and
split around its midpoint, then both directional aggregates are rebuilt.
Endpoint operations are `O(1)` amortized, a rebalance costs `O(n)`, and a
whole-deque query is `O(1)`.

This is distinct from [`deque_operate_all_composite`](../../d/deque_operate_all_composite/README.md),
which uses a centered sequence and segment tree for affine-map composition;
this profile uses generic matrix multiplication and two aggregate stacks with
midpoint rebuilding. It also differs from
[`sliding_window_aggregator`](../sliding_window_aggregator/README.md), which
only appends to and evicts from a FIFO sum window. The independent oracle
maintains a direct list and folds it from left to right for each query.

## Source and rights

The end-oriented stack aggregates and midpoint rebalance follow the
high-level behavior documented in NyaanNyaan/library's
[`slide-window-aggregation-deque.hpp`](https://nyaannyaan.github.io/library/data-structure/slide-window-aggregation-deque.hpp.html)
([GitHub source](https://github.com/NyaanNyaan/library/blob/master/data-structure/slide-window-aggregation-deque.hpp)).
The upstream repository declares CC0 1.0 Universal in its
[`LICENSE`](https://github.com/NyaanNyaan/library/blob/master/LICENSE). The
ports, references, fixtures, and prose here are clean-room material; no
upstream code or text is included. See [RIGHTS.md](RIGHTS.md).

[`workload.json`](workload.json) covers noncommutative order, pops that trigger
rebalancing from either side, the zero-operation frame, empty-query identity,
maximum frames, and malformed operations. The two rebalancing fixtures have
checksums `2,775,662`
and `2,766,253`, respectively.

## Language ports

| Language | Source |
|---|---|
| C | [`c/s/slide_window_aggregation_deque.c`](../../../c/s/slide_window_aggregation_deque.c) |
| C3 | [`c3/s/slide_window_aggregation_deque.c3`](../../../c3/s/slide_window_aggregation_deque.c3) |
| C++ | [`cpp/s/slide_window_aggregation_deque.cpp`](../../../cpp/s/slide_window_aggregation_deque.cpp) |
| Elisa | [`elisa/s/slide_window_aggregation_deque.elisa`](../../../elisa/s/slide_window_aggregation_deque.elisa) |
| Mojo | [`mojo/s/slide_window_aggregation_deque.mojo`](../../../mojo/s/slide_window_aggregation_deque.mojo) |
| Nim | [`nim/s/slide_window_aggregation_deque.nim`](../../../nim/s/slide_window_aggregation_deque.nim) |
| Odin | [`odin/s/slide_window_aggregation_deque.odin`](../../../odin/s/slide_window_aggregation_deque.odin) |
| Rust | [`rust/s/slide_window_aggregation_deque.rs`](../../../rust/s/slide_window_aggregation_deque.rs) |
| V | [`v/s/slide_window_aggregation_deque.v`](../../../v/s/slide_window_aggregation_deque.v) |
| Zig | [`zig/s/slide_window_aggregation_deque.zig`](../../../zig/s/slide_window_aggregation_deque.zig) |
