# Huber loss

This benchmark ports `huber_loss` from the pinned
[TheAlgorithms/Rust source](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/machine_learning/loss_function/huber_loss.rs).
The source computes the mean Huber loss for paired true and predicted values,
returning `None` when the lengths differ or the predictions are empty.

## Contract

- Input uses `i64_array_float64` and is packed as
  `[delta_micro, true_count, predicted_count, true_values..., predicted_values...]`.
  Every fixed-point measurement uses 1,000,000 units per physical unit.
- Each array has between 1 and 64 values for valid input. Values and delta are
  bounded to `[-1,000, 1,000]` and `[0, 1,000]`, respectively. Delta zero is
  supported, matching the source formula.
- The result is the arithmetic mean of the per-pair losses. Each residual `r`
  contributes `0.5*r*r` when `r <= delta`, otherwise `delta*r - 0.5*delta*delta`.
- Unequal or empty arrays, malformed packing, out-of-range measurements, and
  invalid counts return `-1e300`, adapting the source's `None` result to the
  scalar benchmark ABI. The maximum delta is covered at its boundary. The parser admits 65 values per side so complete
  one-over-bound fixtures reach the algorithm; valid arrays remain capped at
  64 pairs.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/h/huber_loss.c`](../../../c/h/huber_loss.c) |
| C3 | [`c3/h/huber_loss.c3`](../../../c3/h/huber_loss.c3) |
| C++ | [`cpp/h/huber_loss.cpp`](../../../cpp/h/huber_loss.cpp) |
| Elisa | [`elisa/h/huber_loss.elisa`](../../../elisa/h/huber_loss.elisa) |
| Nim | [`nim/h/huber_loss.nim`](../../../nim/h/huber_loss.nim) |
| Odin | [`odin/h/huber_loss.odin`](../../../odin/h/huber_loss.odin) |
| Rust | [`rust/h/huber_loss.rs`](../../../rust/h/huber_loss.rs) |
| V | [`v/h/huber_loss.v`](../../../v/h/huber_loss.v) |
| Zig | [`zig/h/huber_loss.zig`](../../../zig/h/huber_loss.zig) |

The workload is [`workload.json`](workload.json), and the oracle is
[`huber_loss_oracle.py`](../../huber_loss_oracle.py).
