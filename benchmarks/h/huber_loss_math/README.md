# Huber Loss Math

This benchmark ports the distinct `huber_loss` function in the pinned
[TheAlgorithms/Rust math module](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/huber_loss.rs).
That function sums its per-pair results, truncates unequal slices through Rust's
`zip`, returns zero for empty slices, and uses `delta * |difference| - delta/2`
for the large-residual branch. Those behaviors differ from the separately
benchmarked machine-learning average-loss implementation.

## Contract

- Input uses `i64_array_float64` and is packed as
  `[delta_micro, actual_count, predicted_count, actual_values..., predicted_values...]`.
  Measurements use 1,000,000 integer units per physical unit.
- Each array may contain 0 through 64 samples. The two lengths may differ; only
  the first `min(actual_count, predicted_count)` pairs contribute, matching
  source `zip` truncation. Empty input slices therefore return `0.0`.
- Delta is bounded to `[0, 1,000]` and samples to `[-1,000, 1,000]` physical
  units. The benchmark adapts malformed or out-of-domain input to `-1e300`.
- For each zipped pair, if `r = |actual - predicted| <= delta`, add
  `0.5 * (actual - predicted)^2`; otherwise add `delta * r - 0.5 * delta`.
  Return the sum, with no averaging. The source's linear term is intentionally
  preserved as written, even though it differs from the conventional Huber
  formula.
- The parser accepts 65 values per array so complete one-over-bound records fit;
  valid arrays remain capped at 64 samples.

## Pinned source

Rust [`src/math/huber_loss.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/huber_loss.rs)
at commit `fed66cb0c74c4a939ec5163648458a8c2b46fd4c`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/h/huber_loss_math.c`](../../../c/h/huber_loss_math.c) |
| C3 | [`c3/h/huber_loss_math.c3`](../../../c3/h/huber_loss_math.c3) |
| C++ | [`cpp/h/huber_loss_math.cpp`](../../../cpp/h/huber_loss_math.cpp) |
| Elisa | [`elisa/h/huber_loss_math.elisa`](../../../elisa/h/huber_loss_math.elisa) |
| Nim | [`nim/h/huber_loss_math.nim`](../../../nim/h/huber_loss_math.nim) |
| Odin | [`odin/h/huber_loss_math.odin`](../../../odin/h/huber_loss_math.odin) |
| Rust | [`rust/h/huber_loss_math.rs`](../../../rust/h/huber_loss_math.rs) |
| V | [`v/h/huber_loss_math.v`](../../../v/h/huber_loss_math.v) |
| Zig | [`zig/h/huber_loss_math.zig`](../../../zig/h/huber_loss_math.zig) |

The workload is [`workload.json`](workload.json), and the independent oracle is
[`huber_loss_math_oracle.py`](../../huber_loss_math_oracle.py).
