# 2D Mo rectangle frequency-square queries

This profile schedules static submatrix queries by all four rectangle
boundaries using two-dimensional Mo ordering. For each query it computes the
sum of squared frequencies of the matrix's eight possible values, then weights
that result by the query's original one-based index. It is distinct from the
existing one-dimensional Mo workload, which moves only two range endpoints.

## Contract

The exported scalar symbol is `mo_2d_rectangle_frequency_square`. Input is
`[N,Q,matrix[N*N],(top,left,bottom,right)*Q]`, with `1<=N<=8`, `0<=Q<=32`,
matrix values in `[0,7]`, and zero-based inclusive rectangles satisfying
`top<=bottom` and `left<=right`. The exact length is `2+N*N+4Q`; maximum valid
and parseable lengths are 194 and 195 i64 values. Invalid input returns `-1`.

For `Q>0`, choose the greatest block size `B` in `[1,N]` satisfying
`Q*B^4<=N^4` (use `B=1` if none exists). Sort by
`(top/B,left/B,bottom/B,right/B,top,left,bottom,right,original_index)`. Start
from the first sorted rectangle, then move its four boundaries to each next
query. Adding a cell with old value frequency `f` changes the running sum of
squares by `2f+1`; removing it changes the sum by `1-2f`. The primary answers
all sorted queries from that maintained state and restores original query
weights. The independent oracle scans each requested rectangle directly.
The language ports use insertion sort for their at most 32 queries, so primary
worst-case time is `O(N^2+Q^2+Q N^2)` and space is `O(N^2+Q)`;
the bounded profile emphasizes the four-boundary movement schedule.

The maximum checksum is `2,162,688`, attained by 32 full-matrix queries over
an 8x8 matrix of one repeated value.

## Provenance and rights

The 2D Mo ordering follows the algorithmic idea described by OI Wiki's
[two-dimensional Mo algorithm](https://oi-wiki.org/misc/mo-algo-2dimen/).
The source page is licensed CC BY-SA 4.0 and carries its stated SATA notice.
This package uses the scheduling idea only; contract, fixtures, oracles, and
language ports are independently written, with no source code or prose copied.
See [`RIGHTS.md`](RIGHTS.md), [`workload.json`](workload.json), the
[movement-scheduling oracle](../../mo_2d_rectangle_frequency_square_oracle.py),
the [direct-scan verifier](../../mo_2d_rectangle_frequency_square_verifier_oracle.py),
and [static package inventory](../../check_mo_2d_rectangle_frequency_square_package.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/m/mo_2d_rectangle_frequency_square.c`](../../../c/m/mo_2d_rectangle_frequency_square.c) |
| C3 | [`c3/m/mo_2d_rectangle_frequency_square.c3`](../../../c3/m/mo_2d_rectangle_frequency_square.c3) |
| C++ | [`cpp/m/mo_2d_rectangle_frequency_square.cpp`](../../../cpp/m/mo_2d_rectangle_frequency_square.cpp) |
| Elisa | [`elisa/m/mo_2d_rectangle_frequency_square.elisa`](../../../elisa/m/mo_2d_rectangle_frequency_square.elisa) |
| Mojo | [`mojo/m/mo_2d_rectangle_frequency_square.mojo`](../../../mojo/m/mo_2d_rectangle_frequency_square.mojo) |
| Nim | [`nim/m/mo_2d_rectangle_frequency_square.nim`](../../../nim/m/mo_2d_rectangle_frequency_square.nim) |
| Odin | [`odin/m/mo_2d_rectangle_frequency_square.odin`](../../../odin/m/mo_2d_rectangle_frequency_square.odin) |
| Rust | [`rust/m/mo_2d_rectangle_frequency_square.rs`](../../../rust/m/mo_2d_rectangle_frequency_square.rs) |
| V | [`v/m/mo_2d_rectangle_frequency_square.v`](../../../v/m/mo_2d_rectangle_frequency_square.v) |
| Zig | [`zig/m/mo_2d_rectangle_frequency_square.zig`](../../../zig/m/mo_2d_rectangle_frequency_square.zig) |
