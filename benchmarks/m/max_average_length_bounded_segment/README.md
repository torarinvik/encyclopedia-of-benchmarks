# Length-bounded maximum-average segment

This exact bounded profile scans all consecutive intervals whose lengths lie
in `[L,U]` and compares their averages by cross multiplication. It returns the
maximum as an exact numerator/denominator pair, followed by the interval
indices.

Input is `[n,L,U,values...]`, with `1 <= n <= 32`, `1 <= L <= U <= n`, and
values in `[-10000,10000]`. Output is
`[segment_sum, segment_length, zero_based_start, end_exclusive]` as
little-endian signed i64 values. Ties choose shorter length, then earlier
start, then earlier end. Invalid input returns `-1`; null output or
insufficient capacity returns `-2` without writing.

The problem is from “Maximum-Average Segments,” DOI
[`10.1007/978-1-4939-2864-4_224`](https://doi.org/10.1007/978-1-4939-2864-4_224).
This is a bounded exact-search profile of the source problem, not a claim to
match its asymptotically faster right-skew algorithms. It is clean-room.

It is a distinct objective from maximum-sum segments: intervals are ranked by
average, not total sum.

| Language | Port |
|---|---|
| C | `c/m/max_average_length_bounded_segment.c` |
| C3 | `c3/m/max_average_length_bounded_segment.c3` |
| C++ | `cpp/m/max_average_length_bounded_segment.cpp` |
| Elisa | `elisa/m/max_average_length_bounded_segment.elisa` |
| Nim | `nim/m/max_average_length_bounded_segment.nim` |
| Odin | `odin/m/max_average_length_bounded_segment.odin` |
| Rust | `rust/m/max_average_length_bounded_segment.rs` |
| V | `v/m/max_average_length_bounded_segment.v` |
| Zig | `zig/m/max_average_length_bounded_segment.zig` |
