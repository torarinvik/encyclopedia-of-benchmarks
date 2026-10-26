# Greedy min-sum set cover

This profile schedules universe elements one at a time. At each step it picks
the element that belongs to the largest number of sets not yet hit; ties go to
the smallest element ID. It reports the sum of the sets' first-hit positions
and the full element order.

Input is `[n, set_count, masks...]`, with a universe of `1 <= n <= 12`
elements and `1 <= set_count <= 16` nonempty sets represented as bitmasks.
Output is `[total_cover_time, element_order...]` as little-endian signed i64
values. Invalid input returns `-1`; null output or insufficient capacity
returns `-2` without writing.

The profile instantiates the greedy MSSC algorithm from “Min-Sum Set Cover and
Its Generalizations,” DOI
[`10.1007/978-1-4939-2864-4_806`](https://doi.org/10.1007/978-1-4939-2864-4_806).
It is clean-room and does not copy book prose or source code. The objective
differs from set cover: it minimizes cover-time sum under a specified greedy
ordering rule, rather than selecting a small family of sets.

| Language | Port |
|---|---|
| C | `c/m/min_sum_set_cover_greedy.c` |
| C3 | `c3/m/min_sum_set_cover_greedy.c3` |
| C++ | `cpp/m/min_sum_set_cover_greedy.cpp` |
| Elisa | `elisa/m/min_sum_set_cover_greedy.elisa` |
| Nim | `nim/m/min_sum_set_cover_greedy.nim` |
| Odin | `odin/m/min_sum_set_cover_greedy.odin` |
| Rust | `rust/m/min_sum_set_cover_greedy.rs` |
| V | `v/m/min_sum_set_cover_greedy.v` |
| Zig | `zig/m/min_sum_set_cover_greedy.zig` |
