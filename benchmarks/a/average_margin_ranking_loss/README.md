# Average margin ranking loss

Compute the mean pairwise hinge loss for two score arrays, following the pinned Rust implementation.

## Contract

- The `i64_array_float64` ABI receives `[count, margin, y_true, x_first..., x_second...]`, with 1 through 256 pairs.
- The margin is an integer from 0 through 1,000, `y_true` is exactly `-1` or `1`, and score values are integers in `[-1,000, 1,000]`.
- For each pair, compute `max(0, margin - y_true * (x_first - x_second))`; return the average across all pairs.
- Invalid counts, unequal packed lengths, negative or oversized margins, invalid labels, or out-of-range scores return `-1e300`.
- The method takes `O(n)` time and constant auxiliary storage.

## Source

This follows pinned [TheAlgorithms Rust `average_margin_ranking_loss.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/machine_learning/loss_function/average_margin_ranking_loss.rs). The source validates equal nonempty arrays, a nonnegative margin, and a label of `-1` or `1`, then averages `max(0, margin - y_true * (x_first - x_second))`. The benchmark uses a bounded integer subset and maps invalid input to the sentinel.

## Workload

[`workload.json`](workload.json) covers the pinned examples, both label signs, zero and positive margins, mixed hinge activation, maximum length, and invalid inputs.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/average_margin_ranking_loss.c`](../../../c/a/average_margin_ranking_loss.c) |
| C3 | [`c3/a/average_margin_ranking_loss.c3`](../../../c3/a/average_margin_ranking_loss.c3) |
| C++ | [`cpp/a/average_margin_ranking_loss.cpp`](../../../cpp/a/average_margin_ranking_loss.cpp) |
| Elisa | [`elisa/a/average_margin_ranking_loss.elisa`](../../../elisa/a/average_margin_ranking_loss.elisa) |
| Nim | [`nim/a/average_margin_ranking_loss.nim`](../../../nim/a/average_margin_ranking_loss.nim) |
| Odin | [`odin/a/average_margin_ranking_loss.odin`](../../../odin/a/average_margin_ranking_loss.odin) |
| Rust | [`rust/a/average_margin_ranking_loss.rs`](../../../rust/a/average_margin_ranking_loss.rs) |
| V | [`v/a/average_margin_ranking_loss.v`](../../../v/a/average_margin_ranking_loss.v) |
| Zig | [`zig/a/average_margin_ranking_loss.zig`](../../../zig/a/average_margin_ranking_loss.zig) |

The package uses the `i64_array_float64` ABI and portable scalar operations.
