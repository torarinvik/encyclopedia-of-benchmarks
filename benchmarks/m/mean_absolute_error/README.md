# Mean absolute error

This benchmark ports mean_absolute_error from the pinned
[TheAlgorithms/Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/loss_functions.py).
The source checks equal array lengths and returns the mean of absolute elementwise residuals.

## Contract

- Input uses i64_array_float64_call and is packed as
  [n, true_scaled[0..n], predicted_scaled[0..n]]. Each fixed-point input uses
  1,000,000 integer units per physical unit.
- Valid inputs have 1 through 256 paired values. Samples are bounded to
  [-1,000,000, 1,000,000] micro-units (physical values [-1, 1]). The parser admits
  n=257 so one-over-bound input reaches the implementation.
- The result is the arithmetic mean of abs(true - predicted), returned as binary64.
  Empty, malformed, and out-of-range inputs return -1e300. The verifier uses absolute
  and relative tolerances of 1e-12.

The independent oracle is [mean_absolute_error_oracle.py](../../mean_absolute_error_oracle.py);
bounded examples are in [workload.json](workload.json).

## Implementations

| Language | Source |
| --- | --- |
| C | [c/mean_absolute_error.c](../../../c/m/mean_absolute_error.c) |
| C3 | [c3/mean_absolute_error.c3](../../../c3/m/mean_absolute_error.c3) |
| C++ | [cpp/mean_absolute_error.cpp](../../../cpp/m/mean_absolute_error.cpp) |
| Elisa | [elisa/mean_absolute_error.elisa](../../../elisa/m/mean_absolute_error.elisa) |
| Nim | [nim/mean_absolute_error.nim](../../../nim/m/mean_absolute_error.nim) |
| Odin | [odin/mean_absolute_error.odin](../../../odin/m/mean_absolute_error.odin) |
| Rust | [rust/mean_absolute_error.rs](../../../rust/m/mean_absolute_error.rs) |
| V | [v/mean_absolute_error.v](../../../v/m/mean_absolute_error.v) |
| Zig | [zig/mean_absolute_error.zig](../../../zig/m/mean_absolute_error.zig) |
