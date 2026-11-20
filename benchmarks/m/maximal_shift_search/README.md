# Maximal Shift Search

Input is `[n,m,text...,pattern...]`, with `0<=n<=4096`, `1<=m<=128`, and
symbols in `0..3`. The scalar result packs all possibly overlapping match
offsets as `(count<<36)|(sum<<12)|xor`; malformed input returns `-1`.

Maximal Shift is Sunday's Quick Search variant. For each pattern position `i`,
the leading shift is the distance from `i` to the nearest earlier occurrence
of the same symbol, or `i+1` when there is none. The scan order sorts positions
by decreasing leading shift, breaking ties by decreasing pattern index. At an
alignment, positions are compared in that order. The mismatch index selects an
adapted good-suffix shift, while the text symbol immediately after the window
selects a Quick Search shift; the algorithm advances by the larger value. A
full match uses the adapted shift for index `m`. The last alignment has no
following text symbol, so the search ends after checking it.

The order is different from local [`optimal_mismatch`](../../o/optimal_mismatch/README.md),
which sorts positions by symbol frequency. It is also distinct from Quick
Search alone, which scans the pattern in ordinary order and uses only its
lookahead table. The scan order and method follow Lecroq's
[Maximal Shift description](https://igm.univ-mlv.fr/~lecroq/string/node29.html).
Its adapted good-suffix table uses the construction also described for
[Optimal Mismatch](https://igm.univ-mlv.fr/~lecroq/string/node28.html), with
the leading-shift order described above. The Maximal Shift page identifies it
as a Quick Search variant and gives
`O(m^2+sigma)` preprocessing, `O(m+sigma)` space, and `O(mn)` worst-case
search. With the fixed alphabet size four, preprocessing is `O(m^2)` and the
ports use `O(m+n)` bounded storage including the text copy.

The primary reference builds the pattern order, adapted good-suffix shifts,
and Quick Search table. The independent reference checks each legal alignment
directly. The workload covers overlap, scan-order ties, lookahead shifts,
misses, bounds, and malformed inputs. The package is registered in the
`i64_array_scalar` runner and verifier. Only the published algorithm idea was
consulted; benchmark code, contract, fixtures, and prose are independently
authored. See [RIGHTS.md](RIGHTS.md).

| Language | Port |
|---|---|
| C | [c/m/maximal_shift_search.c](../../../c/m/maximal_shift_search.c) |
| C3 | [c3/m/maximal_shift_search.c3](../../../c3/m/maximal_shift_search.c3) |
| C++ | [cpp/m/maximal_shift_search.cpp](../../../cpp/m/maximal_shift_search.cpp) |
| Elisa | [elisa/m/maximal_shift_search.elisa](../../../elisa/m/maximal_shift_search.elisa) |
| Mojo | [mojo/m/maximal_shift_search.mojo](../../../mojo/m/maximal_shift_search.mojo) |
| Nim | [nim/m/maximal_shift_search.nim](../../../nim/m/maximal_shift_search.nim) |
| Odin | [odin/m/maximal_shift_search.odin](../../../odin/m/maximal_shift_search.odin) |
| Rust | [rust/m/maximal_shift_search.rs](../../../rust/m/maximal_shift_search.rs) |
| V | [v/m/maximal_shift_search.v](../../../v/m/maximal_shift_search.v) |
| Zig | [zig/m/maximal_shift_search.zig](../../../zig/m/maximal_shift_search.zig) |
