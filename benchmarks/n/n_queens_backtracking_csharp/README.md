# N-Queens backtracking solver

Enumerate all placements of `n` queens on an `n × n` board using the pinned C# backtracking solver. The search assigns columns from left to right and tries candidate rows in ascending order. A placement is accepted when no earlier queen shares its row or diagonal. The empty board (`n = 0`) follows the source behavior and produces no solutions.

Pinned source:

- C#: [TheAlgorithms/C-Sharp `BacktrackingNQueensSolver.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Problems/NQueens/BacktrackingNQueensSolver.cs)

## Contract

The input is one signed 64-bit integer `n`, from 0 through 8. The output is a little-endian signed 64-bit vector containing the solution count, followed by every solution in the source's depth-first search order. Each solution contains `n` row indices, one for each column, from column 0 through column `n-1`. For `n = 0`, the vector contains only a zero count.

The function returns the number of output bytes written, `-1` for an out-of-range `n`, and `-2` when the output pointer is null or its capacity is too small. The largest result occurs at `n = 8` and uses 5,896 bytes.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/n/n_queens_backtracking_csharp.c`](../../../c/n/n_queens_backtracking_csharp.c) |
| C3 | [`c3/n/n_queens_backtracking_csharp.c3`](../../../c3/n/n_queens_backtracking_csharp.c3) |
| C++ | [`cpp/n/n_queens_backtracking_csharp.cpp`](../../../cpp/n/n_queens_backtracking_csharp.cpp) |
| Elisa | [`elisa/n/n_queens_backtracking_csharp.elisa`](../../../elisa/n/n_queens_backtracking_csharp.elisa) |
| Nim | [`nim/n/n_queens_backtracking_csharp.nim`](../../../nim/n/n_queens_backtracking_csharp.nim) |
| Odin | [`odin/n/n_queens_backtracking_csharp.odin`](../../../odin/n/n_queens_backtracking_csharp.odin) |
| Rust | [`rust/n/n_queens_backtracking_csharp.rs`](../../../rust/n/n_queens_backtracking_csharp.rs) |
| V | [`v/n/n_queens_backtracking_csharp.v`](../../../v/n/n_queens_backtracking_csharp.v) |
| Zig | [`zig/n/n_queens_backtracking_csharp.zig`](../../../zig/n/n_queens_backtracking_csharp.zig) |
