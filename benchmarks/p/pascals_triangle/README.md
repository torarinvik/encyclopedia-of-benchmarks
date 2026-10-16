# Pascal's triangle row

The pinned TypeScript `pascalsTriangle(n)` builds n rows and returns the final row, so its input n selects row index n−1. Each new row has ones at both ends and sums adjacent values from the previous row for its interior.

## Contract

Input is `[n]`, where 1 <= n <= 31. The scalar result is a base-31 rolling hash modulo 1,000,000,007 of the returned row. The bound keeps every row coefficient exactly representable by the source's JavaScript number arithmetic. Zero is excluded because the source returns `undefined` after building no rows.

See [`workload.json`](workload.json) and the runtime [oracle](../../pascals_triangle_oracle.py). Pinned source: [TheAlgorithms/TypeScript `pascals_triangle.ts`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/maths/pascals_triangle.ts).

| Language | Port |
|---|---|
| C | [`c/p/pascals_triangle.c`](../../../c/p/pascals_triangle.c) |
| C3 | [`c3/p/pascals_triangle.c3`](../../../c3/p/pascals_triangle.c3) |
| C++ | [`cpp/p/pascals_triangle.cpp`](../../../cpp/p/pascals_triangle.cpp) |
| Elisa | [`elisa/p/pascals_triangle.elisa`](../../../elisa/p/pascals_triangle.elisa) |
| Nim | [`nim/p/pascals_triangle.nim`](../../../nim/p/pascals_triangle.nim) |
| Odin | [`odin/p/pascals_triangle.odin`](../../../odin/p/pascals_triangle.odin) |
| Rust | [`rust/p/pascals_triangle.rs`](../../../rust/p/pascals_triangle.rs) |
| V | [`v/p/pascals_triangle.v`](../../../v/p/pascals_triangle.v) |
| Zig | [`zig/p/pascals_triangle.zig`](../../../zig/p/pascals_triangle.zig) |
