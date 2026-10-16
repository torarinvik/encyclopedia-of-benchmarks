# Linear Diophantine equations solver

The pinned Java solver uses recursive extended Euclid to return one integer solution to `a*x+b*y=c`; it has explicit cases for zero coefficients and sentinel solutions for no solution and infinitely many solutions. The contract preserves its recursive quotient/remainder branch and selected particular solution.

## Contract

Input is `[a,b,c]`, with `a,b` in `[-1000,1000]` and `c` in `[-10000,10000]`. Output is `-1` for invalid input, `-2` when no solution exists, `-3` for `0x+0y=0`, otherwise `(x+10000001)*20000003+(y+10000001)`.

See [workload](workload.json), [independent oracle](../../linear_diophantine_equations_solver_oracle.py), and pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/LinearDiophantineEquationsSolver.java).

| Language | Port |
|---|---|
| C | [`c/l/linear_diophantine_equations_solver.c`](../../../c/l/linear_diophantine_equations_solver.c) |
| C3 | [`c3/l/linear_diophantine_equations_solver.c3`](../../../c3/l/linear_diophantine_equations_solver.c3) |
| C++ | [`c++/l/linear_diophantine_equations_solver.cpp`](../../../c++/l/linear_diophantine_equations_solver.cpp) |
| Elisa | [`elisa/l/linear_diophantine_equations_solver.elisa`](../../../elisa/l/linear_diophantine_equations_solver.elisa) |
| Nim | [`nim/l/linear_diophantine_equations_solver.nim`](../../../nim/l/linear_diophantine_equations_solver.nim) |
| Odin | [`odin/l/linear_diophantine_equations_solver.odin`](../../../odin/l/linear_diophantine_equations_solver.odin) |
| Rust | [`rust/l/linear_diophantine_equations_solver.rs`](../../../rust/l/linear_diophantine_equations_solver.rs) |
| V | [`v/l/linear_diophantine_equations_solver.v`](../../../v/l/linear_diophantine_equations_solver.v) |
| Zig | [`zig/l/linear_diophantine_equations_solver.zig`](../../../zig/l/linear_diophantine_equations_solver.zig) |
