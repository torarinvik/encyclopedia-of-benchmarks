# Length-bounded maximum-sum segment

This profile solves the maximum-sum segment problem with both a minimum and
maximum allowed length. It uses prefix sums and a monotone deque of candidate
prefix minima, preserving the linear-time recurrence described for this
problem family.

Input is `[n, L, U, values...]`, where `1 <= n <= 32`, `1 <= L <= U <= n`,
and each value is in `[-10000, 10000]`. Output is `[sum, start, end]`, where
`start` is zero-based and `end` is exclusive. Among equal sums the earliest
start wins, then the earliest end. Values and output fields are signed i64;
output uses little-endian encoding. Invalid input returns `-1`; null output
or insufficient capacity returns `-2` without writing.

The source chapter is “Maximum-Sum Segments,” DOI
[`10.1007/978-1-4939-2864-4_226`](https://doi.org/10.1007/978-1-4939-2864-4_226).
This bounded profile is clean-room and does not copy book prose or source code.

| Language | Port |
|---|---|
| C | `c/m/max_sum_length_bounded_segment.c` |
| C3 | `c3/m/max_sum_length_bounded_segment.c3` |
| C++ | `cpp/m/max_sum_length_bounded_segment.cpp` |
| Elisa | `elisa/m/max_sum_length_bounded_segment.elisa` |
| Nim | `nim/m/max_sum_length_bounded_segment.nim` |
| Odin | `odin/m/max_sum_length_bounded_segment.odin` |
| Rust | `rust/m/max_sum_length_bounded_segment.rs` |
| V | `v/m/max_sum_length_bounded_segment.v` |
| Zig | `zig/m/max_sum_length_bounded_segment.zig` |
