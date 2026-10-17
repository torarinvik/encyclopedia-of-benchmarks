# Snail matrix traversal

## Contract

Traverse a rectangular matrix clockwise inward from its top-left cell. The input is a direct signed-i32 array encoded as [rows, columns, row-major cells...]. Each dimension is between 0 and 16, the packed length is exactly 2 + rows * columns, and all cells may use the full signed-i32 range. An empty matrix is encoded as [0, 0]; a positive row count with zero columns also returns an empty result. A zero row count with nonzero columns is invalid.

The pinned Rust source advances its direction and bounds after every emitted value, including the final value. On a multi-row, one-column matrix that final movement decrements an unsigned zero column bound and can panic when overflow checks are enabled. The supported domain therefore permits one column only for a 1-by-1 matrix. Ragged matrices are not representable by the packed input.

The C ABI entry point is:

~~~c
int64_t snail(const int32_t *values, size_t length,
              uint8_t *output, size_t output_capacity);
~~~

A null input, malformed dimensions or length, or input longer than 259 words returns -1. Valid output is the clockwise traversal encoded as little-endian signed-i32 values; the function returns the number of bytes written. A null output pointer or insufficient capacity returns -2 after input validation, and errors write no output. The maximum valid input is 258 words and the maximum output is 1,024 bytes. A nonnull output pointer with zero capacity succeeds for an empty result.

## Workload

[workload.json](workload.json) covers empty and zero-column matrices, one-cell and one-row matrices, square and rectangular traversals, signed-i32 boundaries, the source-safe 1-by-1 single-column case, malformed dimensions and lengths, null pointers, and output-capacity errors.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/s/snail.c](../../../c/s/snail.c) |
| C3 | [c3/s/snail.c3](../../../c3/s/snail.c3) |
| C++ | [cpp/s/snail.cpp](../../../cpp/s/snail.cpp) |
| Elisa | [elisa/s/snail.elisa](../../../elisa/s/snail.elisa) |
| Nim | [nim/s/snail.nim](../../../nim/s/snail.nim) |
| Odin | [odin/s/snail.odin](../../../odin/s/snail.odin) |
| Rust | [rust/s/snail.rs](../../../rust/s/snail.rs) |
| V | [v/s/snail.v](../../../v/s/snail.v) |
| Zig | [zig/s/snail.zig](../../../zig/s/snail.zig) |

## TheAlgorithms source

- [Rust snail.rs at commit fed66cb0c74c4a939ec5163648458a8c2b46fd4c](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/dynamic_programming/snail.rs)
