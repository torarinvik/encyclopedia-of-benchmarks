# Matrix subtraction

This benchmark ports the pinned Go `Matrix[T].Subtract` operation as a bounded elementwise matrix subtraction. The source returns an error when dimensions differ and otherwise subtracts corresponding cells. Go launches one goroutine per row and constructs a result matrix; the shared ports use sequential row-major loops, so the benchmark isolates the bounded elementwise kernel rather than Go goroutine scheduling or matrix-allocation overhead. The shared ABI uses `int32` cells and defines their arithmetic modulo 2^32, so overflow is deterministic across languages.

Source: [TheAlgorithms/Go `math/matrix/subtract.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/matrix/subtract.go), with dimensions from [`math/matrix/matrix.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/matrix/matrix.go).

## Contract

Input is `[rows_a, columns_a, A row-major values..., rows_b, columns_b, B row-major values...]`, carried in signed-i64 slots. Each dimension is 0 through 16, with at most 256 cells per matrix. A zero-row matrix must be 0×0; positive-row, zero-column matrices are allowed. The packed length must exactly match both matrices. Cell values must fit signed i32.

For matching dimensions, subtract corresponding cells in row-major order modulo 2^32 and emit each result as a little-endian signed-i32 bit pattern. The return value is the cell count, not the output byte count. Invalid dimensions, framing, or cell domain return `-2`. A valid shape mismatch returns `-1` before cell-domain or output-buffer checks. A null output buffer or insufficient capacity for a nonempty result returns `-3` without writing. A matching zero-cell shape returns `0`, including with null output and zero capacity. Maximum output and workspace are 1,024 bytes.

## Workload and oracle

[workload.json](workload.json) covers signed values, modulo wraparound, empty and zero-column matrices, shape mismatch, invalid framing/dimensions/domain, null and short output, and maximum-size matrices. The independent integer oracle is [subtract_oracle.py](../../subtract_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [c/m/subtract.c](../../../c/m/subtract.c) |
| C3 | [c3/m/subtract.c3](../../../c3/m/subtract.c3) |
| C++ | [cpp/m/subtract.cpp](../../../cpp/m/subtract.cpp) |
| Elisa | [elisa/m/subtract.elisa](../../../elisa/m/subtract.elisa) |
| Nim | [nim/m/subtract.nim](../../../nim/m/subtract.nim) |
| Odin | [odin/m/subtract.odin](../../../odin/m/subtract.odin) |
| Rust | [rust/m/subtract.rs](../../../rust/m/subtract.rs) |
| V | [v/m/subtract.v](../../../v/m/subtract.v) |
| Zig | [zig/m/subtract.zig](../../../zig/m/subtract.zig) |
