# Floyd's Triangle

Generate the triangular sequence of consecutive positive integers. The pinned Java source starts at 1 and appends one more value in each successive row.

## Contract

- The scalar input is the row count from 0 through 90. Invalid values return `-1`.
- Return the triangle values in row-major order as unsigned 16-bit little-endian bytes. For example, three rows encode `1`, then `2, 3`, then `4, 5, 6`.
- The return value is the number of output bytes. If the caller's output capacity is too small, return `-2` without writing.
- Ninety rows produce 4,095 values and 8,190 output bytes, within the shared scalar byte-output ABI's 8,192-byte capacity.

The shared verifier checks every input from 0 through 4,096, signed-64-bit boundaries, invalid rows, output-capacity failures, and every published workload case in all nine languages.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/f/floyd_triangle.c`](../../../c/f/floyd_triangle.c) |
| C3 | [`c3/f/floyd_triangle.c3`](../../../c3/f/floyd_triangle.c3) |
| C++ | [`cpp/f/floyd_triangle.cpp`](../../../cpp/f/floyd_triangle.cpp) |
| Elisa | [`elisa/f/floyd_triangle.elisa`](../../../elisa/f/floyd_triangle.elisa) |
| Nim | [`nim/f/floyd_triangle.nim`](../../../nim/f/floyd_triangle.nim) |
| Odin | [`odin/f/floyd_triangle.odin`](../../../odin/f/floyd_triangle.odin) |
| Rust | [`rust/f/floyd_triangle.rs`](../../../rust/f/floyd_triangle.rs) |
| V | [`v/f/floyd_triangle.v`](../../../v/f/floyd_triangle.v) |
| Zig | [`zig/f/floyd_triangle.zig`](../../../zig/f/floyd_triangle.zig) |

Upstream: [TheAlgorithms/Java `FloydTriangle.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/others/FloydTriangle.java).

Build with the `i64_scalar_bytes_output` ABI and verify with `python3 benchmarks/verify_i64_scalar_bytes_output.py --algorithms floyd_triangle --elisa-compiler ../Elisa-compiler/bin/elisac-stage1`.
