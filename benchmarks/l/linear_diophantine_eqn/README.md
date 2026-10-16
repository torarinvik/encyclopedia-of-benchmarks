# Linear Diophantine equation solvability

The pinned Dart `Isposs(a,b,c)` checks whether the integer equation `a*x + b*y = c` is solvable by computing `gcd(a,b)` and testing whether it divides c. The source gcd is recursive Euclid.

## Contract

Input is `[a,b,c]`, with coefficients in `[-100000,100000]`, `c` in `[-1000000,1000000]`, and `b != 0`. The `b=0` case is excluded because the pinned gcd evaluates a remainder by zero. Output is 1 when solvable and 0 otherwise; invalid input returns -1.

See [workload](workload.json), [independent oracle](../../linear_diophantine_eqn_oracle.py), and the pinned [Dart source](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/maths/LinearDiophantineEqn.dart).

| Language | Port |
|---|---|
| C | [`c/l/linear_diophantine_eqn.c`](../../../c/l/linear_diophantine_eqn.c) |
| C3 | [`c3/l/linear_diophantine_eqn.c3`](../../../c3/l/linear_diophantine_eqn.c3) |
| C++ | [`cpp/l/linear_diophantine_eqn.cpp`](../../../cpp/l/linear_diophantine_eqn.cpp) |
| Elisa | [`elisa/l/linear_diophantine_eqn.elisa`](../../../elisa/l/linear_diophantine_eqn.elisa) |
| Nim | [`nim/l/linear_diophantine_eqn.nim`](../../../nim/l/linear_diophantine_eqn.nim) |
| Odin | [`odin/l/linear_diophantine_eqn.odin`](../../../odin/l/linear_diophantine_eqn.odin) |
| Rust | [`rust/l/linear_diophantine_eqn.rs`](../../../rust/l/linear_diophantine_eqn.rs) |
| V | [`v/l/linear_diophantine_eqn.v`](../../../v/l/linear_diophantine_eqn.v) |
| Zig | [`zig/l/linear_diophantine_eqn.zig`](../../../zig/l/linear_diophantine_eqn.zig) |
