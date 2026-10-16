# Print a matrix in spiral order

The pinned Java `PrintAMatrixInSpiralOrder.print` visits the top row, right column, bottom row in reverse, and left column in reverse while shrinking its bounds. Its example is a clockwise walk starting at the top-left. This benchmark uses that order for bounded rectangular matrices.

## Contract

Input is `[rows, columns, row_major_i32_values...]`, with each dimension in 1..8 and exactly `rows * columns` signed 32-bit entries. The scalar result is 32-bit FNV-1a over the spiral sequence, feeding each signed value as four little-endian two's-complement bytes. Malformed inputs return -1.

The source returns a `List<Integer>`; the hash is the benchmark's bounded scalar ABI representation. See [`workload.json`](workload.json), the runtime [oracle](../../print_amatrix_in_spiral_order_oracle.py), and the [pinned Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/matrix/PrintAMatrixInSpiralOrder.java).

| Language | Port |
|---|---|
| C | [`c/p/print_amatrix_in_spiral_order.c`](../../../c/p/print_amatrix_in_spiral_order.c) |
| C3 | [`c3/p/print_amatrix_in_spiral_order.c3`](../../../c3/p/print_amatrix_in_spiral_order.c3) |
| C++ | [`cpp/p/print_amatrix_in_spiral_order.cpp`](../../../cpp/p/print_amatrix_in_spiral_order.cpp) |
| Elisa | [`elisa/p/print_amatrix_in_spiral_order.elisa`](../../../elisa/p/print_amatrix_in_spiral_order.elisa) |
| Nim | [`nim/p/print_amatrix_in_spiral_order.nim`](../../../nim/p/print_amatrix_in_spiral_order.nim) |
| Odin | [`odin/p/print_amatrix_in_spiral_order.odin`](../../../odin/p/print_amatrix_in_spiral_order.odin) |
| Rust | [`rust/p/print_amatrix_in_spiral_order.rs`](../../../rust/p/print_amatrix_in_spiral_order.rs) |
| V | [`v/p/print_amatrix_in_spiral_order.v`](../../../v/p/print_amatrix_in_spiral_order.v) |
| Zig | [`zig/p/print_amatrix_in_spiral_order.zig`](../../../zig/p/print_amatrix_in_spiral_order.zig) |
