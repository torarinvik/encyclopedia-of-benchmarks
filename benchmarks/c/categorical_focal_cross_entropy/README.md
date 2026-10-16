# Categorical Focal Cross Entropy

This benchmark ports `categorical_focal_cross_entropy` from the pinned TheAlgorithms/Python loss-functions module with source defaults fixed.

## Contract

- Input is `[B, C, one_hot[B*C], probability_scaled[B*C]]`, flattened row-major, with `1 <= B <= 64`, `2 <= C <= 16`, and exact length `2 + 2BC`.
- Each label row is one-hot. Each probability is an integer from 0 through 1,000,000, scaled by 1,000,000; each un-clipped probability row must sum to exactly 1,000,000.
- The source default `alpha=None` means unit weight for every class. Fix `gamma=2`; clip probabilities to `[1e-15, 1 - 1e-15]`, sum class losses within each row, then average those row losses over `B`.
- Return one binary64 scalar. Invalid input returns `-1e300`.
- Comparison uses absolute and relative tolerances of `1e-12`.

The independent [`categorical_focal_cross_entropy_oracle.py`](../../categorical_focal_cross_entropy_oracle.py) evaluates the bounded scalar formula directly.

## Pinned source

[TheAlgorithms/Python `loss_functions.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/loss_functions.py), commit `e1a2a8b016001309a73d5fec4818c35cca139795`, method `categorical_focal_cross_entropy`.
