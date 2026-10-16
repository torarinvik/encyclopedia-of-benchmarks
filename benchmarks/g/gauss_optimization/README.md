# Gauss optimization

Ports the pinned C# coordinate-search maximizer. Because the source accepts an arbitrary delegate, the benchmark fixes the objective to `f(x1, x2) = -((x1 - target1)^2 + (x2 - target2)^2)` and supplies the target coordinates as input.

Input is `[reduction_factor, initial_step, epsilon, x1, x2, target1, target2]`. The reduction factor is exactly 2, 3, or 4; the step is in `[0.25, 4]`; epsilon is in `[1e-6, 2]`; and start and target coordinates are in `[-8, 8]`. The search evaluates bottom, top, left, then right, keeps the first equal maximum, moves to that coordinate, and divides the step by the reduction factor. It stops when the absolute function-value change is at most epsilon. A 256-iteration limit makes the ABI bounded; the documented input range converges within it. The output is the final `(x1, x2)` pair. Invalid input returns `-1`; null or undersized output returns `-2`.

The source's `Math.Abs(error)` condition and first-index `List<double>.IndexOf` tie behavior are preserved. Console output and arbitrary user callbacks are outside this portable contract. See [`workload.json`](workload.json), the [independent oracle](../../gauss_optimization_oracle.py), and the [pinned C# source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6/Algorithms/Other/GaussOptimization.cs).

| Language | Port |
|---|---|
| C | [`c/g/gauss_optimization.c`](../../../c/g/gauss_optimization.c) |
| C3 | [`c3/g/gauss_optimization.c3`](../../../c3/g/gauss_optimization.c3) |
| C++ | [`cpp/g/gauss_optimization.cpp`](../../../cpp/g/gauss_optimization.cpp) |
| Elisa | [`elisa/g/gauss_optimization.elisa`](../../../elisa/g/gauss_optimization.elisa) |
| Nim | [`nim/g/gauss_optimization.nim`](../../../nim/g/gauss_optimization.nim) |
| Odin | [`odin/g/gauss_optimization.odin`](../../../odin/g/gauss_optimization.odin) |
| Rust | [`rust/g/gauss_optimization.rs`](../../../rust/g/gauss_optimization.rs) |
| V | [`v/g/gauss_optimization.v`](../../../v/g/gauss_optimization.v) |
| Zig | [`zig/g/gauss_optimization.zig`](../../../zig/g/gauss_optimization.zig) |
