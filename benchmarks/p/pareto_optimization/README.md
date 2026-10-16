# Pareto optimization

This package ports the pinned C# [`ParetoOptimization.Optimize`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Other/ParetoOptimization.cs) row filter. Each row is a decision and each column is a criterion to maximize. A row is removed when another row is greater than or equal to it in every criterion. For exact duplicate rows, the earlier row is retained, matching the source's pairwise scan. Retained rows remain in their original order.

## Contract

Input is a signed-i64 array `[rows, cols, row_major_cells...]` with exact length `2 + rows*cols`. `rows` is `1..64`, `cols` is `1..8`, and each cell is an integer in `[-1000,1000]`, a bounded subset of the source's decimal domain. Invalid shape or values return `-1`.

The scalar result is the low 63 bits of FNV-1a-64 over `[retained_rows, cols, retained_row_major_cells...]`, serialized as signed-i64 little-endian words. The independent oracle checks dominance directly and hashes the retained matrix.

[`workload.json`](workload.json) covers single-row and single-criterion inputs, duplicate and dominated rows, tradeoffs, signed criterion extremes, malformed dimensions/data, and a 64-by-8 boundary case. The oracle is [`pareto_optimization_oracle.py`](../../pareto_optimization_oracle.py).

| Language | Port |
|---|---|
| C | [`c/p/pareto_optimization.c`](../../../c/p/pareto_optimization.c) |
| C3 | [`c3/p/pareto_optimization.c3`](../../../c3/p/pareto_optimization.c3) |
| C++ | [`cpp/p/pareto_optimization.cpp`](../../../cpp/p/pareto_optimization.cpp) |
| Elisa | [`elisa/p/pareto_optimization.elisa`](../../../elisa/p/pareto_optimization.elisa) |
| Nim | [`nim/p/pareto_optimization.nim`](../../../nim/p/pareto_optimization.nim) |
| Odin | [`odin/p/pareto_optimization.odin`](../../../odin/p/pareto_optimization.odin) |
| Rust | [`rust/p/pareto_optimization.rs`](../../../rust/p/pareto_optimization.rs) |
| V | [`v/p/pareto_optimization.v`](../../../v/p/pareto_optimization.v) |
| Zig | [`zig/p/pareto_optimization.zig`](../../../zig/p/pareto_optimization.zig) |
