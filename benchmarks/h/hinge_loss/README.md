# Hinge loss

Compute the average binary classification hinge loss for aligned labels and prediction scores, following the pinned Rust `hng_loss` function.

## Contract

- The `i64_array_float64` ABI receives `[n, labels[0..n], prediction_scaled[0..n]]`, with `1 <= n <= 256` and exactly `1 + 2*n` values.
- Each label is `-1` or `1`. Each prediction is an integer in `[-1,000,000, 1,000,000]`, interpreted as a binary64 score divided by 1,000,000.
- For each pair in input order, compute `max(0, 1 - label * prediction)`, sum the losses in order, and divide by `n`. Return the result as binary64 with absolute and relative tolerance `1e-12`.
- Malformed packing, empty arrays, unsupported labels, or out-of-range scores return `-1e300`. The source uses `zip` and divides by the prediction-array length; this bounded contract accepts equal nonempty arrays so the finite result and every pair are defined.
- Runtime is O(n) with O(1) auxiliary space.

## Source semantics

The implementation follows [TheAlgorithms/Rust `hinge_loss.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74a4c939ec5163648458a8c2b46fd4c/src/machine_learning/loss_function/hinge_loss.rs) at commit `fed66cb0c74a4c939ec5163648458a8c2b46fd4c`. Its `hng_loss` function accumulates `max(0, 1 - y_true[i] * y_pred[i])` over zipped pairs and divides by `y_pred.len()`. The benchmark uses a fixed-point prediction grid and the conventional `{-1, 1}` classification labels. This is distinct from [`average_margin_ranking_loss`](../../a/average_margin_ranking_loss/README.md), which compares two ranked scores with a configurable margin, and from [`cross_entropy_loss`](../../c/cross_entropy_loss/README.md), which applies logarithms to probability values.

## Workload

[`workload.json`](workload.json) covers the pinned source example, zero loss at the margin, fractional scores, wrong-side predictions, the maximum count, and malformed inputs.

Build and record with the `i64_array_float64` family:

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm hinge_loss --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/h/hinge_loss/rust/build.json
python3 benchmarks/verify_i64_array_float64.py --algorithm hinge_loss
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/h/hinge_loss.c`](../../../c/h/hinge_loss.c) |
| C3 | [`c3/h/hinge_loss.c3`](../../../c3/h/hinge_loss.c3) |
| C++ | [`cpp/h/hinge_loss.cpp`](../../../cpp/h/hinge_loss.cpp) |
| Elisa | [`elisa/h/hinge_loss.elisa`](../../../elisa/h/hinge_loss.elisa) |
| Nim | [`nim/h/hinge_loss.nim`](../../../nim/h/hinge_loss.nim) |
| Odin | [`odin/h/hinge_loss.odin`](../../../odin/h/hinge_loss.odin) |
| Rust | [`rust/h/hinge_loss.rs`](../../../rust/h/hinge_loss.rs) |
| V | [`v/h/hinge_loss.v`](../../../v/h/hinge_loss.v) |
| Zig | [`zig/h/hinge_loss.zig`](../../../zig/h/hinge_loss.zig) |
