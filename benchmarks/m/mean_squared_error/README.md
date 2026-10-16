# Mean squared error

This benchmark ports mean_squared_error from the pinned
[TheAlgorithms/Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/loss_functions.py).
The source checks equal array lengths and returns the mean of squared elementwise residuals.

## Contract

- Input uses i64_array_float64_call and is packed as
  [n, true_scaled[0..n], predicted_scaled[0..n]]. Each fixed-point input uses
  1,000,000 integer units per physical unit.
- Valid inputs have 1 through 256 paired values. Samples are bounded to
  [-1,000,000, 1,000,000] micro-units (physical values [-1, 1]). The parser admits
  n=257 so one-over-bound input reaches the implementation.
- The result is the arithmetic mean of (true - predicted) squared, returned as binary64.
  Empty, malformed, and out-of-range inputs return -1e300. The verifier uses absolute
  and relative tolerances of 1e-12.

The independent oracle is [mean_squared_error_oracle.py](../../mean_squared_error_oracle.py);
bounded examples are in [workload.json](workload.json).

## Implementations

| Language | Source |
| --- | --- |
| C | [c/mean_squared_error.c](../../../c/m/mean_squared_error.c) |
| C3 | [c3/mean_squared_error.c3](../../../c3/m/mean_squared_error.c3) |
| C++ | [cpp/mean_squared_error.cpp](../../../cpp/m/mean_squared_error.cpp) |
| Elisa | [elisa/mean_squared_error.elisa](../../../elisa/m/mean_squared_error.elisa) |
| Nim | [nim/mean_squared_error.nim](../../../nim/m/mean_squared_error.nim) |
| Odin | [odin/mean_squared_error.odin](../../../odin/m/mean_squared_error.odin) |
| Rust | [rust/mean_squared_error.rs](../../../rust/m/mean_squared_error.rs) |
| V | [v/mean_squared_error.v](../../../v/m/mean_squared_error.v) |
| Zig | [zig/mean_squared_error.zig](../../../zig/m/mean_squared_error.zig) |
