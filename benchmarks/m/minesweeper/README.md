# Minesweeper Neighbor Counts

This package ports the pinned [TheAlgorithms/JavaScript implementation](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Search/Minesweeper.js). It walks a rectangular boolean grid in row-major order and counts mines in the eight neighboring cells, excluding the cell itself.

The `i64_array_bytes_output` input is `[rows, cols, flattened_cells...]`, with each dimension from 1 through 32 and each cell 0 or 1. The output contains the cell count as a signed little-endian i64 followed by row-major neighbor counts as signed little-endian i64 values. Maximum input length is 1,026 values (8,208 packed bytes); maximum output capacity is 8,200 bytes. Invalid input returns `-1`; insufficient capacity returns `-2`; both errors write no bytes.

See [`workload.json`](workload.json) for singleton, one-dimensional, rectangular, corner/edge/interior, all-mine, all-empty, bounds, malformed-input, and capacity cases. The independent oracle is [`minesweeper_oracle.py`](../../minesweeper_oracle.py).

## Language ports

- C: [`c/m/minesweeper.c`](../../../c/m/minesweeper.c)
- C3: [`c3/m/minesweeper.c3`](../../../c3/m/minesweeper.c3)
- C++: [`cpp/m/minesweeper.cpp`](../../../cpp/m/minesweeper.cpp)
- Elisa: [`elisa/m/minesweeper.elisa`](../../../elisa/m/minesweeper.elisa)
- Nim: [`nim/m/minesweeper.nim`](../../../nim/m/minesweeper.nim)
- Odin: [`odin/m/minesweeper.odin`](../../../odin/m/minesweeper.odin)
- Rust: [`rust/m/minesweeper.rs`](../../../rust/m/minesweeper.rs)
- V: [`v/m/minesweeper.v`](../../../v/m/minesweeper.v)
- Zig: [`zig/m/minesweeper.zig`](../../../zig/m/minesweeper.zig)
