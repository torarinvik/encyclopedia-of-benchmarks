# Connectionist temporal classification loss

This benchmark ports the pinned Python [`connectionist_temporal_classification_loss`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/loss_functions.py) method. The source consumes probabilities, takes their natural logarithms, and applies a forward dynamic program over the target sequence expanded with blank symbols. Its default blank class is `0`.

## Contract

The `i64_array_float64_call` ABI receives `[time, classes, target_length, targets[0..target_length], probabilities_micro[time*classes]]`. Dimensions satisfy `1 <= time <= 32`, `2 <= classes <= 16`, and `1 <= target_length <= 16`. Blank is fixed to `0`; each target ID is in `[1, classes-1]`. To ensure the target has a valid CTC alignment, `time` must be at least `target_length` plus the number of adjacent repeated target IDs.

Each probability is a positive integer in `[1, 1,000,000]` divided by `1,000,000`; each time row sums exactly to `1,000,000`. The packed length is exactly `3 + target_length + time*classes`. Preserve the source's extended target, stay/advance/conditional-skip transitions, probability-to-log conversion, and final negative log-add of the blank and target states. Malformed packing, invalid IDs, nonpositive probabilities, invalid row sums, or impossible alignments return `-1e300`. Results use absolute tolerance `1e-10` and relative tolerance `1e-12`.

## Workload

[`workload.json`](workload.json) covers a single frame, multiple valid alignments, adjacent repeated labels requiring a blank, and invalid cases. The independent oracle is [`connectionist_temporal_classification_loss_oracle.py`](../../connectionist_temporal_classification_loss_oracle.py).

## Implementations

The nine language ports live in `c/c`, `c3/c`, `cpp/c`, `elisa/c`, `nim/c`, `odin/c`, `rust/c`, `v/c`, and `zig/c`.
