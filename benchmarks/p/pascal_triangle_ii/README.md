# Pascal triangle row by index

This benchmark follows the final active `get_row` definition in the pinned Ruby `pascal_triangle_ii` sources. Its input is a zero-based row index; row 0 is `[1]` and row 3 is `[1, 3, 3, 1]`.

## Contract

- Input is a signed 64-bit row index in `0..=30`.
- The result is a base-31 rolling hash modulo 1,000,000,007 of the selected row.
- Inputs outside the range return `INT64_MIN`.

The dynamic-programming file defines `get_row` three times; Ruby's final definition is active. It builds the triangle from `[[1]]`, sets each row's endpoints to one, and fills interior entries from the two values above. The second pinned Ruby file computes the same row with factorial-based combinations; both produce the same row on this bounded domain. The hash maps the returned integer array to the scalar ABI. The bound ensures the row coefficients remain exactly representable in signed 32-bit integers.

This candidate uses a zero-based row index, while [`pascals_triangle`](../pascals_triangle/README.md) accepts a one-based row count.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/pascal_triangle_ii.c`](../../../c/p/pascal_triangle_ii.c) |
| C3 | [`c3/p/pascal_triangle_ii.c3`](../../../c3/p/pascal_triangle_ii.c3) |
| C++ | [`cpp/p/pascal_triangle_ii.cpp`](../../../cpp/p/pascal_triangle_ii.cpp) |
| Elisa | [`elisa/p/pascal_triangle_ii.elisa`](../../../elisa/p/pascal_triangle_ii.elisa) |
| Nim | [`nim/p/pascal_triangle_ii.nim`](../../../nim/p/pascal_triangle_ii.nim) |
| Odin | [`odin/p/pascal_triangle_ii.odin`](../../../odin/p/pascal_triangle_ii.odin) |
| Rust | [`rust/p/pascal_triangle_ii.rs`](../../../rust/p/pascal_triangle_ii.rs) |
| V | [`v/p/pascal_triangle_ii.v`](../../../v/p/pascal_triangle_ii.v) |
| Zig | [`zig/p/pascal_triangle_ii.zig`](../../../zig/p/pascal_triangle_ii.zig) |

## Workload and recording

[`workload.json`](workload.json) includes rows 0, 1, 3, 10, 20, and 30, plus invalid bounds. The runtime oracle uses the binomial coefficient recurrence in [`pascal_triangle_ii_oracle.py`](../../pascal_triangle_ii_oracle.py). Build and record with the scalar ABI and `benchmarks/run_scalar.py`.

## Pinned sources

- [Ruby dynamic-programming source](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/dynamic_programming/pascal_triangle_ii.rb)
- [Ruby maths source](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/maths/pascal_triangle_ii.rb)
