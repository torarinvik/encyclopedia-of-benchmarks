# Smooth L1 loss

This benchmark ports smooth_l1_loss from the pinned
[TheAlgorithms/Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/loss_functions.py).
The source checks equal array lengths and averages the per-element Smooth L1 values.

## Contract

- Input uses i64_array_float64_call and is packed as
  [n, true_scaled[0..n], predicted_scaled[0..n]]. Each fixed-point input uses
  1,000,000 integer units per physical unit.
- Valid inputs have 1 through 256 paired values. Samples are bounded to
  [-1,000,000, 1,000,000] micro-units (physical values [-1, 1]). The parser admits
  n=257 so one-over-bound input reaches the implementation.
- Beta is fixed to the source default of 1.0. For residual d, the quadratic branch
  is used only when abs(d) < beta; equality and larger residuals use
  abs(d) - 0.5*beta. The result is the arithmetic mean, returned as binary64.
- Empty, malformed, and out-of-range inputs return -1e300. Absolute and relative
  tolerances are 1e-12.

The independent oracle is [smooth_l1_loss_oracle.py](../../smooth_l1_loss_oracle.py);
bounded examples are in [workload.json](workload.json).

## Implementations

| Language | Source |
| --- | --- |
| C | [c/smooth_l1_loss.c](../../../c/s/smooth_l1_loss.c) |
| C3 | [c3/smooth_l1_loss.c3](../../../c3/s/smooth_l1_loss.c3) |
| C++ | [cpp/smooth_l1_loss.cpp](../../../cpp/s/smooth_l1_loss.cpp) |
| Elisa | [elisa/smooth_l1_loss.elisa](../../../elisa/s/smooth_l1_loss.elisa) |
| Nim | [nim/smooth_l1_loss.nim](../../../nim/s/smooth_l1_loss.nim) |
| Odin | [odin/smooth_l1_loss.odin](../../../odin/s/smooth_l1_loss.odin) |
| Rust | [rust/smooth_l1_loss.rs](../../../rust/s/smooth_l1_loss.rs) |
| V | [v/smooth_l1_loss.v](../../../v/s/smooth_l1_loss.v) |
| Zig | [zig/smooth_l1_loss.zig](../../../zig/s/smooth_l1_loss.zig) |
