# Power iteration

The pinned Python implementation repeatedly multiplies a vector by the matrix, normalizes it by its Euclidean norm, and evaluates the Rayleigh quotient. It stops when the relative change in that quotient is at most `1e-12`, or after 100 iterations. The pinned C# implementation uses a different stopping rule based on the dot product of consecutive normalized vectors and reports the norm of `A*v`; this benchmark follows the specified Python path.

## Contract

Input is `[a, b, d, x, y]` for the symmetric matrix `[[a,b],[b,d]]` and starting vector `[x,y]`. All five integers are in `1..1000`; the matrix must be positive definite (`a*d > b*b`). Positive off-diagonal and starting entries ensure a nonzero projection onto the dominant eigenvector. Output is the estimated dominant eigenvalue as binary64; malformed input returns `-1e300`.

The eigenvector is an internal iteration state; the scalar ABI records the eigenvalue component of the Python return pair. See [`workload.json`](workload.json), the runtime [oracle](../../power_iteration_oracle.py), and the [pinned Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/linear_algebra/src/power_iteration.py). The [pinned C# source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/LinearAlgebra/Eigenvalue/PowerIteration.cs) is documented as a distinct stopping/return variant.

| Language | Port |
|---|---|
| C | [`c/p/power_iteration.c`](../../../c/p/power_iteration.c) |
| C3 | [`c3/p/power_iteration.c3`](../../../c3/p/power_iteration.c3) |
| C++ | [`cpp/p/power_iteration.cpp`](../../../cpp/p/power_iteration.cpp) |
| Elisa | [`elisa/p/power_iteration.elisa`](../../../elisa/p/power_iteration.elisa) |
| Nim | [`nim/p/power_iteration.nim`](../../../nim/p/power_iteration.nim) |
| Odin | [`odin/p/power_iteration.odin`](../../../odin/p/power_iteration.odin) |
| Rust | [`rust/p/power_iteration.rs`](../../../rust/p/power_iteration.rs) |
| V | [`v/p/power_iteration.v`](../../../v/p/power_iteration.v) |
| Zig | [`zig/p/power_iteration.zig`](../../../zig/p/power_iteration.zig) |
