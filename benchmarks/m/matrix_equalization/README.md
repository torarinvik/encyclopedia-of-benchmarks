# Matrix equalization

The pinned Python file defines array_equalization(vector, step_size), a greedy
minimum-update algorithm. For each distinct value already in the vector, it
scans left to right: a matching value advances by one index, while a mismatch
counts one update and advances by step_size. It returns the least update count
among the candidate values.

## Contract

- The input is a signed 64-bit integer array: [step_size, value_0, ..., value_(n-1)].
- The vector length n is 1 through 64. Every vector value may be any signed
  64-bit integer.
- step_size is in 1 through n.
- The result is the minimum update count. Invalid shape or step size returns -1.
- Empty vectors are excluded because the source returns sys.maxsize for that
  case. The bounded step and vector sizes keep index arithmetic safe.

The catalog filename is matrix_equalization, but the pinned source function is
named array_equalization. This package follows that function's behavior.

## Workload and oracle

workload.json covers the source examples, ties between target values, step
sizes that skip multiple positions, signed boundary values, the maximum
vector length, and invalid packed inputs. The independent oracle is
benchmarks/matrix_equalization_oracle.py.

## Pinned source

- [TheAlgorithms/Python array_equalization.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/matrix/matrix_equalization.py)

## Implementations

| Language | Port |
|---|---|
| C | [c/m/matrix_equalization.c](../../../c/m/matrix_equalization.c) |
| C3 | [c3/m/matrix_equalization.c3](../../../c3/m/matrix_equalization.c3) |
| C++ | [cpp/m/matrix_equalization.cpp](../../../cpp/m/matrix_equalization.cpp) |
| Elisa | [elisa/m/matrix_equalization.elisa](../../../elisa/m/matrix_equalization.elisa) |
| Nim | [nim/m/matrix_equalization.nim](../../../nim/m/matrix_equalization.nim) |
| Odin | [odin/m/matrix_equalization.odin](../../../odin/m/matrix_equalization.odin) |
| Rust | [rust/m/matrix_equalization.rs](../../../rust/m/matrix_equalization.rs) |
| V | [v/m/matrix_equalization.v](../../../v/m/matrix_equalization.v) |
| Zig | [zig/m/matrix_equalization.zig](../../../zig/m/matrix_equalization.zig) |
