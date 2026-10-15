# Pascal Triangle Row

Compute a single zero-based row of Pascal's triangle using an in-place dynamic-programming recurrence.

## Contract

- The scalar input is a row index from 0 through 33; other signed 64-bit inputs return -1.
- The implementation returns the row coefficients in ascending column order.
- Each coefficient is written as an unsigned 32-bit little-endian integer. The return value is the number of bytes written.
- An output capacity smaller than the complete row returns -2 and writes no bytes.
- The upper bound preserves the source problem's 32-bit coefficient domain; row 33 has maximum coefficient 1,166,803,110.

The algorithm initializes every coefficient to one, then updates interior positions from right to left for each row. This uses O(n) storage and O(n^2) additions for row index n.

## Workload and verification

[workload.json](workload.json) includes every supported row, invalid signed inputs, and the maximum row. [verify_i64_scalar_bytes_output.py](../../verify_i64_scalar_bytes_output.py) compares all coefficients against Python's exact binomial coefficient oracle, checks insufficient-capacity behavior, and validates the recorder. The checker and runner support outputs up to 256 bytes; the largest supported row uses 136.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/pascal_triangle_row.c](../../../c/p/pascal_triangle_row.c) |
| C3 | [c3/p/pascal_triangle_row.c3](../../../c3/p/pascal_triangle_row.c3) |
| C++ | [cpp/p/pascal_triangle_row.cpp](../../../cpp/p/pascal_triangle_row.cpp) |
| Elisa | [elisa/p/pascal_triangle_row.elisa](../../../elisa/p/pascal_triangle_row.elisa) |
| Nim | [nim/p/pascal_triangle_row.nim](../../../nim/p/pascal_triangle_row.nim) |
| Odin | [odin/p/pascal_triangle_row.odin](../../../odin/p/pascal_triangle_row.odin) |
| Rust | [rust/p/pascal_triangle_row.rs](../../../rust/p/pascal_triangle_row.rs) |
| V | [v/p/pascal_triangle_row.v](../../../v/p/pascal_triangle_row.v) |
| Zig | [zig/p/pascal_triangle_row.zig](../../../zig/p/pascal_triangle_row.zig) |

## TheAlgorithms reference

- [C LeetCode 119 getRow](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/119.c) uses the same in-place update from right to left.
