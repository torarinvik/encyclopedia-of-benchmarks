# KL divergence loss

Port the pinned Rust loss function that computes a smoothed, unnormalized KL sum over the zipped prefix of two vectors.

## Contract

- The `i64_array_float64` ABI packs `[actual_count, predicted_count, actual_scaled..., predicted_scaled...]` with exact length `2 + actual_count + predicted_count`.
- Each count is in `0..64`. Values are in `0..1,000,000` and represent binary64 values divided by `1,000,000`; vectors do not need to sum to one. The maximum input is 130 signed 64-bit values.
- Pair `a,p` contributes `(a + 1e-5) * ln((a + 1e-5) / (p + 1e-5))`. Sum the first `min(actual_count, predicted_count)` terms in source order. Extra values in the longer vector are ignored, matching Rust's `zip` behavior. An empty zipped prefix returns `0.0`.
- The result is compared with absolute and relative tolerance `1e-12`. Malformed input returns `-1e300`.

## Source semantics

This package follows [`kl_divergence_loss.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/machine_learning/loss_function/kl_divergence_loss.rs) at commit `fed66cb0c74c4a939ec5163648458a8c2b46fd4c`. The fixed `1e-5` epsilon is applied to both inputs before multiplying and taking the natural logarithm. Zero actual values therefore still contribute when paired with positive predicted values. The source neither normalizes nor averages its inputs.

See the [workload](workload.json) and [oracle](../../kl_divergence_loss_oracle.py).

## Implementations

| Language | Port |
|---|---|
| C | [kl_divergence_loss.c](../../../c/k/kl_divergence_loss.c) |
| C3 | [kl_divergence_loss.c3](../../../c3/k/kl_divergence_loss.c3) |
| C++ | [kl_divergence_loss.cpp](../../../cpp/k/kl_divergence_loss.cpp) |
| Elisa | [kl_divergence_loss.elisa](../../../elisa/k/kl_divergence_loss.elisa) |
| Nim | [kl_divergence_loss.nim](../../../nim/k/kl_divergence_loss.nim) |
| Odin | [kl_divergence_loss.odin](../../../odin/k/kl_divergence_loss.odin) |
| Rust | [kl_divergence_loss.rs](../../../rust/k/kl_divergence_loss.rs) |
| V | [kl_divergence_loss.v](../../../v/k/kl_divergence_loss.v) |
| Zig | [kl_divergence_loss.zig](../../../zig/k/kl_divergence_loss.zig) |
